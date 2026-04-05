# =============================================================================
# 05_model_opposition_signaling.R
# Signaling Resolve to Domestic Opposition:
# Domestic opposition size → Hosting of training camps for foreign NAGs
# (Control-function approach, dyadic supporter A / target B structure)
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
    `Domestic Opposition Size` = v2regoppgroupssize_a,          # continuous → first stage OLS
    `Hosts Any Training Camps` = ifelse(Num_S_TrainCamp > 0, 1, 0),  # binary → second stage logit
    
    `Leader Tenure (years)` = tenure,
    `Logged Military Capabilities (A)` = cinc_a_log,
    `Liberal Democracy Score (A)` = v2x_libdem_a,
    `Revisionism Distance (Dyadic)` = revisionism_distance,
    `Target is Democracy (B)` = targets_democracy,
    `Bandwidth Visibility` = bandwidth_visibility,
    `Cold War Period` = cold_war,
    `War on Terror Period` = war_on_terror
  ) %>%
  filter(!is.na(`Domestic Opposition Size`),
         !is.na(`Hosts Any Training Camps`),
         !is.na(`Leader Tenure (years)`))

rm(df_final)
gc()

# =============================================================================
# 2. First stage: OLS for continuous endogenous regressor (opposition size)
#    Instrument: Leader Tenure
# =============================================================================
first_stage <- lm(
  `Domestic Opposition Size` ~ `Leader Tenure (years)` +
    `Logged Military Capabilities (A)` +
    `Liberal Democracy Score (A)` +
    `Revisionism Distance (Dyadic)` +
    `Target is Democracy (B)` +
    `Bandwidth Visibility` +
    `Cold War Period` + `War on Terror Period`,
  data = df_model
)

# Add residuals (control function term)
df_model <- df_model %>%
  mutate(
    opposition_residuals = residuals(first_stage)
  )

rm(first_stage)
gc()

# =============================================================================
# 3. Second stage: Logistic regression with control-function correction
# =============================================================================
model_opp_signal <- glm(
  `Hosts Any Training Camps` ~ 
    `Domestic Opposition Size` +
    opposition_residuals +                          # control function correction
    `Logged Military Capabilities (A)` +
    `Leader Tenure (years)` +
    `Liberal Democracy Score (A)` +
    `Revisionism Distance (Dyadic)` +
    `Target is Democracy (B)` +
    `Bandwidth Visibility` +
    `Cold War Period` + `War on Terror Period`,
  data = df_model,
  family = binomial(link = "logit")
)

# =============================================================================
# 4. Extract & save results – never save full model (Rule 4)
# =============================================================================
library(broom)
library(modelsummary)

results_table <- tidy(model_opp_signal, conf.int = TRUE) %>%
  mutate(
    `Model` = "Opposition Signaling (Control Function, Dyadic Logit)",
    `Outcome` = "Hosts Any Training Camps for Foreign NAGs"
  )

write_csv(results_table, 
          here("results/tables/05_opposition_signaling_coefficients.csv"))

modelsummary(
  list("Control-Function Logit" = model_opp_signal),
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
    "`Bandwidth Visibility`" = "Bandwidth Visibility"
  ),
  gof_map = c("nobs", "aic", "bic", "logLik"),
  title = "Domestic Opposition Size and Hosting of Training Camps for Foreign NAGs (Dyadic)"
)

modelsummary(
  list("Control-Function Logit" = model_opp_signal),
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
    "`Bandwidth Visibility`" = "Bandwidth Visibility"
  )
)

# =============================================================================
# 5. Minimal stripped model (only if needed for later plots)
# =============================================================================
minimal_model <- list(
  coefficients = coef(model_opp_signal),
  vcov = vcov(model_opp_signal),
  formula = formula(model_opp_signal),
  family = family(model_opp_signal)
)

saveRDS(minimal_model, 
        here("results/models/05_opposition_signaling_stripped.rds"),
        compress = "xz")

rm(df_model, model_opp_signal, minimal_model, results_table)
gc()

message("05_model_opposition_signaling.R completed successfully. First stage now uses OLS for continuous opposition size.")
