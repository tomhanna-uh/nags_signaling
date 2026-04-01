# =============================================================================
# 05_model_paper2_h12_training_camps.R
# H12: Larger domestic opposition increases hosting of training camps
# Triadic data (Total, Active, De Facto) + Dynamic Leader interaction
# + New: Regime type (libdem) interaction models as additional specs
# =============================================================================

here::i_am("R/models/05_model_paper2_h12_training_camps.R")

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
library(readr)

# ---------------------------------------------------------------------------- 
# Prepare model data with friendly English labels 
# ---------------------------------------------------------------------------- 
df_model <- df_final |>
  drop_na(nags_training, oppsize_norm, sidea_dynamic_leader, v2x_libdem_a,
          politicalbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log) |>
  mutate(
    # Triadic training camp variables
    TrainingCamps        = Num_S_TrainCamp + Num_DS_TrainCamp,   # Combined total
    ActiveTrainingCamps  = Num_S_TrainCamp,                      # State-selected / intentional support
    DeFactoTrainingCamps = Num_DS_TrainCamp,                     # NAG-selected / de facto support
    
    # Friendly labels
    OppositionSizeNorm   = oppsize_norm,
    DynamicLeader        = sidea_dynamic_leader,
    Regimelibdem      = v2x_libdem_a,      # Higher = more competitive autocracy
    PoliticalBandwidth   = politicalbandwidth,
    LogCapitalDistance   = ln_capital_dist_km,
    SenderCINCLog        = cinc_a_log,
    TargetCINCLog        = cinc_b_log
  )

message("Training camp variables created - Total mean: ", round(mean(df_model$TrainingCamps), 3),
        " | Active: ", round(mean(df_model$ActiveTrainingCamps), 3),
        " | De Facto: ", round(mean(df_model$DeFactoTrainingCamps), 3))

# ---------------------------------------------------------------------------- 
# ORIGINAL MODELS (preserved exactly as before)
# ---------------------------------------------------------------------------- 

model_h12_nb_total <- fenegbin(
  TrainingCamps ~ OppositionSizeNorm * DynamicLeader +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h12_nb_active <- fenegbin(
  ActiveTrainingCamps ~ OppositionSizeNorm * DynamicLeader +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h12_nb_defacto <- fenegbin(
  DeFactoTrainingCamps ~ OppositionSizeNorm * DynamicLeader +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h12_qp_total <- feglm(
  TrainingCamps ~ OppositionSizeNorm * DynamicLeader +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  family = quasipoisson(link = "log"),
  cluster = ~dyad,
  data = df_model
)

# ---------------------------------------------------------------------------- 
# NEW ADDITIONAL MODELS: Regime Type (libdem) Interaction
# ---------------------------------------------------------------------------- 

model_h12_nb_total_libdem <- fenegbin(
  TrainingCamps ~ OppositionSizeNorm * Regimelibdem +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h12_nb_active_libdem <- fenegbin(
  ActiveTrainingCamps ~ OppositionSizeNorm * Regimelibdem +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h12_nb_defacto_libdem <- fenegbin(
  DeFactoTrainingCamps ~ OppositionSizeNorm * Regimelibdem +
    PoliticalBandwidth + LogCapitalDistance +
    SenderCINCLog + TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

# ---------------------------------------------------------------------------- 
# NEW ADDITIONAL MODELS: SenderCINCLog interacted with Active and De Facto
# ---------------------------------------------------------------------------- 

model_h12_nb_active_cinc <- fenegbin(
  ActiveTrainingCamps ~ OppositionSizeNorm * SenderCINCLog +
     DynamicLeader +   # Key new interaction
    PoliticalBandwidth + LogCapitalDistance +
    TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)

model_h12_nb_defacto_cinc <- fenegbin(
  DeFactoTrainingCamps ~ OppositionSizeNorm * SenderCINCLog +
     DynamicLeader +   # Key new interaction
    PoliticalBandwidth + LogCapitalDistance +
    TargetCINCLog + cold_war + war_on_terror,
  cluster = ~dyad,
  data = df_model
)


# ---------------------------------------------------------------------------- 
# PRINT SUMMARIES FOR ALL 9 MODELS AT ONCE (clean & readable)
# ---------------------------------------------------------------------------- 

models_list <- list(
  "NB Total (Original)"          = model_h12_nb_total,
  "NB Active (Original)"         = model_h12_nb_active,
  "NB DeFacto (Original)"        = model_h12_nb_defacto,
  "QP Total (Robustness)"        = model_h12_qp_total,
  "NB Active + CINC Interact"    = model_h12_nb_active_cinc,
  "NB DeFacto + CINC Interact"   = model_h12_nb_defacto_cinc,
  "NB Total + LibDem Interact"   = model_h12_nb_total_libdem,      # if you have this one
  "NB Active + LibDem Interact"  = model_h12_nb_active_libdem,
  "NB DeFacto + LibDem Interact" = model_h12_nb_defacto_libdem
)

cat("\n=== H12 MODEL SUMMARIES ===\n\n")

for (name in names(models_list)) {
  cat("──────────────────────────────────────────────\n")
  cat("MODEL:", name, "\n")
  cat("──────────────────────────────────────────────\n")
  print(summary(models_list[[name]]))
  cat("\n\n")
}

# Optional: Save all summaries to a single text file for easy reference
sink(here("results/tables/paper2_h12_all_model_summaries.txt"))
cat("H12 ALL MODEL SUMMARIES\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
for (name in names(models_list)) {
  cat("──────────────────────────────────────────────\n")
  cat("MODEL:", name, "\n")
  cat("──────────────────────────────────────────────\n")
  print(summary(models_list[[name]]))
  cat("\n\n")
}
sink()

message("All 9 model summaries printed and saved to paper2_h12_all_model_summaries.txt")
# ---------------------------------------------------------------------------- 
# Save stripped models (Rule 6)
# ---------------------------------------------------------------------------- 
source(here("R/shared/utils_model.R"))

# Original models
saveRDS(strip_model(model_h12_nb_total), here("results/models/h12_nb_total_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h12_nb_active), here("results/models/h12_nb_active_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h12_nb_defacto), here("results/models/h12_nb_defacto_stripped.rds"), compress = "xz")

# New libdem interaction models
saveRDS(strip_model(model_h12_nb_total_libdem), here("results/models/h12_nb_total_libdem_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h12_nb_active_libdem), here("results/models/h12_nb_active_libdem_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h12_nb_defacto_libdem), here("results/models/h12_nb_defacto_libdem_stripped.rds"), compress = "xz")

# New CINC interaction models
saveRDS(strip_model(model_h12_nb_active_cinc), here("results/models/h12_nb_active_cinc_stripped.rds"), compress = "xz")
saveRDS(strip_model(model_h12_nb_defacto_cinc), here("results/models/h12_nb_defacto_cinc_stripped.rds"), compress = "xz")

# ---------------------------------------------------------------------------- 
# Export tables 
# ---------------------------------------------------------------------------- 
etable(model_h12_nb_total, model_h12_nb_active, model_h12_nb_defacto,
       file = here("results/tables/paper2_h12_nb_original.tex"), replace = TRUE)

etable(model_h12_nb_active_cinc, model_h12_nb_defacto_cinc,
       file = here("results/tables/paper2_h12_nb_cinc_interact.tex"), replace = TRUE)

etable(model_h12_nb_total_libdem, model_h12_nb_active_libdem, model_h12_nb_defacto_libdem,
       file = here("results/tables/paper2_h12_nb_libdem.tex"), replace = TRUE)

etable(model_h12_qp_total, file = here("results/tables/paper2_h12_qp.tex"), replace = TRUE)


# CSV version
coef_table <- etable(model_h12_nb_total, model_h12_nb_active, model_h12_nb_defacto, tex = FALSE)
write_csv(coef_table, here("results/tables/paper2_h12_coefficients.csv"))


# ---------------------------------------------------------------------------- 
# PREDICTED COUNTS AND ORDERED MARGINAL PLOTS (FIXED ORDER)
# ---------------------------------------------------------------------------- 

# Create newdata with OppositionSizeNorm varying
opp_levels <- quantile(df_model$OppositionSizeNorm, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)

newdata <- expand.grid(
  OppositionSizeNorm = opp_levels,
  DynamicLeader      = mean(df_model$DynamicLeader, na.rm = TRUE),
  LiberalDemocracy   = mean(df_model$LiberalDemocracy, na.rm = TRUE),
  PoliticalBandwidth = mean(df_model$PoliticalBandwidth, na.rm = TRUE),
  LogCapitalDistance = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  SenderCINCLog      = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog      = mean(df_model$TargetCINCLog, na.rm = TRUE),
  cold_war           = 0,
  war_on_terror      = 0
)

# Predict
pred_active       <- predict(model_h12_nb_active,       newdata = newdata, type = "response")
pred_defacto      <- predict(model_h12_nb_defacto,      newdata = newdata, type = "response")
pred_active_cinc  <- predict(model_h12_nb_active_cinc,  newdata = newdata, type = "response")
pred_defacto_cinc <- predict(model_h12_nb_defacto_cinc, newdata = newdata, type = "response")

# Create table with EXPLICIT factor order
pred_table <- data.frame(
  OppositionSizeLevel = factor(c("Low (25th)", "Median", "High (75th)"),
                               levels = c("Low (25th)", "Median", "High (75th)")),
  Active              = round(pred_active, 4),
  DeFacto             = round(pred_defacto, 4),
  Active_CINC         = round(pred_active_cinc, 4),
  DeFacto_CINC        = round(pred_defacto_cinc, 4)
)

print("Predicted counts (correct order):")
print(pred_table)

# ---------------------------------------------------------------------------- 
# PLOTS WITH CORRECT LEFT-TO-RIGHT ORDER (Low → Median → High)
# ---------------------------------------------------------------------------- 

# Active (State-selected)
ggplot(pred_table, aes(x = OppositionSizeLevel, y = Active)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  labs(title = "H12: Domestic Opposition and Active (State-selected) Training Camps",
       x = "Opposition Size Level", y = "Predicted Active Training Camps") +
  theme_minimal(base_size = 14)
ggsave(here("results/plots/paper2_h12_marginal_active.png"), width = 10, height = 7, dpi = 300)

# De Facto (NAG-selected)
ggplot(pred_table, aes(x = OppositionSizeLevel, y = DeFacto)) +
  geom_point(size = 4, color = "darkred") +
  geom_line(aes(group = 1), linewidth = 1, color = "darkred") +
  labs(title = "H12: Domestic Opposition and De Facto (NAG-selected) Training Camps",
       x = "Opposition Size Level", y = "Predicted De Facto Training Camps") +
  theme_minimal(base_size = 14)
ggsave(here("results/plots/paper2_h12_marginal_defacto.png"), width = 10, height = 7, dpi = 300)

# Active with CINC interaction
ggplot(pred_table, aes(x = OppositionSizeLevel, y = Active_CINC)) +
  geom_point(size = 4, color = "steelblue") +
  geom_line(aes(group = 1), linewidth = 1, color = "steelblue") +
  labs(title = "H12: Domestic Opposition and Active Training Camps (with CINC interaction)",
       x = "Opposition Size Level", y = "Predicted Active Training Camps") +
  theme_minimal(base_size = 14)
ggsave(here("results/plots/paper2_h12_marginal_active_cinc.png"), width = 10, height = 7, dpi = 300)

# De Facto with CINC interaction
ggplot(pred_table, aes(x = OppositionSizeLevel, y = DeFacto_CINC)) +
  geom_point(size = 4, color = "darkred") +
  geom_line(aes(group = 1), linewidth = 1, color = "darkred") +
  labs(title = "H12: Domestic Opposition and De Facto Training Camps (with CINC interaction)",
       x = "Opposition Size Level", y = "Predicted De Facto Training Camps") +
  theme_minimal(base_size = 14)
ggsave(here("results/plots/paper2_h12_marginal_defacto_cinc.png"), width = 10, height = 7, dpi = 300)

message("All marginal effects plots saved with correct Low → Median → High order.")

# ---------------------------------------------------------------------------- 
# Aggressive cleanup 
# ---------------------------------------------------------------------------- 
# rm(list = setdiff(ls(), c("df_final", "model_h12_nb_total", "model_h12_nb_active", 
#                           "model_h12_nb_defacto", "model_h12_qp_total",
#                           "model_h12_nb_total_libdem", "model_h12_nb_active_libdem", 
#                           "model_h12_nb_defacto_libdem")))
# gc()
message("[05] Environment cleaned. Ready for next model.")