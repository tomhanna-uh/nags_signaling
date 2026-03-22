# =============================================================================
# R/paper2/09_h8_dynamic_leadership_interaction.R
# H8: Messianic Autocrat Test – Dynamic Leadership × Revisionist Ideology
# Primary: Negative Binomial (interaction) + Logit sub-model for Pr(any support)
# Robustness: Quasipoisson
# Preliminary diagnostic: Poisson + dispersion/zero check
# =============================================================================

here::i_am("R/paper2/09_h8_dynamic_leadership_interaction.R")

# ── 1. Force clean load of trimmed + finalized data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ── 2. Modeling sample – autocracies only, complete cases on core vars
df_model <- df_final %>%
  filter(autocracy_a == 1) %>%
  drop_na(nags_training, 
          sidea_dynamic_leader, sidea_revisionist_domestic,
          cinc_a_log, cinc_b_log, ln_capital_dist_km, 
          politicalbandwidth_norm) %>%
  mutate(
    # Binary sub-DV for logit: probability of any training support
    any_nags_training = as.integer(nags_training > 0),
    # Small offset for IRR interpretation in robustness checks
    nags_training_plus1 = nags_training + 1
  )

message("Modeling sample size: ", nrow(df_model), " dyad-years (", 
        round(mean(df_model$any_nags_training) * 100, 1), "% have any support)")

# ── 3. Aggressive cleanup (Rule 3)
rm(df_final)
gc()

# ── 4. Preliminary diagnostic models (Rule 16)
poisson_diag <- glm(
  nags_training ~ 
    sidea_dynamic_leader * sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  family = poisson(link = "log"),
  data = df_model
)

dispersion <- deviance(poisson_diag) / df.residual(poisson_diag)
prop_zeros <- mean(df_model$nags_training == 0)
expected_zeros_poisson <- exp(-mean(fitted(poisson_diag)))

cat("Poisson diagnostic:\n")
cat("  Dispersion (deviance / df): ", round(dispersion, 2), "\n")
cat("  Proportion of zeros: ", round(prop_zeros * 100, 1), "%\n")
cat("  Expected zeros under Poisson: ", round(expected_zeros_poisson * 100, 1), "%\n\n")

# ── 5. New: Logit sub-model – Probability of Any NAG Training Support
logit_h8 <- glm(
  any_nags_training ~ 
    sidea_dynamic_leader * sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  family = binomial(link = "logit"),
  data = df_model
)

summary(logit_h8)

# ── 6. Primary NB model – Interaction (count among supporters)
nb_h8_interaction <- glm.nb(
  nags_training ~ 
    sidea_dynamic_leader * sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

summary(nb_h8_interaction)

# Additive NB (robustness)
nb_h8_additive <- glm.nb(
  nags_training ~ 
    sidea_dynamic_leader + sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  data = df_model
)

# ── 7. Quasipoisson robustness (interaction)
qp_h8_interaction <- glm(
  nags_training ~ 
    sidea_dynamic_leader * sidea_revisionist_domestic +
    cinc_a_log + cinc_b_log +
    ln_capital_dist_km +
    politicalbandwidth_norm,
  family = quasipoisson(link = "log"),
  data = df_model
)

# ── 8. Export tables (Rule 6)
# CSV for all
write.csv(broom::tidy(logit_h8, conf.int = TRUE, exponentiate = TRUE),
          here("results/tables/h8_logit_any_support_coefs.csv"))

write.csv(broom::tidy(nb_h8_interaction, conf.int = TRUE),
          here("results/tables/h8_nb_interaction_coefs.csv"))

write.csv(broom::tidy(qp_h8_interaction, conf.int = TRUE),
          here("results/tables/h8_qp_interaction_coefs.csv"))

# LaTeX: Logit + NB primary side-by-side
stargazer::stargazer(
  logit_h8, nb_h8_interaction,
  type = "latex",
  out = here("results/tables/h8_logit_nb_comparison.tex"),
  title = "H8: Dynamic Leadership × Revisionism on NAG Training Support",
  dep.var.labels = c("Pr(Any Training Support)", "Count of Training Support"),
  column.labels = c("Logit", "Negative Binomial"),
  covariate.labels = c(
    "Dynamic Leadership (Side A)",
    "Revisionist Domestic Ideology (Side A)",
    "Dynamic × Revisionist",
    "Side A Capabilities (log)",
    "Side B Capabilities (log)",
    "Log Distance to Capital (km)",
    "Normalized Political Bandwidth"
  ),
  omit.stat = c("f", "ll", "ser"),
  no.space = TRUE,
  digits = 3
)

# Plain text summary
sink(here("results/tables/h8_summary_with_logit.txt"))
cat("=== Logit: Pr(Any NAG Training Support) ===\n")
print(summary(logit_h8))
cat("\n=== NB Interaction (Primary Count) ===\n")
print(summary(nb_h8_interaction))
cat("\n=== QP Interaction (Robustness) ===\n")
print(summary(qp_h8_interaction))
sink()

# ── 9. Optional: Stripped-down RDS – for marginal effects
source(here("R/shared/utils_model.R"))  # assumes updated strip_model()
stripped_nb_h8 <- strip_model(nb_h8_interaction)
saveRDS(stripped_nb_h8, 
        here("results/models/h8_nb_interaction_stripped.rds"), 
        compress = "xz")

# ── 10. Cleanup
rm(df_model, poisson_diag, logit_h8, nb_h8_interaction, nb_h8_additive, qp_h8_interaction, stripped_nb_h8)
gc()

message("H8 models complete (with logit sub-model for Pr(any support)). Tables saved to results/tables/")