# =============================================================================
# 05_model_paper2_h11_opposition_size.R
# H11: Larger domestic opposition increases NAG support
# Primary: Logit on nags_any_support | Probit robustness
# Additional: Original QP and NB models kept
# =============================================================================

here::i_am("R/models/05_model_paper2_h11_opposition_size.R")

# Force clean load of trimmed + fixed data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ----------------------------------------------------------------------------
# Packages
# ----------------------------------------------------------------------------
library(fixest)
library(texreg)
library(ggplot2)
library(dplyr)

# ----------------------------------------------------------------------------
# Prepare model data with friendly English labels (Rule 9)
# ----------------------------------------------------------------------------
df_model <- df_final |>
  drop_na(nags_any_support, oppsize_norm,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    OppositionSizeNorm = oppsize_norm,
    PoliticalBandwidth = politicalbandwidth,
    LogCapitalDistance = ln_capital_dist_km,
    SenderCINCLog      = cinc_a_log,
    TargetCINCLog      = cinc_b_log
  )

# ----------------------------------------------------------------------------
# PRIMARY: Logit on nags_any_support (binary)
# ----------------------------------------------------------------------------
model_h11_logit <- feglm(
  nags_any_support ~ OppositionSizeNorm +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# ROBUSTNESS: Probit
# ----------------------------------------------------------------------------
model_h11_probit <- feglm(
  nags_any_support ~ OppositionSizeNorm +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "probit"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# ORIGINAL MODELS KEPT (do not delete)
# ----------------------------------------------------------------------------
# Quasi-Poisson
model_h11_qp <- feglm(
  nags_any_support ~ OppositionSizeNorm +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# Negative Binomial (with safety catch)
model_h11_nb <- tryCatch(
  fenegbin(
    nags_any_support ~ OppositionSizeNorm +
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
etable(model_h11_logit, model_h11_probit, model_h11_qp, 
       file = here("results/tables/paper2_h11_logit_probit_qp.tex"),
       replace = TRUE)

if (!is.null(model_h11_nb)) {
  etable(model_h11_nb,
         file = here("results/tables/paper2_h11_nb.tex"),
         replace = TRUE)
}

coef_table <- etable(model_h11_logit, model_h11_probit, model_h11_qp, tex = FALSE)
write_csv(coef_table, here("results/tables/paper2_h11_coefficients.csv"))

# ----------------------------------------------------------------------------
# NEW: Save stripped RDS models (Rule 6)
# ----------------------------------------------------------------------------
source(here("R/shared/utils_model.R"))

saveRDS(strip_model(model_h11_logit), 
        here("results/models/h11_logit_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h11_probit), 
        here("results/models/h11_probit_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h11_qp), 
        here("results/models/h11_qp_stripped.rds"), compress = "xz")
if (!is.null(model_h11_nb)) {
  saveRDS(strip_model(model_h11_nb), 
          here("results/models/h11_nb_stripped.rds"), compress = "xz")
}

message("Stripped RDS models saved.")

# ----------------------------------------------------------------------------
# Predicted probabilities table — explicit factor order (Rule 14)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  OppositionSizeNorm = quantile(df_model$OppositionSizeNorm, probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  PoliticalBandwidth = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog      = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog      = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war           = 0,
  war_on_terror      = 0
)

preds <- predict(model_h11_logit, newdata = newdata, type = "response")

pred_table <- data.frame(
  OppositionSizeLevel = factor(c("Low (25th)", "Median (50th)", "High (75th)"),
                               levels = c("Low (25th)", "Median (50th)", "High (75th)")),
  PredictedProbability = round(preds, 4)
)

print("Predicted Probabilities Table (H11):")
print(pred_table)
write_csv(pred_table, here("results/tables/paper2_h11_predicted_probabilities.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — fixed with explicit factor ordering (Rule 14)
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = OppositionSizeLevel, y = PredictedProbability)) +
  geom_point(size = 4, color = "darkred") +
  geom_line(aes(group = 1), linewidth = 1, color = "darkred") +
  labs(title = "H11: Larger Domestic Opposition Increases NAG Support",
       x = "Opposition Size Level",
       y = "Predicted Probability of Any NAG Support") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots/paper2_h11_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved: paper2_h11_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h11_logit", "model_h11_probit", 
                          "model_h11_qp", "model_h11_nb")))
gc()
message("[H11] Environment cleaned. Ready for next model.")