# =============================================================================
# 05_model_paper2_h3_dynamic_leader.R
# H3: Dynamic/messianic leaders amplify the effect of continuous revisionist legitimation on NAG support
# Primary DV: nags_support_count
# Primary: Negative Binomial | Robustness: Quasipoisson
# Includes interaction + subsample intensity + subtype models
# =============================================================================

here::i_am("R/models/05_model_paper2_h3_dynamic_leader.R")

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
  drop_na(nags_support_count, sidea_dynamic_leader, sidea_revisionist_domestic,
          v2exl_legitideolcr_0_a, v2exl_legitideolcr_1_a, v2exl_legitideolcr_4_a,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    `Dynamic Leader`            = sidea_dynamic_leader,
    `Revisionist Legitimation`  = sidea_revisionist_domestic,
    `Political Bandwidth`       = politicalbandwidth,
    `Log Capital Distance`      = ln_capital_dist_km,
    `Sender CINC (log)`         = cinc_a_log,
    `Target CINC (log)`         = cinc_b_log,
    
    NationalistLegitimation     = v2exl_legitideolcr_0_a,
    SocialistLegitimation       = v2exl_legitideolcr_1_a,
    ReligiousLegitimation       = v2exl_legitideolcr_4_a
  )

# ----------------------------------------------------------------------------
# PRIMARY MODEL: Negative Binomial (full sample) with interaction
# ----------------------------------------------------------------------------
model_h3_nb <- fenegbin(
  nags_support_count ~ `Dynamic Leader` * `Revisionist Legitimation` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# ROBUSTNESS: Quasipoisson
# ----------------------------------------------------------------------------
model_h3_qp <- feglm(
  nags_support_count ~ `Dynamic Leader` * `Revisionist Legitimation` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# SUBSAMPLE: Intensity given support occurred (nags_support_count > 0)
# ----------------------------------------------------------------------------
df_subsample <- df_model |>
  filter(nags_support_count > 0)

message("Subsample (nags_support_count > 0): ", nrow(df_subsample), " rows remaining")

model_h3_sub_nb <- fenegbin(
  nags_support_count ~ `Dynamic Leader` * `Revisionist Legitimation` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_subsample
)

# ----------------------------------------------------------------------------
# SUB-TYPE ALIGNMENT MODELS (H3a–H3c) — interaction with dynamic leader
# ----------------------------------------------------------------------------
model_h3a_nb <- fenegbin(
  nags_support_count ~ `Dynamic Leader` * NationalistLegitimation * nags_ethnonationalist +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h3b_nb <- fenegbin(
  nags_support_count ~ `Dynamic Leader` * SocialistLegitimation * nags_leftist +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h3c_nb <- fenegbin(
  nags_support_count ~ `Dynamic Leader` * ReligiousLegitimation * nags_religious +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Save tables 
# ----------------------------------------------------------------------------
etable(model_h3_nb, model_h3_qp, model_h3_sub_nb,
       file = here("results/tables/paper2_h3_nb_qp_sub.tex"),
       replace = TRUE)

etable(model_h3a_nb, model_h3b_nb, model_h3c_nb,
       file = here("results/tables/paper2_h3_subtypes.tex"),
       replace = TRUE)

coef_table <- etable(model_h3_nb, model_h3_qp, model_h3_sub_nb, tex = FALSE)
write_csv(coef_table, here("results/tables/paper2_h3_coefficients.csv"))

# ----------------------------------------------------------------------------
# NEW: Save stripped RDS models (Rule 6)
# ----------------------------------------------------------------------------
source(here("R/shared/utils_model.R"))

saveRDS(strip_model(model_h3_nb), 
        here("results/models/h3_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h3_qp), 
        here("results/models/h3_qp_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h3_sub_nb), 
        here("results/models/h3_sub_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h3a_nb), 
        here("results/models/h3a_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h3b_nb), 
        here("results/models/h3b_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h3c_nb), 
        here("results/models/h3c_nb_stripped.rds"), compress = "xz")

message("Stripped RDS models saved.")

# ----------------------------------------------------------------------------
# Predicted counts table — explicit Low-to-High order (Rule 14)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  `Dynamic Leader`           = quantile(df_model$`Dynamic Leader`, probs = c(0.25, 0.75), na.rm = TRUE),
  `Revisionist Legitimation` = quantile(df_model$`Revisionist Legitimation`, probs = c(0.25, 0.75), na.rm = TRUE),
  `Political Bandwidth`      = mean(df_model$`Political Bandwidth`, na.rm = TRUE),
  `Log Capital Distance`     = mean(df_model$`Log Capital Distance`, na.rm = TRUE),
  `Sender CINC (log)`        = mean(df_model$`Sender CINC (log)`, na.rm = TRUE),
  `Target CINC (log)`        = mean(df_model$`Target CINC (log)`, na.rm = TRUE),
  cold_war                   = 0,
  war_on_terror              = 0
)

preds <- predict(model_h3_nb, newdata = newdata, type = "response")

pred_table <- data.frame(
  DynamicLeaderLevel    = factor(rep(c("Low Dynamic (25th)", "High Dynamic (75th)"), each = 2),
                                 levels = c("Low Dynamic (25th)", "High Dynamic (75th)")),
  RevisionistLevel      = factor(rep(c("Low Revisionist (25th)", "High Revisionist (75th)"), 2),
                                 levels = c("Low Revisionist (25th)", "High Revisionist (75th)")),
  PredictedCount        = round(preds, 4)
)

print("Predicted Counts Table (H3):")
print(pred_table)
write_csv(pred_table, here("results/tables/paper2_h3_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — fixed with explicit factor ordering (Rule 14)
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = RevisionistLevel, y = PredictedCount,
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
  filename = here("results/plots/paper2_h3_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved: paper2_h3_marginal_effects.png")

print("Predicted Counts Table (H3):")
print(pred_table)
write_csv(pred_table, here("results/tables/paper2_h3_predicted_counts.csv"))



# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h3_nb", "model_h3_qp", "model_h3_sub_nb",
                          "model_h3a_nb", "model_h3b_nb", "model_h3c_nb")))
gc()
message("[H3] Environment cleaned. Ready for next model.")