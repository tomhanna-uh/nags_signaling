# =============================================================================
# 05_model_paper2_h7_legitimation_ratios.R
# H7: Test ideological vs. personalist legitimation dependence
# (Rational Autocrat signaling vs. Messianic/charismatic mechanism)
# Primary DV: nags_support_count (count) + nags_any_support (binary)
# Primary: Negative Binomial | QP robustness | Subsample intensity | Subtype models
# Additional: Logit on nags_any_support with Probit robustness
# =============================================================================

here::i_am("R/models/05_model_paper2_h7_legitimation_ratios.R")

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
# Prepare modeling sample and compute legitimation ratios
# ----------------------------------------------------------------------------
df_model <- df_final %>%
  filter(autocracy_a == 1) %>%
  drop_na(nags_support_count, nags_any_support,
          legit_ideol_ratio_norm,
          v2exl_legitlead_a, v2exl_legitideol_a,
          v2exl_legitperf_a,
          sidea_revisionist_domestic,
          cinc_a_log, cinc_b_log, ln_capital_dist_km,
          politicalbandwidth_norm) %>%
  mutate(
    `Ideological Legitimation Ratio (norm)` = legit_ideol_ratio_norm,
    
    eps = 1e-6,
    `Personalist Legitimation Ratio` = v2exl_legitlead_a /
      (v2exl_legitideol_a + v2exl_legitlead_a + v2exl_legitperf_a + eps),
    
    `Revisionist Domestic Ideology` = sidea_revisionist_domestic,
    `Political Bandwidth`           = politicalbandwidth_norm,
    `Log Capital Distance`          = ln_capital_dist_km,
    `Sender CINC (log)`             = cinc_a_log,
    `Target CINC (log)`             = cinc_b_log,
    
    NationalistLegitimation         = v2exl_legitideolcr_0_a,
    SocialistLegitimation           = v2exl_legitideolcr_1_a,
    ReligiousLegitimation           = v2exl_legitideolcr_4_a
  )

message("Modeling sample size: ", nrow(df_model), " dyad-years")

# ----------------------------------------------------------------------------
# PRIMARY MODELS — nags_support_count (count)
# ----------------------------------------------------------------------------
# Model 1: Ideological Legitimation Dependence (main hypothesis)
model_h7_ideol_nb <- fenegbin(
  nags_support_count ~ `Ideological Legitimation Ratio (norm)` +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  cluster = ~dyad,
  data = df_model
)

# Model 1a: Ideological Legitimation Dependence without sidea_revisionist_domestic
model_h7_ideol_1a_nb <- fenegbin(
  nags_support_count ~ `Ideological Legitimation Ratio (norm)` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  cluster = ~dyad,
  data = df_model
)

# Model 2: Personalist Legitimation Dependence (Messianic competing hypothesis)
model_h7_personalist_nb <- fenegbin(
  nags_support_count ~ `Personalist Legitimation Ratio` +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  cluster = ~dyad,
  data = df_model
)

# Robustness: Quasipoisson versions (count)
model_h7_ideol_qp <- feglm(
  nags_support_count ~ `Ideological Legitimation Ratio (norm)` +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

model_h7_personalist_qp <- feglm(
  nags_support_count ~ `Personalist Legitimation Ratio` +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# ADDITIONAL: Logit on nags_any_support (binary) with Probit robustness
# ----------------------------------------------------------------------------
model_h7_any_logit <- feglm(
  nags_any_support ~ `Ideological Legitimation Ratio (norm)` +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

model_h7_any_probit <- feglm(
  nags_any_support ~ `Ideological Legitimation Ratio (norm)` +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  family = binomial(link = "probit"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# SUBSAMPLE: Intensity given support occurred (nags_support_count > 0)
# ----------------------------------------------------------------------------
df_subsample <- df_model |>
  filter(nags_support_count > 0)

message("Subsample (nags_support_count > 0): ", nrow(df_subsample), " rows remaining")

model_h7_sub_nb <- fenegbin(
  nags_support_count ~ `Ideological Legitimation Ratio (norm)` +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  cluster = ~dyad,
  data = df_subsample
)

# ----------------------------------------------------------------------------
# SUB-TYPE ALIGNMENT MODELS (H7a–H7c)
# ----------------------------------------------------------------------------
model_h7a_nb <- fenegbin(
  nags_support_count ~ `Ideological Legitimation Ratio (norm)` * nags_ethnonationalist +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  cluster = ~dyad,
  data = df_model
)

model_h7b_nb <- fenegbin(
  nags_support_count ~ `Ideological Legitimation Ratio (norm)` * nags_leftist +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  cluster = ~dyad,
  data = df_model
)

model_h7c_nb <- fenegbin(
  nags_support_count ~ `Ideological Legitimation Ratio (norm)` * nags_religious +
    `Revisionist Domestic Ideology` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)`,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Save tables 
# ----------------------------------------------------------------------------
etable(model_h7_ideol_nb, model_h7_ideol_1a_nb, model_h7_personalist_nb,
       file = here("results/tables/paper2_h7_legitimation_ratios.tex"),
       replace = TRUE)

etable(model_h7_any_logit, model_h7_any_probit,
       file = here("results/tables/paper2_h7_any_logit_probit.tex"),
       replace = TRUE)

etable(model_h7a_nb, model_h7b_nb, model_h7c_nb,
       file = here("results/tables/paper2_h7_subtypes.tex"),
       replace = TRUE)

coef_table <- etable(model_h7_ideol_nb, model_h7_ideol_1a_nb, model_h7_personalist_nb, 
                     model_h7_any_logit, model_h7_any_probit, model_h7_sub_nb, tex = FALSE)
write_csv(coef_table, here("results/tables/paper2_h7_coefficients.csv"))

# ----------------------------------------------------------------------------
# NEW: Save stripped RDS models (Rule 6)
# ----------------------------------------------------------------------------
source(here("R/shared/utils_model.R"))

saveRDS(strip_model(model_h7_ideol_nb), 
        here("results/models/h7_ideol_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7_ideol_1a_nb), 
        here("results/models/h7_ideol_1a_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7_personalist_nb), 
        here("results/models/h7_personalist_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7_any_logit), 
        here("results/models/h7_any_logit_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7_any_probit), 
        here("results/models/h7_any_probit_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7_sub_nb), 
        here("results/models/h7_sub_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7a_nb), 
        here("results/models/h7a_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7b_nb), 
        here("results/models/h7b_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h7c_nb), 
        here("results/models/h7c_nb_stripped.rds"), compress = "xz")

message("Stripped RDS models saved.")

# ----------------------------------------------------------------------------
# Predicted counts table for Ideological Ratio — explicit order (Rule 14)
# ----------------------------------------------------------------------------
newdata_ideol <- expand.grid(
  `Ideological Legitimation Ratio (norm)` = quantile(df_model$`Ideological Legitimation Ratio (norm)`, 
                                                     probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  `Revisionist Domestic Ideology`         = mean(df_model$`Revisionist Domestic Ideology`, na.rm = TRUE),
  `Political Bandwidth`                   = mean(df_model$`Political Bandwidth`, na.rm = TRUE),
  `Log Capital Distance`                  = mean(df_model$`Log Capital Distance`, na.rm = TRUE),
  `Sender CINC (log)`                     = mean(df_model$`Sender CINC (log)`, na.rm = TRUE),
  `Target CINC (log)`                     = mean(df_model$`Target CINC (log)`, na.rm = TRUE)
)

preds_ideol <- predict(model_h7_ideol_nb, newdata = newdata_ideol, type = "response")

pred_table_ideol <- data.frame(
  IdeologicalRatioLevel = factor(c("Low (25th)", "Median (50th)", "High (75th)"),
                                 levels = c("Low (25th)", "Median (50th)", "High (75th)")),
  PredictedCount        = round(preds_ideol, 4)
)

print("Predicted Counts Table (Ideological Ratio):")
print(pred_table_ideol)
write_csv(pred_table_ideol, here("results/tables/paper2_h7_predicted_counts_ideol.csv"))



# ----------------------------------------------------------------------------
# NEW: Predicted counts table for Personalist (Dynamic) Legitimation Ratio
# ----------------------------------------------------------------------------
newdata_pers <- expand.grid(
  `Personalist Legitimation Ratio` = quantile(df_model$`Personalist Legitimation Ratio`, 
                                              probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  `Revisionist Domestic Ideology`  = mean(df_model$`Revisionist Domestic Ideology`, na.rm = TRUE),
  `Political Bandwidth`            = mean(df_model$`Political Bandwidth`, na.rm = TRUE),
  `Log Capital Distance`           = mean(df_model$`Log Capital Distance`, na.rm = TRUE),
  `Sender CINC (log)`              = mean(df_model$`Sender CINC (log)`, na.rm = TRUE),
  `Target CINC (log)`              = mean(df_model$`Target CINC (log)`, na.rm = TRUE)
)

preds_pers <- predict(model_h7_personalist_nb, newdata = newdata_pers, type = "response")

pred_table_pers <- data.frame(
  PersonalistRatioLevel = factor(c("Low (25th)", "Median (50th)", "High (75th)"),
                                 levels = c("Low (25th)", "Median (50th)", "High (75th)")),
  PredictedCount        = round(preds_pers, 4)
)

print("Predicted Counts Table (Personalist/Dynamic Ratio):")
print(pred_table_pers)
write_csv(pred_table_pers, here("results/tables/paper2_h7_predicted_counts_personalist.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plots
# ----------------------------------------------------------------------------
# Plot 1: Ideological Ratio
me_plot_ideol <- ggplot(pred_table_ideol, aes(x = IdeologicalRatioLevel, y = PredictedCount)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  scale_y_log10() +   # <-- This makes small numbers visible +
  labs(title = "H7: Ideological Legitimation Ratio and NAG Support Count",
       x = "Ideological Legitimation Ratio (normalized)",
       y = "Predicted NAG Support Count (log scale)") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots/paper2_h7_marginal_effects_ideol.png"),
  plot     = me_plot_ideol,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

# Plot 2: Personalist (Dynamic) Legitimation Ratio — NEW
me_plot_pers <- ggplot(pred_table_pers, aes(x = PersonalistRatioLevel, y = PredictedCount)) +
  geom_point(size = 4, color = "darkred") +
  geom_line(aes(group = 1), linewidth = 1, color = "darkred") +
  scale_y_log10() +   # <-- This makes small numbers visible +
  labs(title = "H7: Personalist (Dynamic) Legitimation Ratio and NAG Support Count",
       x = "Personalist Legitimation Ratio",
       y = "Predicted NAG Support Count (log scale)") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots/paper2_h7_marginal_effects_personalist.png"),
  plot     = me_plot_pers,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plots saved: paper2_h7_marginal_effects_ideol.png and paper2_h7_marginal_effects_personalist.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
# rm(list = setdiff(ls(), c("df_final", "model_h7_ideol_nb", "model_h7_ideol_1a_nb", 
#                           "model_h7_personalist_nb", "model_h7_ideol_qp",
#                           "model_h7_any_logit", "model_h7_any_probit",
#                           "model_h7_sub_nb", "model_h7a_nb", "model_h7b_nb", "model_h7c_nb")))
# gc()
message("[H7] Environment cleaned. Ready for next model.")