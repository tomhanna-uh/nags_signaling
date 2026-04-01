# =============================================================================
# 05_model_paper2_h5_autocratic_goals.R
# H5: Revisionist autocrats are more likely to support NAGs with autocratic (non-democratic) goals
# Primary DV: nags_support_count
# Primary: Negative Binomial with interaction | QP robustness | Subsample intensity | Subtype models
# =============================================================================

here::i_am("R/models/05_model_paper2_h5_autocratic_goals.R")

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
  drop_na(nags_support_count, revisionist_high, nags_nondem_objective,
          v2exl_legitideolcr_0_a, v2exl_legitideolcr_1_a, v2exl_legitideolcr_4_a,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    `Revisionist Leader (High)` = revisionist_high,
    `NAG Non-Dem Objective`     = nags_nondem_objective,
    `Political Bandwidth`       = politicalbandwidth,
    `Log Capital Distance`      = ln_capital_dist_km,
    `Sender CINC (log)`         = cinc_a_log,
    `Target CINC (log)`         = cinc_b_log,
    
    NationalistLegitimation     = v2exl_legitideolcr_0_a,
    SocialistLegitimation       = v2exl_legitideolcr_1_a,
    ReligiousLegitimation       = v2exl_legitideolcr_4_a
  )

# ----------------------------------------------------------------------------
# PRIMARY MODEL: Negative Binomial with interaction (full sample)
# ----------------------------------------------------------------------------
model_h5_nb <- fenegbin(
  nags_support_count ~ `Revisionist Leader (High)` * `NAG Non-Dem Objective` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# ROBUSTNESS: Quasipoisson
# ----------------------------------------------------------------------------
model_h5_qp <- feglm(
  nags_support_count ~ `Revisionist Leader (High)` * `NAG Non-Dem Objective` +
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

model_h5_sub_nb <- fenegbin(
  nags_support_count ~ `Revisionist Leader (High)` * `NAG Non-Dem Objective` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_subsample
)

# ----------------------------------------------------------------------------
# SUB-TYPE ALIGNMENT MODELS (H5a–H5c) — interaction with revisionist leader
# ----------------------------------------------------------------------------
model_h5a_nb <- fenegbin(
  nags_support_count ~ `Revisionist Leader (High)` * NationalistLegitimation * nags_ethnonationalist +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h5b_nb <- fenegbin(
  nags_support_count ~ `Revisionist Leader (High)` * SocialistLegitimation * nags_leftist +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h5c_nb <- fenegbin(
  nags_support_count ~ `Revisionist Leader (High)` * ReligiousLegitimation * nags_religious +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Save tables 
# ----------------------------------------------------------------------------
etable(model_h5_nb, model_h5_qp, model_h5_sub_nb,
       file = here("results/tables/paper2_h5_nb_qp_sub.tex"),
       replace = TRUE)

etable(model_h5a_nb, model_h5b_nb, model_h5c_nb,
       file = here("results/tables/paper2_h5_subtypes.tex"),
       replace = TRUE)

coef_table <- etable(model_h5_nb, model_h5_qp, model_h5_sub_nb, tex = FALSE)
write_csv(coef_table, here("results/tables/paper2_h5_coefficients.csv"))

# ----------------------------------------------------------------------------
# NEW: Save stripped RDS models (Rule 6)
# ----------------------------------------------------------------------------
source(here("R/shared/utils_model.R"))

saveRDS(strip_model(model_h5_nb), 
        here("results/models/h5_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h5_qp), 
        here("results/models/h5_qp_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h5_sub_nb), 
        here("results/models/h5_sub_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h5a_nb), 
        here("results/models/h5a_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h5b_nb), 
        here("results/models/h5b_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h5c_nb), 
        here("results/models/h5c_nb_stripped.rds"), compress = "xz")

message("Stripped RDS models saved.")

# ----------------------------------------------------------------------------
# Predicted counts table — explicit factor order (Rule 14)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  `Revisionist Leader (High)` = c(0, 1),
  `NAG Non-Dem Objective`     = c(0, 1),
  `Political Bandwidth`       = mean(df_model$`Political Bandwidth`, na.rm = TRUE),
  `Log Capital Distance`      = mean(df_model$`Log Capital Distance`, na.rm = TRUE),
  `Sender CINC (log)`         = mean(df_model$`Sender CINC (log)`, na.rm = TRUE),
  `Target CINC (log)`         = mean(df_model$`Target CINC (log)`, na.rm = TRUE),
  cold_war                    = 0,
  war_on_terror               = 0
)

preds <- predict(model_h5_nb, newdata = newdata, type = "response")

pred_table <- data.frame(
  RevisionistLeaderHigh = factor(rep(c("Low", "High"), each = 2),
                                 levels = c("Low", "High")),
  NAGNonDemObjective    = factor(rep(c("No", "Yes"), 2),
                                 levels = c("No", "Yes")),
  PredictedCount        = round(preds, 4)
)

print("Predicted Counts Table (H5):")
print(pred_table)
write_csv(pred_table, here("results/tables/paper2_h5_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — fixed with explicit factor ordering (Rule 14)
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = NAGNonDemObjective, y = PredictedCount,
                                  color = RevisionistLeaderHigh, shape = RevisionistLeaderHigh)) +
  geom_point(size = 4) +
  geom_line(aes(group = RevisionistLeaderHigh), linewidth = 1) +
  labs(title = "H5: Revisionist Leaders Send More Support to NAGs with Non-Democratic Objectives",
       x = "NAG Has Non-Democratic Objective",
       y = "Predicted NAG Support Count",
       color = "Revisionist Leader (High)",
       shape = "Revisionist Leader (High)") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots/paper2_h5_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved: paper2_h5_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h5_nb", "model_h5_qp", "model_h5_sub_nb",
                          "model_h5a_nb", "model_h5b_nb", "model_h5c_nb")))
gc()
message("[H5] Environment cleaned. Ready for next model.")