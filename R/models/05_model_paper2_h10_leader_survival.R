# =============================================================================
# 05_model_paper2_h10_leader_survival.R
# H10: Does Any vs. Aligned NAG Support Improve Leader Survival?
# Piecewise Cox with period × NAG interactions + glm.nb on tenure + survival plots
# =============================================================================

here::i_am("R/models/05_model_paper2_h10_leader_survival.R")

# ── 1. Force clean load
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ── 2. Modeling sample with period interactions
df_model <- df_final %>%
  filter(autocracy_a == 1) %>%
  drop_na(leader_exit_event, time_at_risk, tenure,
          nags_any_support, nags_ideology_match, nags_ideology_match_cont,
          cinc_a_log, cinc_b_log, ln_capital_dist_km, politicalbandwidth_norm) %>%
  mutate(
    AnyNAGSupport         = nags_any_support,
    AlignedNAGSupport     = nags_ideology_match,
    AlignedNAGSupportCont = nags_ideology_match_cont,
    SenderCINCLog         = cinc_a_log,
    TargetCINCLog         = cinc_b_log,
    LogCapitalDistance    = ln_capital_dist_km,
    PoliticalBandwidthNorm = politicalbandwidth_norm,
    LeaderTenure          = tenure,
    
    # Time periods (your preferred cutpoints)
    Period = case_when(
      time_at_risk <= 2 ~ "Early_Survival",      # Years 1-2
      time_at_risk <= 9 ~ "Consolidation",       # Years 3-9
      TRUE              ~ "Long_term"            # Year 10+
    ),
    Period = factor(Period, levels = c("Early_Survival", "Consolidation", "Long_term")),
    
    # Explicit interactions
    Any_Early       = AnyNAGSupport * (Period == "Early_Survival"),
    Any_Cons        = AnyNAGSupport * (Period == "Consolidation"),
    Any_Long        = AnyNAGSupport * (Period == "Long_term"),
    
    Aligned_Early   = AlignedNAGSupport * (Period == "Early_Survival"),
    Aligned_Cons    = AlignedNAGSupport * (Period == "Consolidation"),
    Aligned_Long    = AlignedNAGSupport * (Period == "Long_term"),
    
    AlignedCont_Early = AlignedNAGSupportCont * (Period == "Early_Survival"),
    AlignedCont_Cons  = AlignedNAGSupportCont * (Period == "Consolidation"),
    AlignedCont_Long  = AlignedNAGSupportCont * (Period == "Long_term")
  )

message("Survival sample: ", nrow(df_model), " leader-years (",
        round(mean(df_model$leader_exit_event, na.rm = TRUE)*100, 2), "% exits)")

# ── 3. Cleanup
rm(df_final)
gc()

library(survival)

# ── 4. Piecewise Cox models with period interactions
cox_any <- coxph(
  Surv(time = time_at_risk, event = leader_exit_event) ~ 
    Any_Early + Any_Cons + Any_Long +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + PoliticalBandwidthNorm +
    strata(Period),
  data = df_model
)

cox_aligned <- coxph(
  Surv(time = time_at_risk, event = leader_exit_event) ~ 
    Aligned_Early + Aligned_Cons + Aligned_Long +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + PoliticalBandwidthNorm +
    strata(Period),
  data = df_model
)

cox_aligned_cont <- coxph(
  Surv(time = time_at_risk, event = leader_exit_event) ~ 
    AlignedCont_Early + AlignedCont_Cons + AlignedCont_Long +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + PoliticalBandwidthNorm +
    strata(Period),
  data = df_model
)

# Note on PH assumption:
# Old global PH test results (for reference/safekeeping):
# ph_test_any:          GLOBAL p < 2e-16, AnyNAGSupport p=0.0017, SenderCINCLog p<2e-16, PoliticalBandwidthNorm p<2e-16
# ph_test_aligned:      GLOBAL p < 2e-16, AlignedNAGSupport p=4.7e-07, SenderCINCLog p<2e-16, PoliticalBandwidthNorm p<2e-16
# ph_test_aligned_cont: GLOBAL p < 2e-16, AlignedNAGSupportCont p=2.1e-09, SenderCINCLog p<2e-16, PoliticalBandwidthNorm p<2e-16
# The strata(Period) + explicit interactions largely address these violations.

# ── 5. glm.nb on LeaderTenure with same interactions
nb_tenure_any <- glm.nb(
  LeaderTenure ~ Any_Early + Any_Cons + Any_Long +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + 
    PoliticalBandwidthNorm + I(time_at_risk == 1),
  data = df_model
)

nb_tenure_aligned <- glm.nb(
  LeaderTenure ~ Aligned_Early + Aligned_Cons + Aligned_Long +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + 
    PoliticalBandwidthNorm + I(time_at_risk == 1),
  data = df_model
)

nb_tenure_aligned_cont <- glm.nb(
  LeaderTenure ~ AlignedCont_Early + AlignedCont_Cons + AlignedCont_Long +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + 
    PoliticalBandwidthNorm + I(time_at_risk == 1),
  data = df_model
)

# ── 6. Save stripped RDS models (Rule 6)
source(here("R/shared/utils_model.R"))

saveRDS(strip_model(cox_any), here("results/models/h10_cox_any_stripped.rds"), compress = "xz")
saveRDS(strip_model(cox_aligned), here("results/models/h10_cox_aligned_stripped.rds"), compress = "xz")
saveRDS(strip_model(cox_aligned_cont), here("results/models/h10_cox_aligned_cont_stripped.rds"), compress = "xz")

saveRDS(strip_model(nb_tenure_any), here("results/models/h10_nb_tenure_any_stripped.rds"), compress = "xz")
saveRDS(strip_model(nb_tenure_aligned), here("results/models/h10_nb_tenure_aligned_stripped.rds"), compress = "xz")
saveRDS(strip_model(nb_tenure_aligned_cont), here("results/models/h10_nb_tenure_aligned_cont_stripped.rds"), compress = "xz")

# ── 7. Export tables
stargazer::stargazer(
  cox_any, cox_aligned, cox_aligned_cont,
  type = "latex",
  out = here("results/tables/h10_cox_piecewise_interact.tex"),
  title = "H10: NAG Support and Leader Exit Hazard - Piecewise Cox with Period Interactions",
  dep.var.labels = "Hazard of Leader Exit",
  column.labels = c("Any Support", "Aligned (Binary)", "Aligned (Continuous)"),
  covariate.labels = c("Any Early", "Any Cons", "Any Long",
                       "Aligned Early", "Aligned Cons", "Aligned Long",
                       "AlignedCont Early", "AlignedCont Cons", "AlignedCont Long",
                       "Sender CINC (log)", "Target CINC (log)", "Log Distance", "Political Bandwidth"),
  no.space = TRUE,
  digits = 3
)

stargazer::stargazer(
  nb_tenure_any, nb_tenure_aligned, nb_tenure_aligned_cont,
  type = "latex",
  out = here("results/tables/h10_tenure_duration_interact.tex"),
  title = "H10: NAG Support and Leader Tenure Duration (Negative Binomial with Period Interactions)",
  dep.var.labels = "Leader Tenure (years)",
  column.labels = c("Any Support", "Aligned (Binary)", "Aligned (Continuous)"),
  covariate.labels = c("Any Early", "Any Cons", "Any Long",
                       "Aligned Early", "Aligned Cons", "Aligned Long",
                       "AlignedCont Early", "AlignedCont Cons", "AlignedCont Long",
                       "Sender CINC (log)", "Target CINC (log)", "Log Distance", "Political Bandwidth", "First Year"),
  no.space = TRUE,
  digits = 3
)

# =============================================================================
# STANDALONE ADDITIONS FOR H10 (add after all models are fitted)
# Dynamic leader interaction + AIC comparison + diagnostics
# =============================================================================

# ── A. Dynamic Leader Interaction (Messianic Autocrat test)
# Add to the main aligned model
cox_dynamic <- coxph(
  Surv(time = time_at_risk, event = leader_exit_event) ~ 
    Aligned_Early + Aligned_Cons + Aligned_Long +
    sidea_dynamic_leader * AlignedNAGSupport +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + PoliticalBandwidthNorm +
    strata(Period),
  data = df_model
)

# ── B. AIC Comparison Table (piecewise vs simpler models)
# You can add more models here if desired
model_list <- list(
  "Cox Any (Piecewise)" = cox_any,
  "Cox Aligned (Piecewise)" = cox_aligned,
  "Cox Aligned Cont (Piecewise)" = cox_aligned_cont,
  "Cox Dynamic Interaction" = cox_dynamic
)

cat("\n=== AIC Comparison (lower is better) ===\n")
AIC_table <- sapply(model_list, AIC)
print(AIC_table)

# ── C. Diagnostic Summary Printout
cat("\n=== DIAGNOSTIC SUMMARY ===\n")
cat("Number of observations:", nrow(df_model), "\n")
cat("Number of events (exits):", sum(df_model$leader_exit_event, na.rm = TRUE), "\n")
cat("Mean time_at_risk:", round(mean(df_model$time_at_risk, na.rm = TRUE), 2), "\n")
cat("Proportion of exits in Year 1:", 
    round(mean(df_model$leader_exit_event[df_model$time_at_risk == 1], na.rm = TRUE), 4), "\n")
cat("Theta (NB Any):", nb_tenure_any$theta, "\n")
cat("Theta (NB Aligned):", nb_tenure_aligned$theta, "\n")

# Optional: Concordance for Cox models
cat("\nConcordance (Any):", round(cox_any$concordance[1], 3), 
    "(se =", round(cox_any$concordance[2], 3), ")\n")
cat("Concordance (Aligned):", round(cox_aligned$concordance[1], 3), 
    "(se =", round(cox_aligned$concordance[2], 3), ")\n")

message("Dynamic interaction, AIC comparison, and diagnostics added.")

# ── 8. Predicted survival curves (fixed for interaction terms)
# Create newdata with all required interaction variables set to the desired levels

# Base covariates at means
base_data <- data.frame(
  SenderCINCLog         = mean(df_model$SenderCINCLog, na.rm = TRUE),
  TargetCINCLog         = mean(df_model$TargetCINCLog, na.rm = TRUE),
  LogCapitalDistance    = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  PoliticalBandwidthNorm = mean(df_model$PoliticalBandwidthNorm, na.rm = TRUE),
  Period                = "Consolidation"   # reference period
)


# =============================================================================
# ADDITIONAL DIAGNOSTICS & TESTS 
# =============================================================================

# 1. Three-way interaction (Aligned × Period × Dynamic)
cox_threeway <- coxph(
  Surv(time = time_at_risk, event = leader_exit_event) ~ 
    Aligned_Early + Aligned_Cons + Aligned_Long +
    sidea_dynamic_leader * AlignedNAGSupport * Period +
    SenderCINCLog + TargetCINCLog + LogCapitalDistance + PoliticalBandwidthNorm +
    strata(Period),
  data = df_model
)

# 2. Expanded AIC comparison
model_comparison <- list(
  "Cox Any (Piecewise)"          = cox_any,
  "Cox Aligned (Piecewise)"      = cox_aligned,
  "Cox Aligned Cont (Piecewise)" = cox_aligned_cont,
  "Cox Dynamic Interaction"      = cox_dynamic,
  "Cox Three-way Interaction"    = cox_threeway
)

cat("\n=== Expanded AIC Comparison (lower = better) ===\n")
print(sapply(model_comparison, AIC))

# 3. Short diagnostic summary
cat("\n=== Final Diagnostic Summary ===\n")
cat("Best model by AIC:", names(which.min(sapply(model_comparison, AIC))), "\n")
cat("Concordance of best model:", round(cox_dynamic$concordance[1], 3), "\n")
cat("Number of events:", sum(df_model$leader_exit_event), "\n")

message("Additional tests and AIC table added.")
# Create versions for low vs high support (0 vs 1 for binary, or mean ± 1 SD for continuous)
newdata_low_any   <- base_data %>% mutate(Any_Early = 0, Any_Cons = 0, Any_Long = 0)
newdata_high_any  <- base_data %>% mutate(Any_Early = 1, Any_Cons = 1, Any_Long = 1)

newdata_low_aligned   <- base_data %>% mutate(Aligned_Early = 0, Aligned_Cons = 0, Aligned_Long = 0)
newdata_high_aligned  <- base_data %>% mutate(Aligned_Early = 1, Aligned_Cons = 1, Aligned_Long = 1)

newdata_low_cont   <- base_data %>% mutate(AlignedCont_Early = 0, AlignedCont_Cons = 0, AlignedCont_Long = 0)
newdata_high_cont  <- base_data %>% mutate(AlignedCont_Early = 1, AlignedCont_Cons = 1, AlignedCont_Long = 1)

# Generate survival curves
surv_any_low  <- survfit(cox_any, newdata = newdata_low_any)
surv_any_high <- survfit(cox_any, newdata = newdata_high_any)

surv_aligned_low  <- survfit(cox_aligned, newdata = newdata_low_aligned)
surv_aligned_high <- survfit(cox_aligned, newdata = newdata_high_aligned)

surv_aligned_cont_low  <- survfit(cox_aligned_cont, newdata = newdata_low_cont)
surv_aligned_cont_high <- survfit(cox_aligned_cont, newdata = newdata_high_cont)

# Save plots
png(here("results/plots/h10_survival_curve_any.png"), width = 950, height = 650, res = 130)
plot(surv_any_low,  col = "blue", lwd = 2, xlab = "Years in Office", ylab = "Survival Probability",
     main = "Predicted Survival - Any NAG Support")
lines(surv_any_high, col = "red", lwd = 2)
legend("topright", legend = c("Low Any Support", "High Any Support"), col = c("blue", "red"), lwd = 2)
dev.off()

png(here("results/plots/h10_survival_curve_aligned.png"), width = 950, height = 650, res = 130)
plot(surv_aligned_low,  col = "blue", lwd = 2, xlab = "Years in Office", ylab = "Survival Probability",
     main = "Predicted Survival - Aligned NAG Support")
lines(surv_aligned_high, col = "red", lwd = 2)
legend("topright", legend = c("Low Aligned Support", "High Aligned Support"), col = c("blue", "red"), lwd = 2)
dev.off()

png(here("results/plots/h10_survival_curve_aligned_cont.png"), width = 950, height = 650, res = 130)
plot(surv_aligned_cont_low,  col = "blue", lwd = 2, xlab = "Years in Office", ylab = "Survival Probability",
     main = "Predicted Survival - Aligned NAG Support (Continuous)")
lines(surv_aligned_cont_high, col = "red", lwd = 2)
legend("topright", legend = c("Low Alignment", "High Alignment"), col = c("blue", "red"), lwd = 2)
dev.off()

message("Predicted survival curves saved.")
# ── 9. Optional aggressive cleanup at the very end (uncomment if you want a clean environment)
# rm(list = ls()[!ls() %in% c("df_model")])   # keeps only df_model
# gc()
# message("Environment cleaned. Only df_model remains.")

message("H10 models with period interactions and survival plots complete.")