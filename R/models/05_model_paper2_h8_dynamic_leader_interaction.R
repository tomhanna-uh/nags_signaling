# =============================================================================
# 05_model_paper2_h8_dynamic_leader_interaction.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H8: Dynamic/messianic leaders amplify the effect of revisionism on NAG support
# =============================================================================
here::i_am("R/models/05_model_paper2_h8_dynamic_leader_interaction.R")

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
  drop_na(nags_support_count, sidea_dynamic_leader, revisionist_high,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    DynamicLeader           = sidea_dynamic_leader,
    RevisionistHigh         = revisionist_high,
    PoliticalBandwidth      = politicalbandwidth,
    LogCapitalDistance      = ln_capital_dist_km,
    SenderCINCLog           = cinc_a_log,
    TargetCINCLog           = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Primary model: Quasi-Poisson (committee recommendation)
# ----------------------------------------------------------------------------
model_h8_qp <- feglm(
  nags_support_count ~ DynamicLeader * RevisionistHigh +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Robustness: Negative Binomial (with safety catch)
# ----------------------------------------------------------------------------
model_h8_nb <- tryCatch(
  fenegbin(
    nags_support_count ~ DynamicLeader * RevisionistHigh +
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
if (!is.null(model_h8_nb)) {
  etable(model_h8_qp, model_h8_nb,
         file = here("results/tables", "paper2_h8_quasipoisson_nb.tex"),
         replace = TRUE)
  coef_table <- etable(model_h8_qp, model_h8_nb, tex = FALSE)
} else {
  etable(model_h8_qp,
         file = here("results/tables", "paper2_h8_quasipoisson.tex"),
         replace = TRUE)
  coef_table <- etable(model_h8_qp, tex = FALSE)
}

write_csv(coef_table, here("results/tables", "paper2_h8_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted counts table (Dynamic Leader Quartiles × Revisionist High/Low)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  DynamicLeader       = quantile(df_final$sidea_dynamic_leader, probs = c(0.25, 0.75), na.rm = TRUE),
  RevisionistHigh     = c(0, 1),
  PoliticalBandwidth  = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance  = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog       = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog       = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war            = 0,
  war_on_terror       = 0
)

preds <- predict(model_h8_qp, newdata = newdata, type = "response")

pred_table <- data.frame(
  DynamicLeaderLevel = rep(c("Low (25th percentile)", "High (75th percentile)"), each = 2),
  RevisionistHigh    = rep(c("No", "Yes"), 2),
  PredictedCount     = round(preds, 4)
)

print("Predicted Counts Table (H8):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h8_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = RevisionistHigh, y = PredictedCount,
                                  color = DynamicLeaderLevel, shape = DynamicLeaderLevel)) +
  geom_point(size = 4) +
  geom_line(aes(group = DynamicLeaderLevel), linewidth = 1) +
  labs(title = "H8: Dynamic Leaders Amplify the Effect of Revisionism on NAG Support",
       x = "Revisionist Leader (High)",
       y = "Predicted NAG Support Count",
       color = "Dynamic Leader Level",
       shape = "Dynamic Leader Level") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h8_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h8_marginal_effects.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h8_qp", "model_h8_nb")))
gc()
message("[05] Environment cleaned. Ready for next model.")