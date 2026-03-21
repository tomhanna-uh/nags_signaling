# =============================================================================
# 05_model_paper2_h4_ideology_match.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H4: Higher continuous revisionist legitimation increases ideological match with supported NAGs
# =============================================================================
here::i_am("R/models/05_model_paper2_h4_ideology_match.R")

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
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    RevisionistLegitimation = sidea_revisionist_domestic,  # continuous predictor
    IdeologyMatch           = nags_ideology_match,         # binary DV
    PoliticalBandwidth      = politicalbandwidth,
    LogCapitalDistance      = ln_capital_dist_km,
    SenderCINCLog           = cinc_a_log,
    TargetCINCLog           = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Quasi-Poisson (committee recommendation, count-like binary)
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
# Robustness: Negative Binomial (your previous approach)
# ----------------------------------------------------------------------------
model_h4_nb <- tryCatch(
  fenegbin(
    IdeologyMatch ~ RevisionistLegitimation +
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
# Save tables (CSV + LaTeX) — no RDS models (Rule 4)
# ----------------------------------------------------------------------------
if (!is.null(model_h4_nb)) {
  etable(model_h4_qp, model_h4_nb,
         file = here("results/tables", "paper2_h4_quasipoisson_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h4_qp, model_h4_nb, tex = FALSE)
} else {
  etable(model_h4_qp,
         file = here("results/tables", "paper2_h4_quasipoisson.tex"),
         replace = TRUE)
  coef_table <- etable(model_h4_qp, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h4_coefficients.csv"))
message("Tables saved.")

# ----------------------------------------------------------------------------
# Predicted probabilities table (Revisionist Legitimation Quartiles)
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

print("Predicted Probabilities Table (H4):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h4_predicted_probabilities.csv"))
message("Predicted probabilities table saved.")

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG (no viewer pane)
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = RevisionistLegitimationLevel, y = PredictedProbability)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  labs(title = "H4: Higher Revisionist Legitimation Increases Ideological Match with Supported NAGs",
       x = "Revisionist Legitimation Level",
       y = "Predicted Probability of Ideology Match") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h4_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h4_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h4_qp", "model_h4_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")