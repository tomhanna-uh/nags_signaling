# =============================================================================
# 05_model_paper2_h2_ideology_match.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H2: Revisionist autocrats are more likely to support ideologically matching NAGs
# =============================================================================
here::i_am("R/models/05_model_paper2_h2_ideology_match.R")

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
  drop_na(nags_support_count, revisionist_high, nags_ideology_match,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    `Revisionist Leader (High)` = revisionist_high,
    `Ideology Match`            = nags_ideology_match,
    `Political Bandwidth`       = politicalbandwidth,
    `Log Capital Distance`      = ln_capital_dist_km,
    `Sender CINC (log)`         = cinc_a_log,
    `Target CINC (log)`         = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Quasi-Poisson (committee recommendation)
# ----------------------------------------------------------------------------
model_h2_qp <- feglm(
  nags_support_count ~ i(`Revisionist Leader (High)`, `Ideology Match`) +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial
# ----------------------------------------------------------------------------
model_h2_nb <- fenegbin(
  nags_support_count ~ i(`Revisionist Leader (High)`, `Ideology Match`) +
    `Political Bandwidth` + `Log Capital Distance` +
    `Sender CINC (log)` + `Target CINC (log)` + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Save tables
# ----------------------------------------------------------------------------
etable(model_h2_qp, model_h2_nb,
       file = here("results/tables", "paper2_h2_quasipoisson_nb.tex"),
       replace = TRUE)

coef_table <- etable(model_h2_qp, model_h2_nb, tex = FALSE)
write_csv(coef_table, here("results/tables", "paper2_h2_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted probabilities table (Ideology Match Yes/No × Revisionist Quartiles)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  `Revisionist Leader (High)` = c(0, 1),
  `Ideology Match`            = c(0, 1),
  `Political Bandwidth`       = mean(df_model$`Political Bandwidth`, na.rm = TRUE),
  `Log Capital Distance`      = mean(df_model$`Log Capital Distance`, na.rm = TRUE),
  `Sender CINC (log)`         = mean(df_model$`Sender CINC (log)`, na.rm = TRUE),
  `Target CINC (log)`         = mean(df_model$`Target CINC (log)`, na.rm = TRUE),
  cold_war                    = 0,
  war_on_terror               = 0
)

preds <- predict(model_h2_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  IdeologyMatch       = rep(c("No", "Yes"), each = 2),
  RevisionistLevel    = rep(c("Low (25th percentile)", "High (75th percentile)"), 2),
  PredictedCount      = round(preds, 4)
)

print("Predicted Counts Table (H2):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h2_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = IdeologyMatch, y = PredictedCount,
                                  color = RevisionistLevel, shape = RevisionistLevel)) +
  geom_point(size = 4) +
  geom_line(aes(group = RevisionistLevel), linewidth = 1) +
  labs(title = "H2: Revisionist Leaders Prefer Ideologically Matching NAGs",
       x = "Ideology Match (0 = No, 1 = Yes)",
       y = "Predicted NAG Support Count",
       color = "Revisionist Level",
       shape = "Revisionist Level") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h2_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h2_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h2_qp", "model_h2_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")