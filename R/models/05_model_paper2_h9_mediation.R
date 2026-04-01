# =============================================================================
# 05_model_paper2_h9_mediation.R
# H9: Mediation – Revisionist Ideology → Support Groups → NAG Support Count
# Primary: Negative Binomial (second stage)
# Robustness: Quasipoisson
# Diagnostics: Poisson + dispersion/zero check
# Formal mediation: lavaan SEM with bootstrapped indirect effects
# Path diagram: semPlot
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
    RevisionistIdeology    = sidea_revisionist_domestic,
    ReligiousSupport       = sidea_religious_support,
    PartyEliteSupport      = sidea_party_elite_support,
    SenderCapabilitiesLog  = cinc_a_log,
    TargetCapabilitiesLog  = cinc_b_log,
    LogCapitalDistance     = ln_capital_dist_km,
    PoliticalBandwidthNorm = politicalbandwidth_norm
  )

message("Modeling sample size: ", nrow(df_model), " dyad-years")

# ── 3. Aggressive cleanup (Rule 3)
rm(df_final)
gc()

# ── 4. Preliminary diagnostics (Rule 16)
poisson_diag <- glm(
  nags_support_count ~ RevisionistIdeology + ReligiousSupport + PartyEliteSupport +
    SenderCapabilitiesLog + TargetCapabilitiesLog + LogCapitalDistance + PoliticalBandwidthNorm,
  family = poisson(link = "log"),
  data = df_model
)

dispersion <- deviance(poisson_diag) / df.residual(poisson_diag)
prop_zeros <- mean(df_model$nags_support_count == 0)

cat("Poisson diagnostic:\n")
cat("  Dispersion:", round(dispersion, 2), "\n")
cat("  Proportion of zeros:", round(prop_zeros * 100, 1), "%\n\n")

# ── 5. First-stage models (OLS)
first_religious <- lm(ReligiousSupport ~ RevisionistIdeology + SenderCapabilitiesLog +
                        TargetCapabilitiesLog + LogCapitalDistance + PoliticalBandwidthNorm,
                      data = df_model)

first_party <- lm(PartyEliteSupport ~ RevisionistIdeology + SenderCapabilitiesLog +
                    TargetCapabilitiesLog + LogCapitalDistance + PoliticalBandwidthNorm,
                  data = df_model)

# ── 6. Primary second-stage models (NB)
nb_h9_religious <- glm.nb(nags_support_count ~ ReligiousSupport +
                            SenderCapabilitiesLog + TargetCapabilitiesLog +
                            LogCapitalDistance + PoliticalBandwidthNorm,
                          data = df_model)

nb_h9_party <- glm.nb(nags_support_count ~ PartyEliteSupport +
                        SenderCapabilitiesLog + TargetCapabilitiesLog +
                        LogCapitalDistance + PoliticalBandwidthNorm,
                      data = df_model)

# Quasipoisson robustness
qp_h9_religious <- glm(nags_support_count ~ ReligiousSupport +
                         SenderCapabilitiesLog + TargetCapabilitiesLog +
                         LogCapitalDistance + PoliticalBandwidthNorm,
                       family = quasipoisson(link = "log"), data = df_model)

qp_h9_party <- glm(nags_support_count ~ PartyEliteSupport +
                     SenderCapabilitiesLog + TargetCapabilitiesLog +
                     LogCapitalDistance + PoliticalBandwidthNorm,
                   family = quasipoisson(link = "log"), data = df_model)

# ── 7. Export tables
stargazer::stargazer(nb_h9_religious, nb_h9_party,
                     type = "latex",
                     out = here("results/tables/h9_nb_mediation_comparison.tex"),
                     title = "H9: Mediation through Support Groups (Negative Binomial)",
                     dep.var.labels = "Count of Foreign NAGs Supported",
                     column.labels = c("Religious Support", "Party-Elite Support"),
                     covariate.labels = c("Religious Support Group", "Party-Elite Support Group",
                                          "Sender Capabilities (log)", "Target Capabilities (log)",
                                          "Log Distance to Capital (km)", "Normalized Political Bandwidth"),
                     omit.stat = c("f", "ll", "ser"),
                     no.space = TRUE,
                     digits = 3
)

# ── 8. Formal lavaan mediation with bootstrap
library(lavaan)

mediation_model <- '
  ReligiousSupport ~ a1*RevisionistIdeology
  PartyEliteSupport ~ a2*RevisionistIdeology
  
  nags_support_count ~ c1*RevisionistIdeology + b1*ReligiousSupport + b2*PartyEliteSupport
  
  indirect_religious := a1*b1
  indirect_party     := a2*b2
  total_indirect     := indirect_religious + indirect_party
  total_effect       := c1 + total_indirect
'

fit_lavaan <- sem(mediation_model, 
                  data = df_model, 
                  estimator = "ML",
                  se = "bootstrap", 
                  bootstrap = 100,
                  parallel  = "multicore",
                  ncpus     = 14)

summary(fit_lavaan, fit.measures = TRUE, standardized = TRUE)

# Save parameter estimates with CIs
param_table <- parameterEstimates(fit_lavaan, boot.ci.type = "bca.simple", standardized = TRUE)
write_csv(param_table, here("results/tables/h9_lavaan_mediation_estimates.csv"))

# ── 9. Path diagram — alternative reliable version
library(semPlot)

p <- semPaths(fit_lavaan,
              what = "std",
              whatLabels = "est",
              layout = "tree",
              edge.label.cex = 1.1,
              node.label.cex = 1.2,
              intercepts = FALSE,
              residuals = FALSE,
              exoCov = FALSE,
              fade = FALSE,
              color = list(lat = "lightblue", man = "lightgrey"),
              title = FALSE,
              main = "H9 Mediation: Revisionist Ideology → Support Groups → NAG Support",
              sizeMan = 5,
              sizeLat = 6)

# Save the plot
png(here("results/plots/h9_path_diagram.png"), width = 10, height = 7, units = "in", res = 300)
plot(p)
dev.off()


message("Path diagram saved to results/plots/h9_path_diagram.png and .pdf")

message("Path diagram saved to results/plots/h9_path_diagram.png")

# ── 10. Cleanup
rm(list = setdiff(ls(), c("df_model", "fit_lavaan")))
gc()

message("H9 mediation complete with lavaan SEM and path diagram.")