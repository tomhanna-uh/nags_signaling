# =============================================================================
# 06_model_opposition_signaling_robustness.R
# Robustness version addressing separation + standard errors
# (Control-function + bias-reduced logit + robust SEs)
# Does NOT overwrite main 05_ script (Rule 12)
# =============================================================================

here::i_am("R/models/06_model_opposition_signaling_robustness.R")

# Reuse trimmed data
source(here("R/shared/04_trim_and_finalize.R"))

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
    `Cold War Period` = cold_war,
    `War on Terror Period` = war_on_terror
  ) %>%
  filter(!is.na(`Domestic Opposition Size`),
         !is.na(`Hosts Any Training Camps`),
         !is.na(`Leader Tenure (years)`))

rm(df_final)
gc()

# First stage: OLS (same as fixed main model)
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

df_model <- df_model %>%
  mutate(opposition_residuals = residuals(first_stage))

rm(first_stage)
gc()

# Second stage: Bias-reduced logistic (brglm2 handles separation)
library(brglm2)

model_robust <- glm(
  `Hosts Any Training Camps` ~ 
    `Domestic Opposition Size` +
    opposition_residuals +
    `Logged Military Capabilities (A)` +
    `Leader Tenure (years)` +
    `Liberal Democracy Score (A)` +
    `Revisionism Distance (Dyadic)` +
    `Target is Democracy (B)` +
    `Bandwidth Visibility` +
    `Cold War Period` + `War on Terror Period`,
  data = df_model,
  family = binomial(link = "logit"),
  method = "brglmFit"          # Firth's bias-reduced
)

# Robust (sandwich) standard errors for control-function model
library(sandwich)
library(lmtest)

robust_se <- coeftest(model_robust, vcov = vcovHC(model_robust, type = "HC1"))

# Save results
library(broom)
library(modelsummary)

# Use robust SEs in tables
results_table <- tidy(model_robust, conf.int = TRUE) %>%
  mutate(`Model` = "Opposition Signaling Robustness (Bias-Reduced + Robust SE)",
         `Outcome` = "Hosts Any Training Camps for Foreign NAGs")

write_csv(results_table, here("results/tables/06_opposition_signaling_robustness_coefficients.csv"))

modelsummary(
  list("Bias-Reduced Logit (Robust SE)" = model_robust),
  output = here("results/tables/06_opposition_signaling_robustness.tex"),
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
  vcov = list("Robust (HC1)" = vcovHC(model_robust, type = "HC1")),
  gof_map = c("nobs", "aic", "bic", "logLik"),
  title = "Domestic Opposition Size and Hosting of Training Camps (Bias-Reduced Logit with Robust SE)"
)

# Minimal stripped (for later plots if needed)
minimal_robust <- list(coefficients = coef(model_robust), 
                       vcov = vcovHC(model_robust, type = "HC1"),
                       formula = formula(model_robust),
                       family = family(model_robust))
saveRDS(minimal_robust, here("results/models/06_opposition_signaling_robustness_stripped.rds"), compress = "xz")

rm(df_model, model_robust, minimal_robust, results_table)
gc()

message("06_model_opposition_signaling_robustness.R completed. Used brglmFit for separation + HC1 robust SEs.")