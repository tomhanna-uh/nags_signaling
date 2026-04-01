# =============================================================================
# R/paper2/08_h7_legitimation_ratios.R
#   H7: Test ideological vs. personalist legitimation dependence
#       (Rational Autocrat signaling vs. Messianic/charismatic mechanism)
# =============================================================================

here::i_am("R/models/05_model_paper2_h7_legitimation_ratios.R")

# ── 1. Force clean load of trimmed + finalized data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ── 2. Define modeling sample — autocracies only, complete cases on core vars
df_model <- df_final %>%
  filter(autocracy_a == 1) %>%
  drop_na(nags_training,                              # primary DV
          v2exl_legitideol_a, v2exl_legitlead_a, 
          v2exl_legitperf_a, v2exl_legitratio_a,      # needed for ratios
          sidea_revisionist_domestic,
          cinc_a_log, cinc_b_log, ln_capital_dist_km, 
          politicalbandwidth_norm) %>%
  mutate(
    # ── Compute legitimation ratios (proportions of total legitimation)
    # Small epsilon prevents division by zero when all legit = 0 (rare)
    eps = 1e-6,
    ideol_legit_ratio = v2exl_legitideol_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + 
         v2exl_legitperf_a + v2exl_legitratio_a + eps),
    
    personalist_legit_ratio = v2exl_legitlead_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + 
         v2exl_legitperf_a + v2exl_legitratio_a + eps),
    
    # Optional: for easier IRR interpretation later
    nags_training_plus1 = nags_training + 1
  )

message("Modeling sample size: ", nrow(df_model), " dyad-years")

# ── 3. Clean up large objects immediately
rm(df_final)
gc()

# ── 4. Model 1: Ideological Legitimation Dependence (main hypothesis)
model_h7_ideol <- glm.nb(
  nags_training ~ 
    ideol_legit_ratio +                     # core: higher ideological share → more NAG support
    sidea_revisionist_domestic +            # controls for overall revisionism level
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

# Model 1a: Ideological Legitimation Dependence without sidea_revisionist_domestic

summary(model_h7_ideol)

# ── 5. Model 2: Personalist Legitimation Dependence (Messianic competing hypothesis)
model_h7_personalist <- glm.nb(
  nags_training ~ 
    personalist_legit_ratio +               # core: higher personalist share → more NAG support?
    sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

summary(model_h7_personalist)

# ── 6. Export results (Rule 4: no RDS, use CSV + LaTeX + text)
# CSV — coefficients, SE, z, p, conf.int
write.csv(
  broom::tidy(model_h7_ideol, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_model1_ideological_ratio_coefs.csv")
)

write.csv(
  broom::tidy(model_h7_personalist, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_model2_personalist_ratio_coefs.csv")
)

# LaTeX table for manuscript / Quarto
stargazer::stargazer(
  model_h7_ideol, model_h7_personalist,
  type = "latex",
  out = here("results/tables/h7_legitimation_ratios_comparison.tex"),
  title = "H7: Legitimation Dependence and Support for NAG Military Training Camps",
  dep.var.labels = "Count of Foreign NAGs Receiving Training Support",
  column.labels = c("Ideological Dependence", "Personalist Dependence"),
  covariate.labels = c(
    "Ideological Legitimation Share",
    "Personalist Legitimation Share",
    "Revisionist Domestic Ideology",
    "Side A Capabilities (log)",
    "Side B Capabilities (log)",
    "Log Distance to Capital (km)",
    "Normalized Political Bandwidth"
  ),
  omit.stat = c("f", "ll", "ser"),
  no.space = TRUE,
  single.row = TRUE,
  digits = 3
)

# Plain text version for console / quick check
stargazer::stargazer(
  model_h7_ideol, model_h7_personalist,
  type = "text",
  out = here("results/tables/h7_legitimation_ratios_comparison.txt")
)

# ── 7. Cleanup
rm(df_model, model_h7_ideol, model_h7_personalist)
gc()

message("H7 models complete. Tables saved to results/tables/")