# =============================================================================
# R/paper2/08_h7_legitimation_ratios_qp_nb.R
#   H7: Ideological vs. Personalist Legitimation Dependence
#       Primary: Quasipoisson GLM
#       Robustness: Negative Binomial
#       (Normalized & Winsorized at ±10 — parallel construction)
# =============================================================================

here::i_am("R/paper2/08_h7_legitimation_ratios_qp_nb.R")

# ── 1. Force clean load of trimmed + finalized data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ── 2. Define modeling sample — autocracies only, complete cases on required vars
df_model <- df_final %>%
  filter(autocracy_a == 1) %>%
  drop_na(nags_training,                              # primary DV (count of NAG training support)
          v2exl_legitideol_a, v2exl_legitlead_a, 
          v2exl_legitperf_a,                          # legitimation components
          sidea_revisionist_domestic,
          cinc_a_log, cinc_b_log, ln_capital_dist_km, 
          politicalbandwidth_norm) %>%
  mutate(
    # ── Small epsilon to prevent div-by-zero in ratios
    eps = 1e-6,
    
    # ── Raw legitimation shares (proportion of total)
    raw_ideol_share = v2exl_legitideol_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + 
         v2exl_legitperf_a + eps),
    
    raw_personalist_share = v2exl_legitlead_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + 
         v2exl_legitperf_a + eps),
    
    # ── Winsorize at ±10 (matches legit_ideol_ratio pipeline)
    ideol_share_wins = pmax(pmin(raw_ideol_share, 10), -10),
    personalist_share_wins = pmax(pmin(raw_personalist_share, 10), -10),
    
    # ── Normalize to mean=0, SD=1 (on this autocracy subsample)
    legit_ideol_ratio_norm = as.numeric(scale(ideol_share_wins)),
    legit_personalist_ratio_norm = as.numeric(scale(personalist_share_wins))
  )

message("Modeling sample size: ", nrow(df_model), " dyad-years")

# ── 3. Aggressive cleanup of large objects (Rule 3)
rm(df_final)
gc()

# ── 4. Primary Model 1: Quasipoisson – Ideological Legitimation Dependence
qp_h7_ideol <- glm(
  nags_training ~ 
    legit_ideol_ratio_norm +                # 1-SD increase in ideological share
    sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  family = quasipoisson(link = "log"),
  data = df_model
)

summary(qp_h7_ideol)

# ── 5. Primary Model 2: Quasipoisson – Personalist Legitimation Dependence
qp_h7_personalist <- glm(
  nags_training ~ 
    legit_personalist_ratio_norm +          # 1-SD increase in personalist share
    sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  family = quasipoisson(link = "log"),
  data = df_model
)

summary(qp_h7_personalist)

# ── 6. Robustness: Negative Binomial models (exact same specs)
nb_h7_ideol <- glm.nb(
  nags_training ~ 
    legit_ideol_ratio_norm +
    sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

nb_h7_personalist <- glm.nb(
  nags_training ~ 
    legit_personalist_ratio_norm +
    sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

summary(nb_h7_ideol)
summary(nb_h7_personalist)

# ── 7. Export tables (Rule 4 & 6: CSV + LaTeX + text)
# CSV: tidy coefficients/SE/z/p/conf.int
write.csv(
  broom::tidy(qp_h7_ideol, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_qp_model1_ideol_ratio_norm_coefs.csv")
)

write.csv(
  broom::tidy(qp_h7_personalist, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_qp_model2_personalist_ratio_norm_coefs.csv")
)

write.csv(
  broom::tidy(nb_h7_ideol, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_nb_model1_ideol_ratio_norm_coefs.csv")
)

write.csv(
  broom::tidy(nb_h7_personalist, exponentiate = FALSE, conf.int = TRUE),
  here("results/tables/h7_nb_model2_personalist_ratio_norm_coefs.csv")
)

# LaTeX: primary QP models side-by-side
stargazer::stargazer(
  qp_h7_ideol, qp_h7_personalist,
  type = "latex",
  out = here("results/tables/h7_quasipoisson_legit_ratios_comparison.tex"),
  title = "H7: Legitimation Dependence and Support for Foreign NAG Training Camps (Quasipoisson)",
  dep.var.labels = "Count of Foreign NAGs Receiving Military Training Support",
  column.labels = c("Ideological Dependence", "Personalist Dependence"),
  covariate.labels = c(
    "Ideological Legitimation Share (1-SD, Winsorized)",
    "Personalist Legitimation Share (1-SD, Winsorized)",
    "Revisionist Domestic Ideology",
    "Side A Capabilities (log)",
    "Side B Capabilities (log)",
    "Log Distance to Capital (km)",
    "Normalized Political Bandwidth"
  ),
  omit.stat = c("f", "ll", "ser", "deviance"),
  no.space = TRUE,
  single.row = TRUE,
  digits = 3
)

# Plain text summary of all four models for quick review
sink(here("results/tables/h7_legit_ratios_qp_nb_summary.txt"))
cat("=== Quasipoisson: Ideological ===\n")
print(summary(qp_h7_ideol))
cat("\n=== Quasipoisson: Personalist ===\n")
print(summary(qp_h7_personalist))
cat("\n=== NB Robustness: Ideological ===\n")
print(summary(nb_h7_ideol))
cat("\n=== NB Robustness: Personalist ===\n")
print(summary(nb_h7_personalist))
sink()

# ── 8. Cleanup (Rule 3)
rm(df_model, qp_h7_ideol, qp_h7_personalist, nb_h7_ideol, nb_h7_personalist)
gc()

message("H7 models complete (Quasipoisson primary + NB robustness). Tables saved to results/tables/")