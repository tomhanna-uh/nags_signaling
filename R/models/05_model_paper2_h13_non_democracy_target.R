# =============================================================================
# 05_model_paper2_h13_non_democracy_target.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H13: Larger domestic opposition increases NAG support to non-democracy targets
# =============================================================================
here::i_am("R/models/05_model_paper2_h13_non_democracy_target.R")

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
  drop_na(nags_any_support, oppsize_norm, nags_targets_democracy,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    OppositionSizeNorm      = oppsize_norm,
    NAGTargetsNonDemocracy  = 1 - nags_targets_democracy,   # H13: non-democracy target
    PoliticalBandwidth      = politicalbandwidth,
    LogCapitalDistance      = ln_capital_dist_km,
    SenderCINCLog           = cinc_a_log,
    TargetCINCLog           = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Quasi-Poisson (committee recommendation)
# ----------------------------------------------------------------------------
model_h13_qp <- feglm(
  nags_any_support ~ i(OppositionSizeNorm, NAGTargetsNonDemocracy) +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial (with safety catch)
# ----------------------------------------------------------------------------
model_h13_nb <- tryCatch(
  fenegbin(
    nags_any_support ~ i(OppositionSizeNorm, NAGTargetsNonDemocracy) +
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
if (!is.null(model_h13_nb)) {
  etable(model_h13_qp, model_h13_nb,
         file = here("results/tables", "paper2_h13_quasipoisson_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h13_qp, model_h13_nb, tex = FALSE)
} else {
  etable(model_h13_qp,
         file = here("results/tables", "paper2_h13_quasipoisson.tex"),
         replace = TRUE)
  coef_table <- etable(model_h13_qp, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h13_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted probabilities table (Non-Democracy Target Yes/No × Opposition Quartiles)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  OppositionSizeNorm     = quantile(df_model$OppositionSizeNorm, probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  NAGTargetsNonDemocracy = c(0, 1),
  PoliticalBandwidth     = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance     = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog          = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog          = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war               = 0,
  war_on_terror          = 0
)

preds <- predict(model_h13_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  NAGTargetsNonDemocracy = rep(c("No", "Yes"), each = 3),
  OppositionSizeLevel    = rep(c("Low (25th percentile)", "Median (50th percentile)", "High (75th percentile)"), 2),
  PredictedProbability   = round(preds, 4)
)

print("Predicted Probabilities Table (H13):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h13_predicted_probabilities.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = NAGTargetsNonDemocracy, y = PredictedProbability,
                                  color = OppositionSizeLevel, shape = OppositionSizeLevel)) +
  geom_point(size = 4) +
  geom_line(aes(group = OppositionSizeLevel), linewidth = 1) +
  labs(title = "H13: Larger Domestic Opposition Increases NAG Support to Non-Democracy Targets",
       x = "NAG Targets Non-Democracy (0 = No, 1 = Yes)",
       y = "Predicted Probability of Any NAG Support",
       color = "Opposition Size Level",
       shape = "Opposition Size Level") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h13_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h13_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h13_qp", "model_h13_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")