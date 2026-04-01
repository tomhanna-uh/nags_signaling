# =============================================================================
# 05_model_paper2_h3_dynamic_leader.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H3: Dynamic/messianic leaders amplify the effect of continuous revisionist legitimation on NAG support
# =============================================================================
here::i_am("R/models/05_model_paper2_h3_dynamic_leader.R")


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
# Prepare model data with friendly English labels (Rule 9)
# ----------------------------------------------------------------------------
df_model <- df_final |>
  drop_na(nags_support_count, sidea_dynamic_leader, sidea_revisionist_domestic,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    DynamicLeaderQuality      = sidea_dynamic_leader,           # continuous dynamic/messianic leader legitimation
    RevisionistLegitimation   = sidea_revisionist_domestic,     # continuous revisionist legitimation
    PoliticalBandwidth        = politicalbandwidth,
    LogCapitalDistance        = ln_capital_dist_km,
    SenderCINCLog             = cinc_a_log,
    TargetCINCLog             = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Quasi-Poisson (committee recommendation)
# ----------------------------------------------------------------------------
model_h3_qp <- feglm(
  nags_support_count ~ DynamicLeaderQuality * RevisionistLegitimation +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial
# ----------------------------------------------------------------------------
model_h3_nb <- tryCatch(
  fenegbin(
    nags_support_count ~ DynamicLeaderQuality * RevisionistLegitimation +
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
# Save tables (CSV + LaTeX) — no RDS models (Rule 4)
# ----------------------------------------------------------------------------
if (!is.null(model_h3_nb)) {
  etable(model_h3_qp, model_h3_nb,
         file = here("results/tables", "paper2_h3_quasipoisson_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h3_qp, model_h3_nb, tex = FALSE)
} else {
  etable(model_h3_qp,
         file = here("results/tables", "paper2_h3_quasipoisson.tex"),
         replace = TRUE)
  coef_table <- etable(model_h3_qp, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h3_coefficients.csv"))
message("Tables saved.")

# ----------------------------------------------------------------------------
# Predicted counts table (Dynamic Leader × Revisionist Legitimation Quartiles)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  DynamicLeaderQuality      = quantile(df_model$DynamicLeaderQuality, probs = c(0.25, 0.75), na.rm = TRUE),
  RevisionistLegitimation   = quantile(df_model$RevisionistLegitimation, probs = c(0.25, 0.75), na.rm = TRUE),
  PoliticalBandwidth        = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance        = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog             = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog             = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war                  = 0,
  war_on_terror             = 0
)

preds <- predict(model_h3_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  DynamicLeaderLevel      = rep(c("Low Dynamic (25th)", "High Dynamic (75th)"), each = 2),
  RevisionistLegitimation = rep(c("Low Revisionist (25th)", "High Revisionist (75th)"), 2),
  PredictedCount          = round(preds, 4)
)

print("Predicted Counts Table (H3):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h3_predicted_counts.csv"))
message("Predicted counts table saved.")

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG (no viewer pane)
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = RevisionistLegitimation, y = PredictedCount,
                                  color = DynamicLeaderLevel, shape = DynamicLeaderLevel)) +
  geom_point(size = 4) +
  geom_line(aes(group = DynamicLeaderLevel), linewidth = 1) +
  labs(title = "H3: Dynamic Leaders Amplify the Effect of Revisionist Legitimation on NAG Support",
       x = "Revisionist Legitimation Level",
       y = "Predicted NAG Support Count",
       color = "Dynamic Leader Level",
       shape = "Dynamic Leader Level") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h3_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h3_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h3_qp", "model_h3_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")