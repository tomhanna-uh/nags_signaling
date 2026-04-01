# Hypothesis Roadmap for nags_signaling Project
**Last updated:** March 20, 2026  
**Data:** `df_final` (after `04_trim_and_finalize.R`)  
**Project focus:** Autocratic support for foreign non-state armed groups (NAGs) as signaling mechanisms.

## Paper 1 – Ideology and Autocracy Promotion Through Non-State Armed Groups
**Subtitle:** Autocratic Use of Non-State Armed Groups as Tools of Revisionist Signaling and Autocracy Promotion  
**Core idea:** Revisionist autocrats use NAG support as a costly signal of ideological commitment to domestic support coalitions (rational/messianic framing).

| Hypothesis | DV (friendly label) | Core IV / Interaction | Model Type | Mathematical Representation | Suggested Controls | Packages / Functions | Simple Formula Example | Robustness Checks | Notes |
|------------|---------------------|-----------------------|------------|-----------------------------|--------------------|----------------------|------------------------|-------------------|-------|
| **H1** | Any NAG Support (binary) | sidea_revisionist_domestic | Logistic - Probit as robustness | logit(Pr(NAG)) = β₀ + β₁·Revisionist + controls | politicalbandwidth, securitybandwidth, economicbandwidth, ln_capital_dist_km, cinc_a_log, cinc_b_log, cold_war, war_on_terror | fixest (feglm), glm, sandwich+lmtest | `feglm(nags_any_support ~ sidea_revisionist_domestic + politicalbandwidth + ln_capital_dist_km, family=binomial, cluster=~dyad)` | Clustered SE by dyad/year, count DV (nags_support_count), winsorized vars, post-1990 subsample, continuous revisionist | Baseline ideological effect. |
| **H2** | NAG Support Count | sidea_revisionist_domestic | Poisson/NegBin | log(Count) = β₀ + β₁·Revisionist + controls | Same as H1 | fixest, pscl (zeroinfl) | `fepoisson(nags_support_count ~ sidea_revisionist_domestic + ...)` | Zero-inflated, region FE | Rational signaling to coalitions (higher domestic revisionist legitimation increases NAG support count). |
| **H3** | NAG Support Count | sidea_dynamic_leader * revisionist_high | Poisson | log(Count) = β₀ + β₁·Dynamic + β₂·Revisionist + β₃·(Dynamic × Revisionist) + controls | Same as H1 | fixest | `fepoisson(nags_support_count ~ sidea_dynamic_leader * revisionist_high + ...)` | Alternative leader measures (v2exl_legitlead_a), interaction plots | Messianic amplification. |
| **H4** | NAG Ideology Match (binary) | sidea_revisionist_domestic | Logistic | logit(Pr(Match)) = β₀ + β₁·Revisionist + controls | Same + nags_targets_democracy | fixest | `feglm(nags_ideology_match ~ revisionist_high + ...)` | Subsample support>0, triadic NAGID_2/3/4 for identity (ethno-nationalist, religious, leftist) | Alignment baseline (triadic data for NAGID_2 = ethno-nationalist, NAGID_3 = religious, NAGID_4 = leftist). |
| **H5** | Support to NAGs with Non-Democratic Objectives (binary or count) | sidea_revisionist_domestic * nags_nondem_objective | Logistic or Poisson | logit(Pr(NonDemObj)) = β₀ + β₁·Revisionist + β₂·NonDemObj + β₃·(Revisionist × NonDemObj) + controls | Same as H1 | fixest | `feglm(nags_nondem_objective ~ revisionist_high + ...)` | Subsample support>0, alternative non-dem objective (nags_auth_support, nags_theo_support, nags_dict_support, nags_mil_support) | Autocratic goals alignment (triadic NAGAuth/NAGTheo/NAGDict/NAGMil). |
| **H6** | NAG Support Count (specific to to NAGS with Democracy Target) | sidea_revisionist_domestic * nags_targets_democracy | Logistic | logit(Pr(DemTarget)) = β₀ + β₁·Revisionist + controls | Same as H1 | fixest | `feglm(nags_targets_democracy ~ revisionist_high + ...)` | — | Democracy targeting. |
| **H7** | NAG Support Count | ideol_legit_ratio (original) and personalist_legit_ratio (second model) | Poisson | log(Count) = β₀ + β₁·IdeolRatio + controls (original) <br> log(Count) = β₀ + β₁·Dynamic + β₂·Revisionist + β₃·(Dynamic × Revisionist) + controls (second) | Same as H1 | fixest | `fepoisson(nags_support_count ~ ideol_legit_ratio + ...)` (original) <br> `fepoisson(nags_support_count ~ sidea_dynamic_leader * sidea_revisionist_domestic + ...)` (second) | Alternative legit ratios, interaction plots | Legitimation trade-off. Original model retained. Second model added for dynamic leadership effect (dynamic_legit_ratio created in script). |
| **H8** | NAG Support Count | sidea_dynamic_leader * sidea_revisionist_domestic | Poisson | log(Count) = β₀ + β₁·Dynamic + β₂·Revisionist + β₃·(Dynamic × Revisionist) + controls | Same as H1 | fixest | `fepoisson(nags_support_count ~ sidea_dynamic_leader * sidea_revisionist_domestic + ...)` | Alternative leader measures, interaction plots | Dynamic leadership amplification (continuous revisionist preferred). |
| **H9** | NAG Support Count (mediated) | sidea_revisionist_domestic → sidea_religious_support / sidea_party_elite_support → NAG | Mediation (3-step) | First-stage: support_group = γ·Revisionist; Second: NAG = δ·support_group | Same controls | mediation or manual fixest+lm | Two separate fixest models | Bootstrap, Sobel | Mechanism test. |
| **H10** | Leader Survival (duration) | nags_any_support (aligned) | Cox or Logit (survival) | Survival = β·AlignedNAG + controls | Same + sidea_revisionist_domestic | survival, fixest | `coxph(Surv(tenure) ~ nags_any_support + ...)` | — | Survival benefit. |

## Paper 3 – The Threat of Autocracy Promotion
**Subtitle:** International Attacks on Democracy as Domestic Signaling  
**Core idea:** Autocrats use NAG support to signal resolve to domestic opposition.

| Hypothesis | DV (friendly label) | Core IV / Interaction | Model Type | Mathematical Representation | Suggested Controls | Packages / Functions | Simple Formula Example | Robustness Checks | Notes |
|------------|---------------------|-----------------------|------------|-----------------------------|--------------------|----------------------|------------------------|-------------------|-------|
| **H11** | Any NAG Support (binary) | oppsize_norm | Logistic | logit(Pr(NAG)) = β₀ + β₁·OppSize + controls | Same as Paper 2 | fixest (feglm) | `feglm(nags_any_support ~ oppsize_norm + ...)` | Zero-inflated Poisson | Baseline opposition effect. |
| **H12** | Hosting Training Camps (binary) | oppsize_norm | Logistic | logit(Pr(Camp)) = β₀ + β₁·OppSize + controls | Same | fixest | `feglm(nags_training > 0 ~ oppsize_norm + ...)` | — | Visible costly form. |
| **H13** | Any NAG Support | oppsize_norm * (1-nags_targets_democracy) | Logistic | logit(Pr(NonDemTarget)) = β₀ + β₁·OppSize + β₂·NonDemTarget + β₃·(OppSize × NonDemTarget) + controls | Same | fixest | `feglm(nags_any_support ~ oppsize_norm * (1-nags_targets_democracy) + ...)` | Subsample large opp | Strategic avoidance core. |
| **H14** | Any NAG Support | oppsize_norm * politicalbandwidth * (1-nags_targets_democracy) | Logistic (triple) | logit = β₀ + β₁·OppSize + β₂·Bandwidth + β₃·NonDemTarget + interactions | Same + politicalbandwidth | fixest | `feglm(nags_any_support ~ oppsize_norm * politicalbandwidth * (1-nags_targets_democracy) + ...)` | Region-year FE | Visibility amplifier. |
| **H15** | Leader Survival (duration) | nags_any_support * (1-nags_targets_democracy) | Cox / Logit | Survival = β·NonDemNAG + controls | Same | survival | `coxph(Surv(tenure) ~ nags_any_support * (1-nags_targets_democracy) + ...)` | — | Survival via dual signaling. |
| **H16** | NAG Support Count | sidea_dynamic_leader * oppsize_norm | Poisson | log(Count) = β₀ + β₁·Dynamic + β₂·OppSize + β₃·(Dynamic × OppSize) + controls | Same | fixest | `fepoisson(nags_support_count ~ sidea_dynamic_leader * oppsize_norm + ...)` | No avoidance of dem targets | Messianic test. |

## General Roadmap Notes (apply to every script)
- **One model at a time** (Rule 10): Each hypothesis = its own script (05_model_paper2_hX_....R).
- **Header for every model script**:
  ```r
  here::i_am("R/models/05_model_paper2_hX_....R")
  source(here("R/shared/04_trim_and_finalize.R"))
