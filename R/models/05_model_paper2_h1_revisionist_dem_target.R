# =============================================================================
# 05_model_paper2_h1_revisionist_dem_target.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H1: Revisionist autocrats send more NAG support to democracies
# =============================================================================
here::i_am("R/models/05_model_paper2_h1_revisionist_dem_target.R")

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
  drop_na(nags_any_support, revisionist_high, targets_democracy,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    `Revisionist Leader (High)` = revisionist_high,
    `Target is Democracy`       = targets_democracy,
    `Political Bandwidth`       = politicalbandwidth,
    `Log Capital Distance`      = ln_capital_dist_km,
    `Sender CINC (log)`         = cinc_a_log,
    `Target CINC (log)`         = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Quasi-Poisson
# ----------------------------------------------------------------------------
model_h1_qp <- feglm(
  nags_any_support ~ i(`Revisionist Leader (High)`, `Target is Democracy`) +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial
# ----------------------------------------------------------------------------
model_h1_nb <- fenegbin(
  nags_any_support ~ i(`Revisionist Leader (High)`, `Target is Democracy`) +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Save tables
# ----------------------------------------------------------------------------
etable(model_h1_qp, model_h1_nb,
       file = here("results/tables", "paper2_h1_quasipoisson_nb.tex"),
       replace = TRUE)

coef_table <- etable(model_h1_qp, model_h1_nb, tex = FALSE)
write_csv(coef_table, here("results/tables", "paper2_h1_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted probabilities table (Democracy Yes/No × Revisionist Quartiles)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  `Revisionist Leader (High)` = c(0, 1),
  `Target is Democracy`       = c(0, 1),
  `Political Bandwidth`       = mean(df_model$`Political Bandwidth`, na.rm = TRUE),
  `Log Capital Distance`      = mean(df_model$`Log Capital Distance`, na.rm = TRUE),
  `Sender CINC (log)`         = mean(df_model$`Sender CINC (log)`, na.rm = TRUE),
  `Target CINC (log)`         = mean(df_model$`Target CINC (log)`, na.rm = TRUE),
  cold_war                    = 0,
  war_on_terror               = 0
)

preds <- predict(model_h1_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  TargetDemocracy     = rep(c("No", "Yes"), each = 2),
  RevisionistLevel    = rep(c("Low (25th percentile)", "High (75th percentile)"), 2),
  PredictedProbability = round(preds, 4)
)

print("Predicted Probabilities Table:")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h1_predicted_probabilities.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG (no viewer pane, no margins error)
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = TargetDemocracy, y = PredictedProbability,
                                  color = RevisionistLevel, shape = RevisionistLevel)) +
  geom_point(size = 4) +
  geom_line(aes(group = RevisionistLevel), linewidth = 1) +
  labs(title = "H1: Revisionist Leaders More Likely to Support NAGs Targeting Democracies",
       x = "Target is Democracy (0 = No, 1 = Yes)",
       y = "Predicted Probability of Any NAG Support",
       color = "Revisionist Level",
       shape = "Revisionist Level") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h1_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h1_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h1_qp", "model_h1_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")