# =============================================================================
# 05_model_paper3_h14_bandwidth_interaction.R
# H14: The avoidance of democracy-targeting NAGs when opposition is large 
#      is stronger when political bandwidth (visibility) is high
# =============================================================================
here::i_am("R/models/05_model_paper3_h14_bandwidth_interaction.R")

# Force clean load of trimmed + fixed data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ----------------------------------------------------------------------------
# Packages
# ----------------------------------------------------------------------------
library(fixest)
library(modelsummary)
library(gt)
library(dplyr)
library(ggplot2)

# ----------------------------------------------------------------------------
# Prepare data with friendly English labels
# ----------------------------------------------------------------------------
df_model <- df_final |>
  drop_na(nags_any_support, oppsize_norm, nags_targets_democracy,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    OppositionSizeNorm     = oppsize_norm,
    NAGTargetsNonDemocracy = 1 - nags_targets_democracy,   # 1 = targets non-democracy
    PoliticalBandwidth     = politicalbandwidth,
    LogCapitalDistance     = ln_capital_dist_km,
    SenderCINCLog          = cinc_a_log,
    TargetCINCLog          = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Models: Logit (primary) + Probit (robustness)
# ----------------------------------------------------------------------------
model_h14_logit <- feglm(
  nags_any_support ~ OppositionSizeNorm * NAGTargetsNonDemocracy * PoliticalBandwidth +
    LogCapitalDistance + SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

model_h14_probit <- feglm(
  nags_any_support ~ OppositionSizeNorm * NAGTargetsNonDemocracy * PoliticalBandwidth +
    LogCapitalDistance + SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "probit"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Clean coefficient table with friendly labels
# ----------------------------------------------------------------------------
coef_map <- c(
  "OppositionSizeNorm"                                 = "Opposition Size (Normalized)",
  "NAGTargetsNonDemocracy"                             = "NAG Targets Non-Democracy",
  "PoliticalBandwidth"                                 = "Political Bandwidth",
  "OppositionSizeNorm:NAGTargetsNonDemocracy"          = "Opposition Size × Targets Non-Democracy",
  "OppositionSizeNorm:PoliticalBandwidth"              = "Opposition Size × Political Bandwidth",
  "NAGTargetsNonDemocracy:PoliticalBandwidth"          = "Targets Non-Democracy × Political Bandwidth",
  "OppositionSizeNorm:NAGTargetsNonDemocracy:PoliticalBandwidth" = "Three-Way Interaction",
  "LogCapitalDistance"                                 = "Log Capital Distance",
  "SenderCINCLog"                                      = "Sender CINC (log)",
  "TargetCINCLog"                                      = "Target CINC (log)",
  "cold_war"                                           = "Cold War Period",
  "war_on_terror"                                      = "War on Terror Period"
)

modelsummary(list("Logit" = model_h14_logit, "Probit" = model_h14_probit),
             coef_map = coef_map,
             gof_map = c("nobs", "aic", "bic", "r.squared"),
             stars = TRUE,
             output = here("results/tables/paper3_h14_coefficients.tex"))

# Save CSV for gt() use in Quarto
ms_table <- modelsummary(list("Logit" = model_h14_logit, "Probit" = model_h14_probit),
                         coef_map = coef_map, output = "data.frame")
write_csv(ms_table, here("results/tables/paper3_h14_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted probabilities table (saved as CSV for Quarto)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  OppositionSizeNorm     = quantile(df_model$OppositionSizeNorm, probs = c(0.25, 0.50, 0.75)),
  NAGTargetsNonDemocracy = c(0, 1),
  PoliticalBandwidth     = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance     = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog          = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog          = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war               = 0,
  war_on_terror          = 0
)

preds <- predict(model_h14_logit, newdata = newdata, type = "response")

pred_table <- data.frame(
  NAGTargetsNonDemocracy = ifelse(newdata$NAGTargetsNonDemocracy == 1, "Yes", "No"),
  OppositionSizeLevel    = rep(c("Low (25th)", "Median (50th)", "High (75th)"), 2),
  PredictedProbability   = round(preds, 4)
)

print("H14 Predicted Probabilities:")
print(pred_table)
write_csv(pred_table, here("results/tables/paper3_h14_predicted_probabilities.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot (saved directly to quarto/plots/)
# ----------------------------------------------------------------------------
ggplot(pred_table, aes(x = OppositionSizeLevel, y = PredictedProbability,
                       color = NAGTargetsNonDemocracy, group = NAGTargetsNonDemocracy)) +
  geom_point(size = 3) +
  geom_line(linewidth = 1) +
  labs(title = "H14: Marginal Effect of Opposition Size on Probability of NAG Support",
       subtitle = "by Whether the NAG Targets a Non-Democracy and Political Bandwidth",
       x = "Opposition Size Level",
       y = "Predicted Probability of Any NAG Support",
       color = "NAG Targets Non-Democracy") +
  theme_minimal(base_size = 14) +
  scale_x_discrete(limits = c("Low (25th)", "Median (50th)", "High (75th)"))

ggsave(
  filename = here("quarto/plots/paper3_h14_marginal_effects.png"),
  width = 10, height = 7, dpi = 300
)

message("H14 marginal effects plot saved to quarto/plots/paper3_h14_marginal_effects.png")

# ----------------------------------------------------------------------------
# Stripped logit model (small RDS for later post-estimation if needed)
# ----------------------------------------------------------------------------
model_h14_logit_stripped <- model_h14_logit
model_h14_logit_stripped$data <- NULL
model_h14_logit_stripped$fitted.values <- NULL
model_h14_logit_stripped$residuals <- NULL
model_h14_logit_stripped$linear.predictors <- NULL
model_h14_logit_stripped$effects <- NULL
model_h14_logit_stripped$qr <- NULL

saveRDS(model_h14_logit_stripped, 
        file = here("results/models/h14_logit_stripped.rds"), 
        compress = "xz")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h14_logit", "model_h14_probit")))
gc()
message("[H14] Script complete. Environment cleaned.")