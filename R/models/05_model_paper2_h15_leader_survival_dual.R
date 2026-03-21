# =============================================================================
# 05_model_paper2_h15_leader_survival_dual.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H15: Visible NAG support signals resolve to domestic opposition, improving survival
# =============================================================================
here::i_am("R/models/05_model_paper2_h15_leader_survival_dual.R")

# Force clean load of trimmed + fixed data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

# ----------------------------------------------------------------------------
# Packages
# ----------------------------------------------------------------------------
library(fixest)
library(texreg)
library(ggplot2)
library(dplyr)
library(survival)    # for survival analysis

message("Modeling packages loaded. df_final ready: ", nrow(df_final), " rows")

# ----------------------------------------------------------------------------
# Prepare model data with friendly English labels
# ----------------------------------------------------------------------------
df_model <- df_final |>
  drop_na(nags_any_support, oppsize_norm, nags_targets_democracy,
          sidea_dynamic_leader, politicalbandwidth, ln_capital_dist_km,
          cinc_a_log, cinc_b_log) |>
  mutate(
    VisibleNAGSupport      = nags_any_support,          # visible support as resolve signal
    OppositionSizeNorm     = oppsize_norm,              # domestic opposition size
    NAGTargetsNonDemocracy = 1 - nags_targets_democracy, # dual signaling to non-dem targets
    DynamicLeaderQuality   = sidea_dynamic_leader,      # survival proxy
    PoliticalBandwidth     = politicalbandwidth,
    LogCapitalDistance     = ln_capital_dist_km,
    SenderCINCLog          = cinc_a_log,
    TargetCINCLog          = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Logistic (committee-friendly, stable for binary outcome)
# ----------------------------------------------------------------------------
model_h15_logit <- feglm(
  VisibleNAGSupport ~ OppositionSizeNorm * NAGTargetsNonDemocracy +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial on count DV
# ----------------------------------------------------------------------------
model_h15_nb <- tryCatch(
  fenegbin(
    nags_support_count ~ OppositionSizeNorm * NAGTargetsNonDemocracy +
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
if (!is.null(model_h15_nb)) {
  etable(model_h15_logit, model_h15_nb,
         file = here("results/tables", "paper2_h15_logit_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h15_logit, model_h15_nb, tex = FALSE)
} else {
  etable(model_h15_logit,
         file = here("results/tables", "paper2_h15_logit.tex"),
         replace = TRUE)
  coef_table <- etable(model_h15_logit, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h15_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted probabilities table (Opposition Size × Non-Democracy Target)
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

preds <- predict(model_h15_logit, newdata = newdata, type = "response")

pred_table <- data.frame(
  OppositionSizeLevel    = rep(c("Low (25th)", "Median (50th)", "High (75th)"), each = 2),
  NAGTargetsNonDemocracy = rep(c("No", "Yes"), 3),
  PredictedProbability   = round(preds, 4)
)

print("Predicted Probabilities Table (H15):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h15_predicted_probabilities.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = NAGTargetsNonDemocracy, y = PredictedProbability,
                                  color = OppositionSizeLevel, shape = OppositionSizeLevel)) +
  geom_point(size = 4) +
  geom_line(aes(group = OppositionSizeLevel), linewidth = 1) +
  labs(title = "H15: Larger Opposition Increases NAG Support to Non-Democracy Targets",
       x = "NAG Targets Non-Democracy (0 = No, 1 = Yes)",
       y = "Predicted Probability of Any NAG Support",
       color = "Opposition Size Level",
       shape = "Opposition Size Level") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h15_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h15_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h15_logit", "model_h15_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")