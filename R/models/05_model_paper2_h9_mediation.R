# =============================================================================
# 05_model_paper2_h9_mediation.R
# H9: Mediation – Revisionist Ideology → Support Groups → NAG Support Count
# Primary: Negative Binomial (second stage)
# Robustness: Quasipoisson
# Diagnostics: Poisson + dispersion/zero check + ZINB/Hurdle comparison
# Formal mediation: lavaan SEM with bootstrapped indirect effects
# =============================================================================

here::i_am("R/models/05_model_paper2_h9_mediation.R")

# ── 1. Force clean load of trimmed + finalized data (Rule 15)
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

# ── 2. Modeling sample – autocracies only, complete cases on core vars
df_model <- df_final %>%
  filter(autocracy_a == 1) %>%
  drop_na(nags_support_count, sidea_revisionist_domestic,
          sidea_religious_support, sidea_party_elite_support,
          cinc_a_log, cinc_b_log, ln_capital_dist_km, politicalbandwidth_norm) %>%
  mutate(
    # Friendly names for output and lavaan
    RevisionistIdeology       = sidea_revisionist_domestic,
    ReligiousSupport          = sidea_religious_support,
    PartyEliteSupport         = sidea_party_elite_support,
    SenderCapabilitiesLog     = cinc_a_log,
    TargetCapabilitiesLog     = cinc_b_log,
    LogCapitalDistance        = ln_capital_dist_km,
    PoliticalBandwidthNorm    = politicalbandwidth_norm
  )

message("Modeling sample size: ", nrow(df_model), " dyad-years")

# ── 3. Aggressive cleanup of large objects (Rule 3)
rm(df_final)
gc()

# ── 4. Preliminary diagnostics on DV (nags_support_count) – Rule 16
poisson_diag <- glm(
  nags_support_count ~ 
    RevisionistIdeology + ReligiousSupport + PartyEliteSupport +
    SenderCapabilitiesLog + TargetCapabilitiesLog +
    LogCapitalDistance + PoliticalBandwidthNorm,
  family = poisson(link = "log"),
  data = df_model
)

dispersion <- deviance(poisson_diag) / df.residual(poisson_diag)
prop_zeros <- mean(df_model$nags_support_count == 0)
expected_zeros <- exp(-mean(fitted(poisson_diag)))

cat("Poisson diagnostic for nags_support_count:\n")
cat("  Dispersion (deviance / df): ", round(dispersion, 2), "\n")
cat("  Proportion of zeros: ", round(prop_zeros * 100, 1), "%\n")
cat("  Expected zeros under Poisson: ", round(expected_zeros * 100, 1), "%\n\n")

# Justification: High zeros + low dispersion → NB primary expected

# ── 5. First-stage models: Revisionist Ideology → Mediators (OLS)
first_religious <- lm(
  ReligiousSupport ~ 
    RevisionistIdeology +
    SenderCapabilitiesLog + TargetCapabilitiesLog +
    LogCapitalDistance + PoliticalBandwidthNorm,
  data = df_model
)

first_party <- lm(
  PartyEliteSupport ~ 
    RevisionistIdeology +
    SenderCapabilitiesLog + TargetCapabilitiesLog +
    LogCapitalDistance + PoliticalBandwidthNorm,
  data = df_model
)

summary(first_religious)
summary(first_party)

# ── 6. Primary second-stage models: NB – Mediator → NAG Support Count
nb_h9_religious <- glm.nb(
  nags_support_count ~ 
    ReligiousSupport +
    SenderCapabilitiesLog + TargetCapabilitiesLog +
    LogCapitalDistance + PoliticalBandwidthNorm,
  data = df_model
)

nb_h9_party <- glm.nb(
  nags_support_count ~ 
    PartyEliteSupport +
    SenderCapabilitiesLog + TargetCapabilitiesLog +
    LogCapitalDistance + PoliticalBandwidthNorm,
  data = df_model
)

# ── 7. Quasipoisson robustness
qp_h9_religious <- glm(
  nags_support_count ~ 
    ReligiousSupport +
    SenderCapabilitiesLog + TargetCapabilitiesLog +
    LogCapitalDistance + PoliticalBandwidthNorm,
  family = quasipoisson(link = "log"),
  data = df_model
)

qp_h9_party <- glm(
  nags_support_count ~ 
    PartyEliteSupport +
    SenderCapabilitiesLog + TargetCapabilitiesLog +
    LogCapitalDistance + PoliticalBandwidthNorm,
  family = quasipoisson(link = "log"),
  data = df_model
)

# ── 8. Export NB/QP tables (Rule 6)
write.csv(broom::tidy(nb_h9_religious, conf.int = TRUE),
          here("results/tables/h9_nb_religious_coefs.csv"))
write.csv(broom::tidy(nb_h9_party, conf.int = TRUE),
          here("results/tables/h9_nb_party_coefs.csv"))

stargazer::stargazer(
  nb_h9_religious, nb_h9_party,
  type = "latex",
  out = here("results/tables/h9_nb_mediation_comparison.tex"),
  title = "H9: Support Groups and NAG Support Count (Negative Binomial)",
  dep.var.labels = "Count of Foreign NAGs Supported",
  column.labels = c("Religious Support", "Party-Elite Support"),
  covariate.labels = c(
    "Religious Support Group",
    "Party-Elite Support Group",
    "Sender Capabilities (log)",
    "Target Capabilities (log)",
    "Log Distance to Capital (km)",
    "Normalized Political Bandwidth"
  ),
  omit.stat = c("f", "ll", "ser"),
  no.space = TRUE,
  digits = 3
)

# ── 9. Predicted counts at mean mediator levels (NB)
newdata_mean <- data.frame(
  ReligiousSupport = mean(df_model$ReligiousSupport, na.rm = TRUE),
  PartyEliteSupport = mean(df_model$PartyEliteSupport, na.rm = TRUE),
  SenderCapabilitiesLog = mean(df_model$SenderCapabilitiesLog, na.rm = TRUE),
  TargetCapabilitiesLog = mean(df_model$TargetCapabilitiesLog, na.rm = TRUE),
  LogCapitalDistance = mean(df_model$LogCapitalDistance, na.rm = TRUE),
  PoliticalBandwidthNorm = mean(df_model$PoliticalBandwidthNorm, na.rm = TRUE)
)

pred_rel_nb  <- predict(nb_h9_religious, newdata = newdata_mean, type = "response")
pred_party_nb <- predict(nb_h9_party, newdata = newdata_mean, type = "response")

pred_table <- data.frame(
  Mediator = c("Religious Support", "Party-Elite Support"),
  PredictedNAGCount_NB = round(c(pred_rel_nb, pred_party_nb), 4)
)

write_csv(pred_table, here("results/tables/h9_predicted_counts_nb.csv"))

# ── 10. Formal mediation via lavaan (SEM with bootstrapped indirect effects)
library(lavaan)

# Define the mediation model (two parallel paths)
mediation_model <- '
  # Direct paths
  ReligiousSupport ~ a1 * RevisionistIdeology
  PartyEliteSupport ~ a2 * RevisionistIdeology
  
  nags_support_count ~ c1 * RevisionistIdeology + 
                       b1 * ReligiousSupport + 
                       b2 * PartyEliteSupport
  
  # Indirect effects
  indirect_religious := a1 * b1
  indirect_party := a2 * b2
  total_indirect := indirect_religious + indirect_party
  total_effect := c1 + total_indirect
'

library(doParallel)  # or snow
registerDoParallel(cores = 4)  # adjust to your machine (e.g., 4–8 cores)

fit_lavaan <- sem(mediation_model, 
                  data = df_model, 
                  estimator = "ML",
                  missing = "ML",
                  se = "bootstrap", 
                  bootstrap = 5000,
                  parallel = "multicore",
                  ncpus = 8)




# Summary + parameter estimates
summary(fit_lavaan, fit.measures = TRUE, standardized = TRUE)

# Extract indirect effects with 95% CIs
parameterEstimates(fit_lavaan, boot.ci.type = "bca.simple")

# Save lavaan results
write.csv(parameterEstimates(fit_lavaan, boot.ci.type = "bca.simple"),
          here("results/tables/h9_lavaan_mediation_estimates.csv"))

# ── 11. Simple marginal plot (saved directly)
me_plot <- ggplot(pred_table, aes(x = Mediator, y = PredictedNAGCount_NB)) +
  geom_point(size = 5, color = "darkblue") +
  geom_segment(aes(x = 1, xend = 2, y = pred_rel_nb, yend = pred_party_nb), linewidth = 1) +
  labs(title = "H9: Predicted NAG Support Count at Mean Mediator Levels",
       subtitle = "Negative Binomial Models",
       x = "Mediator Type",
       y = "Predicted Count") +
  theme_minimal(base_size = 14)

ggsave(here("results/plots/h9_mediation_predicted_counts.png"), 
       me_plot, width = 9, height = 6, dpi = 300)

message("H9 mediation complete (NB primary + lavaan SEM). Tables/plots saved to results/")

# ── 12. Cleanup
rm(list = setdiff(ls(), c("df_model")))
gc()