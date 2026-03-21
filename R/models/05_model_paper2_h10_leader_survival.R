# =============================================================================
# 05_model_paper2_h10_leader_survival.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H10: Aligned NAG support improves leader survival (using sidea_dynamic_leader)
# =============================================================================
here::i_am("R/models/05_model_paper2_h10_leader_survival.R")

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
  drop_na(nags_any_support, sidea_dynamic_leader,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    AlignedNAGSupport   = nags_any_support,
    DynamicLeaderQuality = sidea_dynamic_leader,   # operationalization per paper
    PoliticalBandwidth  = politicalbandwidth,
    LogCapitalDistance  = ln_capital_dist_km,
    SenderCINCLog       = cinc_a_log,
    TargetCINCLog       = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Logistic (committee-friendly, stable)
# ----------------------------------------------------------------------------
model_h10_logit <- feglm(
  AlignedNAGSupport ~ DynamicLeaderQuality +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial on count DV
# ----------------------------------------------------------------------------
model_h10_nb <- tryCatch(
  fenegbin(
    nags_support_count ~ DynamicLeaderQuality +
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
if (!is.null(model_h10_nb)) {
  etable(model_h10_logit, model_h10_nb,
         file = here("results/tables", "paper2_h10_logit_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h10_logit, model_h10_nb, tex = FALSE)
} else {
  etable(model_h10_logit,
         file = here("results/tables", "paper2_h10_logit.tex"),
         replace = TRUE)
  coef_table <- etable(model_h10_logit, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h10_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted probabilities table
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  DynamicLeaderQuality = quantile(df_model$DynamicLeaderQuality, probs = c(0.25, 0.75), na.rm = TRUE),
  PoliticalBandwidth   = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance   = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog        = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog        = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war             = 0,
  war_on_terror        = 0
)

preds <- predict(model_h10_logit, newdata = newdata, type = "response")

pred_table <- data.frame(
  DynamicLeaderQualityLevel = c("Low (25th percentile)", "High (75th percentile)"),
  PredictedProbability      = round(preds, 4)
)

print("Predicted Probabilities Table (H10):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h10_predicted_probabilities.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = DynamicLeaderQualityLevel, y = PredictedProbability)) +
  geom_point(size = 4, color = "darkgreen") +
  geom_line(aes(group = 1), linewidth = 1, color = "darkgreen") +
  labs(title = "H10: Aligned NAG Support Improves Leader Survival (sidea_dynamic_leader)",
       x = "Dynamic Leader Quality Level",
       y = "Predicted Probability of Aligned NAG Support") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h10_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h10_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h10_logit", "model_h10_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")