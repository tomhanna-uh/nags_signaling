# =============================================================================
# 05_model_paper2_h7_legitimation_ratio.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H7: Higher ideological legitimation ratio increases NAG support
# =============================================================================
here::i_am("R/models/05_model_paper2_h7_legitimation_ratio.R")

# Force clean load of trimmed + fixed data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

# ----------------------------------------------------------------------------
# Packages
# ----------------------------------------------------------------------------
library(fixest)
library(texreg)
library(ggplot2)
library(dplyr)

message("Modeling packages loaded. df_final ready: ", nrow(df_final), " rows")

# ----------------------------------------------------------------------------
# Prepare model data with friendly English labels
# ----------------------------------------------------------------------------
df_model <- df_final |>
  drop_na(nags_support_count, ideol_legit_ratio,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    # Winsorize legit ratio to prevent extreme values from collapsing predictions
    IdeolLegitRatioWinsor = pmin(pmax(ideol_legit_ratio, quantile(ideol_legit_ratio, 0.01, na.rm = TRUE)),
                                 quantile(ideol_legit_ratio, 0.99, na.rm = TRUE)),
    PoliticalBandwidth    = politicalbandwidth,
    LogCapitalDistance    = ln_capital_dist_km,
    SenderCINCLog         = cinc_a_log,
    TargetCINCLog         = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Quasi-Poisson using count DV (fixes zero-prediction collapse)
# ----------------------------------------------------------------------------
model_h7_qp <- feglm(
  nags_support_count ~ IdeolLegitRatioWinsor +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial (with safety catch)
# ----------------------------------------------------------------------------
model_h7_nb <- tryCatch(
  fenegbin(
    nags_support_count ~ IdeolLegitRatioWinsor +
      PoliticalBandwidth + LogCapitalDistance +
      SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
    cluster = ~dyad,
    data = df_model
  ),
  error = function(e) {
    message("Negative Binomial failed to converge - skipping for now.")
    NULL
  }
)

# ----------------------------------------------------------------------------
# Save tables
# ----------------------------------------------------------------------------
if (!is.null(model_h7_nb)) {
  etable(model_h7_qp, model_h7_nb,
         file = here("results/tables", "paper2_h7_quasipoisson_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h7_qp, model_h7_nb, tex = FALSE)
} else {
  etable(model_h7_qp,
         file = here("results/tables", "paper2_h7_quasipoisson.tex"),
         replace = TRUE)
  coef_table <- etable(model_h7_qp, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h7_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted counts table (Legitimation Ratio Quartiles)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  IdeolLegitRatioWinsor = quantile(df_model$IdeolLegitRatioWinsor, probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  PoliticalBandwidth    = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance    = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog         = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog         = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war              = 0,
  war_on_terror         = 0
)

preds <- predict(model_h7_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  LegitimationRatioLevel = c("Low (25th percentile)", "Median (50th percentile)", "High (75th percentile)"),
  PredictedCount         = round(preds, 4)
)

print("Predicted Counts Table (H7):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h7_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = LegitimationRatioLevel, y = PredictedCount)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  labs(title = "H7: Higher Ideological Legitimation Ratio Increases NAG Support",
       x = "Ideological Legitimation Ratio Level",
       y = "Predicted NAG Support Count") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h7_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h7_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h7_qp", "model_h7_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")
