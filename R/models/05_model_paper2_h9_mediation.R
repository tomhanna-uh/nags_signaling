# =============================================================================
# 05_model_paper2_h9_mediation.R
# Tier 1 Model for Paper 2 (Ideological Commitment Signaling)
# H9: Revisionist ideology → support-group legitimation → NAG support (mediation)
# =============================================================================
here::i_am("R/models/05_model_paper2_h9_mediation.R")

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
  drop_na(nags_support_count, revisionist_high,
          sidea_religious_support, sidea_party_elite_support,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    RevisionistHigh         = revisionist_high,
    ReligiousSupport        = sidea_religious_support,
    PartyEliteSupport       = sidea_party_elite_support,
    PoliticalBandwidth      = politicalbandwidth,
    LogCapitalDistance      = ln_capital_dist_km,
    SenderCINCLog           = cinc_a_log,
    TargetCINCLog           = cinc_b_log
  )

# ----------------------------------------------------------------------------
# Step 1: First-stage models (Revisionist → mediators)
# ----------------------------------------------------------------------------
first_religious <- feglm(
  ReligiousSupport ~ RevisionistHigh +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = gaussian,
  cluster = ~dyad,
  data = df_model
)

first_party <- feglm(
  PartyEliteSupport ~ RevisionistHigh +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = gaussian,
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Step 2: Second-stage models (mediators → NAG support)
# ----------------------------------------------------------------------------
model_h9_qp_rel <- feglm(
  nags_support_count ~ ReligiousSupport +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

model_h9_qp_party <- feglm(
  nags_support_count ~ PartyEliteSupport +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ----------------------------------------------------------------------------
# Save tables
# ----------------------------------------------------------------------------
etable(model_h9_qp_rel, model_h9_qp_party,
       file = here("results/tables", "paper2_h9_mediation.tex"),
       replace = TRUE)

coef_table <- etable(model_h9_qp_rel, model_h9_qp_party, tex = FALSE)
write_csv(coef_table, here("results/tables", "paper2_h9_coefficients.csv"))

# ----------------------------------------------------------------------------
# Predicted counts table (at mean mediator levels)
# ----------------------------------------------------------------------------
newdata <- expand.grid(
  ReligiousSupport     = mean(df_model$ReligiousSupport, na.rm = TRUE),
  PartyEliteSupport    = mean(df_model$PartyEliteSupport, na.rm = TRUE),
  PoliticalBandwidth   = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance   = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog        = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog        = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war             = 0,
  war_on_terror        = 0
)

pred_rel  <- predict(model_h9_qp_rel,  newdata = newdata, type = "response")
pred_party <- predict(model_h9_qp_party, newdata = newdata, type = "response")

pred_table <- data.frame(
  Mediator                = c("Religious Support", "Party-Elite Support"),
  PredictedNAGCount       = round(c(pred_rel, pred_party), 4)
)

print("Predicted Counts Table (H9 Mediation):")
print(pred_table)
write_csv(pred_table, here("results/tables", "paper2_h9_predicted_counts.csv"))

# ----------------------------------------------------------------------------
# Marginal effects plot — saved DIRECTLY to PNG
# ----------------------------------------------------------------------------
me_plot <- ggplot(pred_table, aes(x = Mediator, y = PredictedNAGCount)) +
  geom_point(size = 5, color = "darkblue") +
  geom_segment(aes(x = 1, xend = 2, y = pred_rel, yend = pred_party), linewidth = 1) +
  labs(title = "H9: Mediation - Revisionist Ideology → Support Groups → NAG Support",
       x = "Mediator",
       y = "Predicted NAG Support Count") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h9_mediation_plot.png"),
  plot     = me_plot,
  width    = 9,
  height   = 6,
  dpi      = 300,
  units    = "in"
)

message("Plot saved directly: paper2_h9_mediation_plot.png")

# ----------------------------------------------------------------------------
# Aggressive cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "model_h9_qp_rel", "model_h9_qp_party")))
gc()
message("[05] Environment cleaned. Ready for next model.")