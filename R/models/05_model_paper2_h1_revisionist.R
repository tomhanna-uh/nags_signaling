# =============================================================================
# 05_model_paper2_h1_revisionist_dem_target.R
# H1: Revisionist autocrats send more NAG support (any)
# Primary: Logit | Robustness: Probit | Subtype logits (H1a–H1c)
# =============================================================================

here::i_am("R/models/05_model_paper2_h1_revisionist.R")

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
# Prepare model data with friendly English labels 
# ---------------------------------------------------------------------------- 
df_model <- df_final |>
  drop_na(nags_any_support, sidea_revisionist_domestic,
          v2exl_legitideolcr_0_a, v2exl_legitideolcr_1_a, v2exl_legitideolcr_4_a,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    RevisionistLeader       = sidea_revisionist_domestic,
    PoliticalBandwidth      = politicalbandwidth,
    LogCapitalDistance      = ln_capital_dist_km,
    SenderCINCLog           = cinc_a_log,
    TargetCINCLog           = cinc_b_log,
    
    NationalistLegitimation = v2exl_legitideolcr_0_a,
    SocialistLegitimation   = v2exl_legitideolcr_1_a,
    ReligiousLegitimation   = v2exl_legitideolcr_4_a
  )

# ---------------------------------------------------------------------------- 
# PRIMARY MODEL: Logit
# ---------------------------------------------------------------------------- 
model_h1_logit <- feglm(
  nags_any_support ~ RevisionistLeader +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

# ---------------------------------------------------------------------------- 
# ROBUSTNESS: Probit
# ---------------------------------------------------------------------------- 
model_h1_probit <- feglm(
  nags_any_support ~ RevisionistLeader +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "probit"),
  cluster = ~dyad,
  data = df_model
)

# ---------------------------------------------------------------------------- 
# SUB-TYPE ALIGNMENT MODELS (H1a–H1c)
# ---------------------------------------------------------------------------- 
model_h1a_logit <- feglm(
  nags_any_support ~ NationalistLegitimation * nags_ethnonationalist +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

model_h1b_logit <- feglm(
  nags_any_support ~ SocialistLegitimation * nags_leftist +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

model_h1c_logit <- feglm(
  nags_any_support ~ ReligiousLegitimation * nags_religious +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = binomial(link = "logit"),
  cluster = ~dyad,
  data = df_model
)

# ---------------------------------------------------------------------------- 
# Save tables (original structure preserved)
# ---------------------------------------------------------------------------- 
etable(model_h1_logit, model_h1_probit,
       file = here("results/tables", "paper2_h1_logit_probit.tex"),
       replace = TRUE)

etable(model_h1a_logit, model_h1b_logit, model_h1c_logit,
       file = here("results/tables", "paper2_h1_subtypes.tex"),
       replace = TRUE)

coef_table <- etable(model_h1_logit, model_h1_probit, tex = FALSE)
write_csv(coef_table, here("results/tables", "paper2_h1_coefficients.csv"))

# ---------------------------------------------------------------------------- 
# Predicted probabilities table (Revisionist Leader High vs Low)
# ---------------------------------------------------------------------------- 
newdata <- expand.grid(
  RevisionistLeader   = c(0, 1),
  PoliticalBandwidth  = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance  = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog       = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog       = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war            = 0,
  war_on_terror       = 0
)

preds <- predict(model_h1_logit, newdata = newdata, type = "response")

pred_table <- data.frame(
  RevisionistLevel      = factor(c("Low", "High"), levels = c("Low", "High")),
  PredictedProbability  = round(preds, 4)
)

print("Predicted Probabilities Table (H1):")
print(pred_table)
write_csv(pred_table, here("results/tables/paper2_h1_predicted_probabilities.csv"))

# ---------------------------------------------------------------------------- 
# Marginal effects plot 
# ---------------------------------------------------------------------------- 
me_plot <- ggplot(pred_table, aes(x = RevisionistLevel, y = PredictedProbability)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  labs(title = "H1: Revisionist Leaders Send More NAG Support",
       x = "Revisionist Leader (High vs Low)",
       y = "Predicted Probability of Any NAG Support") +
  theme_minimal(base_size = 14)

ggsave(
  filename = here("results/plots", "paper2_h1_marginal_effects.png"),
  plot     = me_plot,
  width    = 10,
  height   = 7,
  dpi      = 300,
  units    = "in"
)

message("Plot saved: paper2_h1_marginal_effects.png")

# ---------------------------------------------------------------------------- 
# Aggressive cleanup 
# ---------------------------------------------------------------------------- 
rm(list = setdiff(ls(), c("df_final", "model_h1_logit", "model_h1_probit", 
                          "model_h1a_logit", "model_h1b_logit", "model_h1c_logit")))
gc()
message("[05] Environment cleaned. Ready for next model.")
