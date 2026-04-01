# =============================================================================
# 05_model_paper2_h2_revisionist_support.R
# H2: Among autocracies, higher revisionist support increases NAG support as signaling to coalitions
# Primary DV: nags_support_count
# Primary: NB (full) | QP robustness | Subsample intensity (NB) | Subtype models
# =============================================================================

here::i_am("R/models/05_model_paper2_h2_revisionist_support.R")

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
  drop_na(nags_support_count, sidea_revisionist_domestic,
          v2exl_legitideolcr_0_a, v2exl_legitideolcr_1_a, v2exl_legitideolcr_4_a,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    `Revisionist Support Level` = sidea_revisionist_domestic,
    `Political Bandwidth`       = politicalbandwidth,
    `Log Capital Distance`      = ln_capital_dist_km,
    `Sender CINC (log)`         = cinc_a_log,
    `Target CINC (log)`         = cinc_b_log,
    
    NationalistLegitimation     = v2exl_legitideolcr_0_a,
    SocialistLegitimation       = v2exl_legitideolcr_1_a,
    ReligiousLegitimation       = v2exl_legitideolcr_4_a
  )

# ----------------------------------------------------------------------------
# PRIMARY MODEL: Negative Binomial (full sample)
# ----------------------------------------------------------------------------
model_h2_nb <- fenegbin(
  nags_support_count ~ `Revisionist Support Level` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# ROBUSTNESS: Quasipoisson (full sample)
# ----------------------------------------------------------------------------
model_h2_qp <- feglm(
  nags_support_count ~ `Revisionist Support Level` +
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

model_h2_sub_nb <- fenegbin(
  nags_support_count ~ `Revisionist Support Level` +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_subsample
)

# ----------------------------------------------------------------------------
# SUB-TYPE ALIGNMENT MODELS (H2a–H2c)
# ----------------------------------------------------------------------------
model_h2a_nb <- fenegbin(
  nags_support_count ~ NationalistLegitimation * nags_ethnonationalist +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h2b_nb <- fenegbin(
  nags_support_count ~ SocialistLegitimation * nags_leftist +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h2c_nb <- fenegbin(
  nags_support_count ~ ReligiousLegitimation * nags_religious +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Save tables 
# ----------------------------------------------------------------------------
etable(model_h2_nb, model_h2_qp, model_h2_sub_nb,
       file = here("results/tables", "paper2_h2_nb_qp_sub.tex"),
       replace = TRUE)

etable(model_h2a_nb, model_h2b_nb, model_h2c_nb,
       file = here("results/tables", "paper2_h2_subtypes.tex"),
       replace = TRUE)

coef_table <- etable(model_h2_nb, model_h2_qp, model_h2_sub_nb, tex = FALSE)
write_csv(coef_table, here("results/tables", "paper2_h2_coefficients.csv"))

# ----------------------------------------------------------------------------
# NEW: Save stripped RDS models (Rule 6)
# ----------------------------------------------------------------------------
source(here("R/shared/utils_model.R"))

saveRDS(strip_model(model_h2_nb), 
        here("results/models/h2_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h2_qp), 
        here("results/models/h2_qp_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h2_sub_nb), 
        here("results/models/h2_sub_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h2a_nb), 
        here("results/models/h2a_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h2b_nb), 
        here("results/models/h2b_nb_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h2c_nb), 
        here("results/models/h2c_nb_stripped.rds"), compress = "xz")

message("Stripped RDS models saved.")

# ----------------------------------------------------------------------------
# Predicted counts table — explicit order (Rule 14)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  `Revisionist Support Level` = quantile(df_model$`Revisionist Support Level`, 
                                         probs = c(0.25, 0.5, 0.75), na.rm = TRUE),
  `Political Bandwidth`       = mean(df_model$`Political Bandwidth`, na.rm = TRUE),
  `Log Capital Distance`      = mean(df_model$`Log Capital Distance`, na.rm = TRUE),
  `Sender CINC (log)`         = mean(df_model$`Sender CINC (log)`, na.rm = TRUE),
  `Target CINC (log)`         = mean(df_model$`Target CINC (log)`, na.rm = TRUE),
  cold_war                    = 0,
  war_on_terror               = 0
)

preds <- predict(model_h2_nb, newdata = newdata, type = "response")

pred_table <- data.frame(
  `Revisionist Support Level` = factor(c("Low (25th)", "Median (50th)", "High (75th)"),
                                       levels = c("Low (25th)", "Median (50th)", "High (75th)")),
  `Predicted Count`           = round(preds, 4)
)

print("Predicted Counts Table (H2):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h2_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — explicit order (Rule 14)
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = `Revisionist.Support.Level`, y = `Predicted.Count`)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  labs(title = "H2: Higher Revisionist Support Increases NAG Support Count",
       x = "Revisionist Support Level",
       y = "Predicted NAG Support Count") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h2_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved: paper2_h2_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h2_nb", "model_h2_qp", "model_h2_sub_nb",
                          "model_h2a_nb", "model_h2b_nb", "model_h2c_nb")))
gc()
message("[H2] Environment cleaned. Ready for next model.")