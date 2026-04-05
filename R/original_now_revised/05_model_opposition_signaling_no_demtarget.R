# =============================================================================
# 05_model_opposition_signaling_no_demtarget.R
# Signaling Resolve to Domestic Opposition (No Democracy Target Variable)
# Comparison version – removes `Target is Democracy (B)`
# =============================================================================

here::i_am("R/models/05_model_opposition_signaling_no_demtarget.R")

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
    `Bandwidth Visibility` = bandwidth_visibility
    # Target is Democracy (B) deliberately removed for comparison
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
    `Bandwidth Visibility`,
  data = df_model
)

df_model <- df_model %>%
  mutate(opposition_residuals = residuals(first_stage))

rm(first_stage)
gc()

# =============================================================================
# 3. Second stage: Bias-reduced logistic
# =============================================================================
library(brglm2)
library(sandwich)
library(lmtest)

model_no_demtarget <- glm(
  `Hosts Any Training Camps` ~ 
    `Domestic Opposition Size` +
    opposition_residuals +
    `Logged Military Capabilities (A)` +
    `Leader Tenure (years)` +
    `Liberal Democracy Score (A)` +
    `Revisionism Distance (Dyadic)` +
    `Bandwidth Visibility`,
  data = df_model,
  family = binomial(link = "logit"),
  method = "brglmFit"
)

robust_se <- vcovHC(model_no_demtarget, type = "HC1")

# =============================================================================
# 4. Extract & save results
# =============================================================================
library(broom)
library(modelsummary)

results_table <- tidy(model_no_demtarget, conf.int = TRUE, vcov = robust_se) %>%
  mutate(
    `Model` = "Opposition Signaling (No Democracy Target)",
    `Outcome` = "Hosts Any Training Camps for Foreign NAGs"
  )

write_csv(results_table, here("results/tables/05_opposition_signaling_no_demtarget_coefficients.csv"))

modelsummary(
  list("Bias-Reduced Logit (Robust SE) – No Democracy Target" = model_no_demtarget),
  output = here("results/tables/05_opposition_signaling_no_demtarget.tex"),
  stars = TRUE,
  coef_map = c(
    "`Domestic Opposition Size`" = "Domestic Opposition Size",
    "opposition_residuals" = "Opposition Residuals (Control Function)",
    "`Leader Tenure (years)`" = "Leader Tenure (years)",
    "`Logged Military Capabilities (A)`" = "Logged Military Capabilities (A)",
    "`Liberal Democracy Score (A)`" = "Liberal Democracy Score (A)",
    "`Revisionism Distance (Dyadic)`" = "Revisionism Distance (Dyadic)",
    "`Bandwidth Visibility`" = "Bandwidth Visibility"
  ),
  vcov = list("Robust (HC1)" = robust_se),
  gof_map = c("nobs", "aic", "bic", "logLik"),
  title = "Domestic Opposition Size and Hosting of Training Camps (No Democracy Target Variable)"
)

modelsummary(
  list("Bias-Reduced Logit (Robust SE) – No Democracy Target" = model_no_demtarget),
  output = here("results/tables/05_opposition_signaling_no_demtarget.md"),
  stars = TRUE,
  coef_map = c(
    "`Domestic Opposition Size`" = "Domestic Opposition Size",
    "opposition_residuals" = "Opposition Residuals (Control Function)",
    "`Leader Tenure (years)`" = "Leader Tenure (years)",
    "`Logged Military Capabilities (A)`" = "Logged Military Capabilities (A)",
    "`Liberal Democracy Score (A)`" = "Liberal Democracy Score (A)",
    "`Revisionism Distance (Dyadic)`" = "Revisionism Distance (Dyadic)",
    "`Bandwidth Visibility`" = "Bandwidth Visibility"
  ),
  vcov = list("Robust (HC1)" = robust_se)
)

# Minimal stripped model
minimal_model <- list(
  coefficients = coef(model_no_demtarget),
  vcov = robust_se,
  formula = formula(model_no_demtarget),
  family = family(model_no_demtarget)
)

saveRDS(minimal_model, 
        here("results/models/05_opposition_signaling_no_demtarget_stripped.rds"),
        compress = "xz")

rm(df_model, model_no_demtarget, minimal_model, results_table)
gc()

message("05_model_opposition_signaling_no_demtarget.R completed successfully.")