# =============================================================================
# R/paper2/08_h7_legitimation_ratios_winsor_norm.R
#   H7: Ideological vs. Personalist Legitimation Dependence
#       (Normalized & Winsorized at ±10 — parallel construction)
#       Rational Autocrat signaling vs. Messianic/charismatic mechanism
# =============================================================================

here::i_am("R/paper2/08_h7_legitimation_ratios_winsor_norm.R")

# ── 1. Force clean load of trimmed + finalized data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ── 2. Define modeling sample — autocracies only, complete cases on required vars
df_model <- df_final %>%
  filter(autocracy_a == 1) %>%
  drop_na(nags_training,                              # primary DV
          v2exl_legitideol_a, v2exl_legitlead_a, 
          v2exl_legitperf_a,                          # denom components
          sidea_revisionist_domestic,
          cinc_a_log, cinc_b_log, ln_capital_dist_km, 
          politicalbandwidth_norm) %>%
  mutate(
    # ── Small epsilon to prevent div-by-zero
    eps = 1e-6,
    
    # ── Raw shares (proportion of total legitimation)
    raw_ideol_share = v2exl_legitideol_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + 
         v2exl_legitperf_a + eps),
    
    raw_personalist_share = v2exl_legitlead_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + 
         v2exl_legitperf_a + eps),
    
    # ── Winsorize at ±10 (exact match to legit_ideol_ratio pipeline)
    ideol_share_wins = pmax(pmin(raw_ideol_share, 10), -10),
    personalist_share_wins = pmax(pmin(raw_personalist_share, 10), -10),
    
    # ── Normalize to mean=0, SD=1 (computed on this autocracy subsample)
    legit_ideol_ratio_norm = scale(ideol_share_wins),
    legit_personalist_ratio_norm = scale(personalist_share_wins),
    
    # Optional: small offset DV for IRR interpretation checks
    nags_training_plus1 = nags_training + 1
  )

message("Modeling sample size: ", nrow(df_model), " dyad-years")

# ── 3. Aggressive cleanup of large objects (Rule 3)
rm(df_final)
gc()

# ── 4. Model 1: Ideological Legitimation Dependence (main Rational Autocrat test)
#    Expect positive coef on legit_ideol_ratio_norm
model_h7_ideol <- glm.nb(
  nags_training ~ 
    legit_ideol_ratio_norm +                # 1-SD increase in ideological dependence
    sidea_revisionist_domestic + 
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

summary(model_h7_ideol)

# ── 5. Model 2: Personalist Legitimation Dependence (competing Messianic test)
#    Expect weaker / non-significant positive coef
model_h7_personalist <- glm.nb(
  nags_training ~ 
    legit_personalist_ratio_norm +          # 1-SD increase in personalist dependence
    sidea_revisionist_domestic + 
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

summary(model_h7_personalist)

# ── 6. Export results (Rule 4: tables only — CSV + LaTeX + text)
# CSV: coefficients, SE, z, p, conf.int
write.csv(
  broom::tidy(model_h7_ideol, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_model1_ideol_ratio_norm_coefs.csv")
)

write.csv(
  broom::tidy(model_h7_personalist, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_model2_personalist_ratio_norm_coefs.csv")
)

# LaTeX table for Quarto/manuscript
stargazer::stargazer(
  model_h7_ideol, model_h7_personalist,
  type = "latex",
  out = here("results/tables/h7_legit_ratios_winsor_norm_comparison.tex"),
  title = "H7: Legitimation Dependence and Support for Foreign NAG Training Camps",
  dep.var.labels = "Count of Foreign NAGs Receiving Military Training Support",
  column.labels = c("Ideological Dependence (Norm)", "Personalist Dependence (Norm)"),
  covariate.labels = c(
    "Ideological Legitimation Share (1-SD, Winsorized)",
    "Personalist Legitimation Share (1-SD, Winsorized)",
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

# Plain text version for quick review
stargazer::stargazer(
  model_h7_ideol, model_h7_personalist,
  type = "text",
  out = here("results/tables/h7_legit_ratios_winsor_norm_comparison.txt")
)

# ── 7. Cleanup
rm(df_model, model_h7_ideol, model_h7_personalist)
gc()

message("H7 models complete (winsorized & normalized ratios). Tables saved to results/tables/")