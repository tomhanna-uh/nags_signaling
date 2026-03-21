# Hypothesis Roadmap for nags_signaling Project
**Last updated:** March 14, 2026  
**Source:** README.md (exact H1–H16 from repo) + df_final (after 04_trim_and_finalize.R)  
**Purpose:** One-model-at-a-time scripts (Rule 10). Friendly English labels, here::i_am(), no RDS models, tables in CSV/LaTeX, plots in results/plots.

## Paper 2 – Ideological Commitment Signaling (Autocracy Promotion)
**Core idea:** Revisionist autocrats use NAG support as a costly signal to domestic ideological coalitions.

| Hypothesis | DV (friendly label) | Core IV / Interaction | Model Type | Mathematical Representation | Suggested Controls | Packages / Functions | Simple Formula Example | Robustness Checks | Notes |
|------------|---------------------|-----------------------|------------|-----------------------------|--------------------|----------------------|------------------------|-------------------|-------|
| **H1** | Any NAG Support (binary) or NAG Support Count | sidea_revisionist_domestic | Logistic or Poisson | logit(Pr(NAG)) = β₀ + β₁·Revisionist + controls | politicalbandwidth, securitybandwidth, economicbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log, cold_war, war_on_terror, capital_dist_km | fixest (feglm), glm, sandwich+lmtest | `feglm(nags_any_support ~ revisionist_high + politicalbandwidth + ln_capital_dist_km, family=binomial, cluster=~dyad)` | Clustered SE by dyad/year, count DV (nags_support_count), winsorized vars, post-1990 subsample, continuous revisionist | Baseline ideological effect. |
| **H2** | NAG Support Count | sidea_revisionist_domestic | Poisson/NegBin | log(Count) = β₀ + β₁·Revisionist + β₂·IdeologyMatch + β₃·(Revisionist × IdeologyMatch) + controls | Same as H1 | fixest, pscl (zeroinfl) | `fepoisson(nags_support_count ~ revisionist_high * nags_ideology_match_cont + ...)` | Zero-inflated, region FE, subsample nags>0 | Rational alignment test. |
| **H3** | NAG Support Count | sidea_dynamic_leader × revisionist_high | Poisson | log(Count) = β₀ + β₁·DynamicLeader + β₂·Revisionist + β₃·(Dynamic × Revisionist) + controls | Same as H1 | fixest | `fepoisson(nags_support_count ~ sidea_dynamic_leader * revisionist_high + ...)` | Alternative leader measures, interaction plots | Messianic amplification. |
| **H4** | NAG Ideology Match (binary) | sidea_revisionist_domestic | Logistic | logit(Pr(Match)) = β₀ + β₁·Revisionist + controls | Same + nags_targets_democracy | fixest | `feglm(nags_ideology_match ~ revisionist_high + ...)` | Subsample support>0 | Alignment baseline. |
| **H5** | NAG Support to Autocracy Target (binary) | sidea_revisionist_domestic | Logistic | logit(Pr(AutocracyTarget)) = β₀ + β₁·Revisionist + controls | Same | fixest | `feglm(nags_targets_democracy ~ revisionist_high + ...)` | — | Autocracy promotion. |
| **H6** | NAG Support to Democracy Target (binary) | sidea_revisionist_domestic | Logistic | logit(Pr(DemTarget)) = β₀ + β₁·Revisionist + controls | Same | fixest | `feglm(nags_targets_democracy ~ revisionist_high + ...)` | — | Democracy targeting. |
| **H7** | NAG Support Count | ideol_legit_ratio | Poisson | log(Count) = β₀ + β₁·IdeolRatio + controls | Same | fixest | `fepoisson(nags_support_count ~ ideol_legit_ratio + ...)` | Alternative legit ratios | Legitimation trade-off. |
| **H8** | NAG Support Count | sidea_dynamic_leader × revisionist_high | Poisson | Same as H3 | Same | fixest | Same as H3 | — | Dynamic leadership. |
| **H9** | NAG Support Count (mediated) | sidea_revisionist_domestic → sidea_religious_support / sidea_party_elite_support → NAG | Mediation (3-step) | First-stage: support_group = γ·Revisionist; Second: NAG = δ·support_group | Same | mediation or manual fixest+lm | Two separate fixest models | Bootstrap, Sobel | Mechanism test. |
| **H10** | Leader Survival (duration) | nags_any_support (aligned) | Cox or Logit (survival) | Survival = β·AlignedNAG + controls | Same + sidea_revisionist_domestic | survival, fixest | `coxph(Surv(tenure) ~ nags_any_support + ...)` | — | Survival benefit. |

## Paper 3 – Signaling Resolve to Domestic Opposition
**Core idea:** Visible NAG support signals resolve to opponents while managing external risks.

| Hypothesis | DV (friendly label) | Core IV / Interaction | Model Type | Mathematical Representation | Suggested Controls | Packages / Functions | Simple Formula Example | Robustness Checks | Notes |
|------------|---------------------|-----------------------|------------|-----------------------------|--------------------|----------------------|------------------------|-------------------|-------|
| **H11** | Any NAG Support (binary) | oppsize_norm | Logistic | logit(Pr(NAG)) = β₀ + β₁·OppSize + controls | Same as Paper 2 | fixest | `feglm(nags_any_support ~ oppsize_norm + ...)` | Zero-inflated Poisson | Baseline opposition effect. |
| **H12** | Hosting Training Camps (binary) | oppsize_norm | Logistic | logit(Pr(Camp)) = β₀ + β₁·OppSize + controls | Same | fixest | `feglm(nags_training > 0 ~ oppsize_norm + ...)` | — | Visible costly form. |
| **H13** | NAG Support to Non-Democracy Target (binary) | oppsize_norm × nags_targets_democracy | Logistic (interaction) | logit(Pr(NonDemTarget)) = β₀ + β₁·OppSize + β₂·DemTarget + β₃·(OppSize × DemTarget) + controls | Same | fixest | `feglm(nags_any_support ~ oppsize_norm * nags_targets_democracy + ...)` | Subsample large opp | Strategic avoidance core. |
| **H14** | NAG Support to Non-Democracy Target | oppsize_norm × bandwidth × nags_targets_democracy | Logistic (triple) | logit = β₀ + β₁·OppSize + β₂·Bandwidth + β₃·DemTarget + interactions | Same + politicalbandwidth | fixest | `feglm(nags_any_support ~ oppsize_norm * politicalbandwidth * nags_targets_democracy + ...)` | Region-year FE | Visibility amplifier. |
| **H15** | Leader Survival (duration) | nags_any_support (non-dem target) | Cox / Logit | Survival = β·NonDemNAG + controls | Same | survival | `coxph(Surv(tenure) ~ nags_any_support * (1-nags_targets_democracy) + ...)` | — | Survival via dual signaling. |
| **H16** | NAG Support Count | sidea_dynamic_leader × oppsize_norm | Poisson | log(Count) = β₀ + β₁·Dynamic + β₂·OppSize + β₃·(Dynamic × OppSize) + controls | Same | fixest | `fepoisson(nags_support_count ~ sidea_dynamic_leader * oppsize_norm + ...)` | No avoidance of dem targets | Messianic test. |

## Identification & General Notes (from README)
- **Endogeneity** (opposition ↔ NAG): Use multi-stage probit / control-function (Wooldridge-style) or IV. Add as robustness in every H11–H16 script.
- **Every model script** starts with:
  ```r
  here::i_am("R/models/05_model_hX_....R")
  source(here("R/shared/04_trim_and_finalize.R"))
