# =============================================================================
# 05_model_opposition_signaling.R
# Signaling Resolve to Domestic Opposition:
# Domestic opposition size → Hosting of training camps for foreign NAGs
# (Control-function + bias-reduced logit + robust SEs)
# War on Terror Period intentionally dropped due to near-perfect prediction
# with democracy targeting (as you identified)
# =============================================================================

here::i_am("R/models/05_model_opposition_signaling.R")

# Force clean load of trimmed + fixed data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# =============================================================================
# 1. Variable preparation – friendly English labels (Rule 9)
# =============================================================================
df_model <- df_final %>%
  mutate(
    `Domestic Opposition Size` = v2regoppgroupssize_a,
    `Hosts Any Training Camps` = ifelse(Num_S_TrainCamp > 0, 1, 0),
    `Leader Tenure (years)` = tenure,
    `Logged Military Capabilities (A)` = cinc_a_log,
    `Liberal Democracy Score (A)` = v2x_libdem_a,
    `Revisionism Distance (Dyadic)` = revisionism_distance,
    `Target is Democracy (B)` = targets_democracy,
    `Bandwidth Visibility` = bandwidth_visibility,
    `Cold War Period` = cold_war
    # War on Terror Period deliberately omitted (near-perfect predictor of 
    # not targeting democracies / outcome separation)
  ) %>%
  filter(!is.na(`Domestic Opposition Size`),
         !is.na(`Hosts Any Training Camps`),
         !is.na(`Leader Tenure (years)`))

rm(df_final)
gc()

# =============================================================================
# 2. First stage: OLS for continuous opposition size
# =============================================================================
first_stage <- lm(
  `Domestic Opposition Size` ~ `Leader Tenure (years)` +
    `Logged Military Capabilities (A)` +
    `Liberal Democracy Score (A)` +
    `Revisionism Distance (Dyadic)` +
    `Target is Democracy (B)` +
    `Bandwidth Visibility` +
    `Cold War Period`,
  data = df_model
)

df_model <- df_model %>%
  mutate(opposition_residuals = residuals(first_stage))

rm(first_stage)
gc()

# =============================================================================
# 3. Second stage: Bias-reduced logistic (handles separation)
# =============================================================================
library(brglm2)
library(sandwich)
library(lmtest)

model_opp_signal <- glm(
  `Hosts Any Training Camps` ~ 
    `Domestic Opposition Size` +
    opposition_residuals +
    `Logged Military Capabilities (A)` +
    `Leader Tenure (years)` +
    `Liberal Democracy Score (A)` +
    `Revisionism Distance (Dyadic)` +
    `Target is Democracy (B)` +
    `Bandwidth Visibility` +
    `Cold War Period`,
  data = df_model,
  family = binomial(link = "logit"),
  method = "brglmFit"
)

# Robust SEs (HC1) – appropriate for control-function / 2SRI setup
robust_se <- vcovHC(model_opp_signal, type = "HC1")

# =============================================================================
# 4. Extract & save results – never save full model (Rule 4)
# =============================================================================
library(broom)
library(modelsummary)

results_table <- tidy(model_opp_signal, conf.int = TRUE, vcov = robust_se) %>%
  mutate(
    `Model` = "Opposition Signaling (Control Function, Bias-Reduced)",
    `Outcome` = "Hosts Any Training Camps for Foreign NAGs"
  )

write_csv(results_table, here("results/tables/05_opposition_signaling_coefficients.csv"))

modelsummary(
  list("Bias-Reduced Logit (Robust SE)" = model_opp_signal),
  output = here("results/tables/05_opposition_signaling.tex"),
  stars = TRUE,
  coef_map = c(
    "`Domestic Opposition Size`" = "Domestic Opposition Size",
    "opposition_residuals" = "Opposition Residuals (Control Function)",
    "`Leader Tenure (years)`" = "Leader Tenure (years)",
    "`Logged Military Capabilities (A)`" = "Logged Military Capabilities (A)",
    "`Liberal Democracy Score (A)`" = "Liberal Democracy Score (A)",
    "`Revisionism Distance (Dyadic)`" = "Revisionism Distance (Dyadic)",
    "`Target is Democracy (B)`" = "Target is Democracy (B)",
    "`Bandwidth Visibility`" = "Bandwidth Visibility",
    "`Cold War Period`" = "Cold War Period"
  ),
  vcov = list("Robust (HC1)" = robust_se),
  gof_map = c("nobs", "aic", "bic", "logLik"),
  title = "Domestic Opposition Size and Hosting of Training Camps for Foreign NAGs (Dyadic)"
)

modelsummary(
  list("Bias-Reduced Logit (Robust SE)" = model_opp_signal),
  output = here("results/tables/05_opposition_signaling.md"),
  stars = TRUE,
  coef_map = c(
    "`Domestic Opposition Size`" = "Domestic Opposition Size",
    "opposition_residuals" = "Opposition Residuals (Control Function)",
    "`Leader Tenure (years)`" = "Leader Tenure (years)",
    "`Logged Military Capabilities (A)`" = "Logged Military Capabilities (A)",
    "`Liberal Democracy Score (A)`" = "Liberal Democracy Score (A)",
    "`Revisionism Distance (Dyadic)`" = "Revisionism Distance (Dyadic)",
    "`Target is Democracy (B)`" = "Target is Democracy (B)",
    "`Bandwidth Visibility`" = "Bandwidth Visibility",
    "`Cold War Period`" = "Cold War Period"
  ),
  vcov = list("Robust (HC1)" = robust_se)
)

# =============================================================================
# 5. Minimal stripped model (for later plots if needed)
# =============================================================================
minimal_model <- list(
  coefficients = coef(model_opp_signal),
  vcov = robust_se,
  formula = formula(model_opp_signal),
  family = family(model_opp_signal)
)

saveRDS(minimal_model, 
        here("results/models/05_opposition_signaling_stripped.rds"),
        compress = "xz")

rm(df_model, model_opp_signal, minimal_model, results_table)
gc()

message("05_model_opposition_signaling.R completed successfully. 
         War on Terror Period omitted due to near-perfect prediction with democracy targeting.")