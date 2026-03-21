# =============================================================================
# 05_model_paper2_h4_subtypes_and_subsample.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H4: Higher revisionist legitimation increases ideological match with supported NAGs
# H4a–H4c: Sub-type alignment (nationalist/ethno, socialist/leftist, religious)
# Subsample analysis: only among cases with nags_support_count > 0
# =============================================================================
here::i_am("R/models/05_model_paper2_h4_subtypes_and_subsample.R")

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
# Prepare model data with friendly English labels (Rule 9)
# ----------------------------------------------------------------------------
df_model <- df_final |>
  drop_na(nags_ideology_match, sidea_revisionist_domestic,
          v2exl_legitideolcr_0_a, v2exl_legitideolcr_1_a, v2exl_legitideolcr_4_a,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    RevisionistLegitimation = sidea_revisionist_domestic,           # continuous predictor (preferred)
    IdeologyMatch           = nags_ideology_match,                  # binary DV
    NationalistLegitimation = v2exl_legitideolcr_0_a,               # subtype 0: nationalist
    SocialistLegitimation   = v2exl_legitideolcr_1_a,               # subtype 1: socialist
    ReligiousLegitimation   = v2exl_legitideolcr_4_a,               # subtype 4: religious
    PoliticalBandwidth      = politicalbandwidth,
    LogCapitalDistance      = ln_capital_dist_km,
    SenderCINCLog           = cinc_a_log,
    TargetCINCLog           = cinc_b_log
  )

# Diagnostic: check variation in key variables
message("Summary of RevisionistLegitimation (continuous):")
summary(df_model$RevisionistLegitimation) |> print()

message("Summary of NationalistLegitimation (continuous):")
summary(df_model$NationalistLegitimation) |> print()

message("Summary of SocialistLegitimation (continuous):")
summary(df_model$SocialistLegitimation) |> print()

message("Summary of ReligiousLegitimation (continuous):")
summary(df_model$ReligiousLegitimation) |> print()

message("Table of IdeologyMatch (binary):")
table(df_model$IdeologyMatch) |> print()

# ----------------------------------------------------------------------------
# H4: Baseline model (continuous revisionist legitimation)
# ----------------------------------------------------------------------------
model_h4_qp <- feglm(
  IdeologyMatch ~ RevisionistLegitimation +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# H4a–H4c: Sub-type alignment models (continuous subtype × matching NAG identity)
# ----------------------------------------------------------------------------
model_h4a_qp <- feglm(
  IdeologyMatch ~ NationalistLegitimation * nags_ethnonationalist +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

model_h4b_qp <- feglm(
  IdeologyMatch ~ SocialistLegitimation * nags_leftist +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

model_h4c_qp <- feglm(
  IdeologyMatch ~ ReligiousLegitimation * nags_religious +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Subsample analysis: only cases with nags_support_count > 0
# ----------------------------------------------------------------------------
df_subsample <- df_model |>
  filter(nags_support_count > 0)

message("Subsample (support > 0): ", nrow(df_subsample), " rows remaining")

model_h4_sub_qp <- feglm(
  IdeologyMatch ~ RevisionistLegitimation +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_subsample
)

# ----------------------------------------------------------------------------
# Save separate tables for each model (CSV + LaTeX)
# ----------------------------------------------------------------------------
# Baseline
etable(model_h4_qp,
       file = here("results/tables", "paper2_h4_baseline_quasipoisson.tex"),
       replace = TRUE)
write_csv(etable(model_h4_qp, tex = FALSE), here("results/tables", "paper2_h4_baseline_coefficients.csv"))

# Sub-type models
etable(model_h4a_qp,
       file = here("results/tables", "paper2_h4a_nationalist_quasipoisson.tex"),
       replace = TRUE)
etable(model_h4b_qp,
       file = here("results/tables", "paper2_h4b_socialist_quasipoisson.tex"),
       replace = TRUE)
etable(model_h4c_qp,
       file = here("results/tables", "paper2_h4c_religious_quasipoisson.tex"),
       replace = TRUE)

# Subsample
etable(model_h4_sub_qp,
       file = here("results/tables", "paper2_h4_subsample_quasipoisson.tex"),
       replace = TRUE)
write_csv(etable(model_h4_sub_qp, tex = FALSE), here("results/tables", "paper2_h4_subsample_coefficients.csv"))

message("All tables saved separately as CSV and LaTeX.")

# ----------------------------------------------------------------------------
# Predicted probabilities table (Revisionist Legitimation Quartiles - full sample)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  RevisionistLegitimation = quantile(df_model$RevisionistLegitimation, probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  PoliticalBandwidth      = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance      = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog           = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog           = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war                = 0,
  war_on_terror           = 0
)

preds <- predict(model_h4_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  RevisionistLegitimationLevel = c("Low (25th percentile)", "Median (50th percentile)", "High (75th percentile)"),
  PredictedProbability         = round(preds, 4)
)

print("Predicted Probabilities Table (H4 - full sample):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h4_predicted_probabilities.csv"))

# ----------------------------------------------------------------------------
# Predicted probabilities table (subsample)
# ----------------------------------------------------------------------------
preds_sub <- predict(model_h4_sub_qp, newdata = newdata, type = "response")

pred_table_sub <- data.frame(
  RevisionistLegitimationLevel = c("Low (25th percentile)", "Median (50th percentile)", "High (75th percentile)"),
  PredictedProbabilitySub      = round(preds_sub, 4)
)

print("Predicted Probabilities Table (H4 - subsample support > 0):")
print(pred_table_sub)
write_csv(pred_table_sub, here("results/tables", "paper2_h4_predicted_probabilities_subsample.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plots — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
# Full sample plot
me_plot_full <- ggplot(pred_table, aes(x = RevisionistLegitimationLevel, y = PredictedProbability)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  labs(title = "H4: Higher Revisionist Legitimation Increases Ideological Match (Full Sample)",
       x = "Revisionist Legitimation Level",
       y = "Predicted Probability of Ideology Match") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h4_marginal_effects_full.png"),
  plot     = me_plot_full,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

# Subsample plot
me_plot_sub <- ggplot(pred_table_sub, aes(x = RevisionistLegitimationLevel, y = PredictedProbabilitySub)) +
  geom_point(size = 4, color = "darkgreen") +
  geom_line(aes(group = 1), linewidth = 1, color = "darkgreen") +
  labs(title = "H4: Higher Revisionist Legitimation Increases Ideological Match (Subsample: Support > 0)",
       x = "Revisionist Legitimation Level",
       y = "Predicted Probability of Ideology Match") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h4_marginal_effects_subsample.png"),
  plot     = me_plot_sub,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plots saved directly: paper2_h4_marginal_effects_full.png and paper2_h4_marginal_effects_subsample.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h4_qp", "model_h4a_qp", "model_h4b_qp", "model_h4c_qp", "model_h4_sub_qp")))
gc()
message("[05] Environment cleaned. Ready for next model.")