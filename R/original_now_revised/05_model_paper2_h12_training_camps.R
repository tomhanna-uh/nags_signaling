# =============================================================================
# 05_model_paper2_h12_training_camps.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H12: Larger domestic opposition increases hosting of training camps
# =============================================================================
here::i_am("R/models/05_model_paper2_h12_training_camps.R")

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
  drop_na(nags_training, oppsize_norm,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    TrainingCamps        = Num_DS_TrainCamp + Num_S_TrainCamp,
    ActiveTrainingCamps  = Num_S_TrainCamp,
    DeFactoTrainingCamps = Num_DS_TrainCamp,
    OppositionSizeNorm   = oppsize_norm,
    PoliticalBandwidth   = politicalbandwidth,
    LogCapitalDistance   = ln_capital_dist_km,
    SenderCINCLog        = cinc_a_log,
    TargetCINCLog        = cinc_b_log
  )



# ----------------------------------------------------------------------------
# Primary Model: Negative Binomial (with safety catch)
# ----------------------------------------------------------------------------
model_h12_nb <- tryCatch(
  fenegbin(
    TrainingCamps ~ OppositionSizeNorm +
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
# Robustness Model: Quasi-Poisson (committee recommendation)
# ----------------------------------------------------------------------------
model_h12_qp <- feglm(
  TrainingCamps ~ OppositionSizeNorm +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)


# ----------------------------------------------------------------------------
# Save tables
# ----------------------------------------------------------------------------
if (!is.null(model_h12_nb)) {
  etable(model_h12_qp, model_h12_nb,
         file = here("results/tables", "paper2_h12_quasipoisson_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h12_qp, model_h12_nb, tex = FALSE)
} else {
  etable(model_h12_qp,
         file = here("results/tables", "paper2_h12_quasipoisson.tex"),
         replace = TRUE)
  coef_table <- etable(model_h12_qp, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h12_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted counts table (Opposition Size Quartiles)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  OppositionSizeNorm   = quantile(df_model$OppositionSizeNorm, probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  PoliticalBandwidth   = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance   = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog        = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog        = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war             = 0,
  war_on_terror        = 0
)

preds <- predict(model_h12_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  OppositionSizeLevel = c("Low (25th percentile)", "Median (50th percentile)", "High (75th percentile)"),
  PredictedTrainingCount = round(preds, 4)
)

print("Predicted Counts Table (H12):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h12_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = OppositionSizeLevel, y = PredictedTrainingCount)) +
  geom_point(size = 4, color = "darkorange") +
  geom_line(aes(group = 1), linewidth = 1, color = "darkorange") +
  labs(title = "H12: Larger Domestic Opposition Increases Hosting of Training Camps",
       x = "Opposition Size Level",
       y = "Predicted Training Camp Support Count") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h12_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h12_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h12_qp", "model_h12_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")