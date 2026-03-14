# Non-State Armed Groups and Ideological Signaling

**Author:** Tom Hanna  
**ORCID:** 0000-0002-8054-0335  
**Affiliation:** University of Houston, Department of Political Science  
**License:** [CC BY-NC-SA 4.0](http://creativecommons.org/licenses/by-nc-sa/4.0/)  
**Copyright:** Tom Hanna, 2020–2026  

---

## Overview

This repository consolidates research on autocratic use of non-state armed groups (NAGs) as tools of ideological signaling and autocracy promotion. It combines two closely related dissertation papers (Papers 2 and 3) that extend the signaling framework developed in Paper 1 ("Autocracy, Conflict, and Ideological Signaling").

- **Paper 2** ("Autocracy, Non-State Armed Groups, and Ideological Signaling") argues that rational autocrats provide support to NAGs as a costly, visible signal of ideological commitment to domestic revisionist support coalitions, enhancing leader survival through nonmaterial payoffs.
- **Paper 3** ("Non-State Armed Groups as Signals of Resolve to Domestic Opposition") examines the dual role of highly visible NAG support: signaling to supporters while also projecting resolve to domestic opponents, with rational limits to avoid excessive external risks.

Both papers use an integrated GRAVE-D dyadic framework (state A support for NAGs targeting state B), drawing on the Non-State Armed Groups Database merged into GRAVE-D 2026.

---

## Data Pipeline & Processing (Updated March 14, 2026)

Primary dataset: `data/GRAVE_D_Master_with_Leaders_nags_signals_trimmed.rds`  
~1.13 million dyad-years, trimmed to ~65 columns (after whitelisting and transformations).

**Pipeline flow**:
1. `R/shared/01_load_data.R` → Loads raw GRAVE-D master (`df_raw`)
2. `R/shared/02_data_prep.R` → Filters to autocracies, imputes, derives basics (`df_prep`)
3. `R/shared/03_derive_signaling_vars.R` → Adds signaling interactions, normalizations, logs, winsorizing (main + raw versions for robustness)
4. `R/shared/04_trim_and_finalize.R` → Applies whitelist trim, aggressive environment cleanup + gc(), saves trimmed RDS

**Key new transformations** (in `03`):
- `ln_capital_dist_km = log(capital_dist_km + 1)`
- Normalized versions (`_norm` suffix) for `oppsize_norm`, `revisionist_norm`, `legit_ideol_ratio_norm`, `politicalbandwidth_norm`, `bandwidth_proximity_norm`
- Winsorized versions (`_wins`, `_cap`) for extreme ratios and proximity
- Logged CINC (`cinc_a_log`, `cinc_b_log`)
- Raw versions retained for robustness checks

**Environment cleanup** (in `04`): Removes `df_raw`, `df_prep`, temp objects; keeps `df_final`, functions, configs. Run `gc()` twice for memory release.

---

## Abstract (Paper 2: Core Signaling to Supporters)

Why do some autocratic regimes provide support to non-state armed groups, including insurgents and terrorists, even when such actions risk international isolation, sanctions, or retaliation? While strategic motives explain some instances of conflict export, they fail to account for the persistence of support in cases where material gains are minimal or negative. This paper argues that rational autocrats use support for non-state armed groups as a costly signal of ideological commitment to their domestic support coalitions, particularly when those coalitions are dominated by revisionist ideological factions. Just as material payoffs secure loyalty in resource-based regimes, visible ideological signals—such as backing aligned armed groups abroad—enhance leader survival by satisfying the nonmaterial demands of key supporters, regardless of the groups' success on the ground.

This project tests the **Rational Autocrat** hypothesis against the competing **Messianic Autocrat** explanation, which attributes such behavior to charismatic leaders pursuing personal normative preferences. Drawing on dyadic data from the Non-State Armed Groups Database integrated into GRAVE-D (with leadership ideology measures and V-Dem legitimation variables), the analysis employs negative binomial and logistic regression models to examine patterns of support initiation, target selection, and alignment. The results demonstrate that revisionist ideology drives support for ideologically congruent groups, that this signaling mechanism boosts domestic legitimation, and that it accounts for a significant portion of conflict export not explained by strategic factors alone. These findings highlight how domestic ideological pressures shape autocratic foreign policy, extending the logic of coalition maintenance beyond material incentives.

---

**Abstract**

Why do autocratic regimes provide visible support to foreign non-state armed groups (NAGs) when facing large domestic opposition, even at the risk of international retaliation? Existing explanations emphasize strategic motives or irrational leadership, yet fail to account for patterns where material gains are minimal and risks are high. This paper argues that rational autocrats use highly visible NAG support—particularly hosting military training camps—as a costly signal of resolve directed at domestic opponents, deterring challengers by projecting willingness to employ armed force. The same action simultaneously signals ideological commitment to supporters (as demonstrated in companion work), creating a dual-purpose mechanism that enhances leader survival by satisfying multiple domestic audiences with one observable behavior.

However, leaders act with bounded rationality: as opposition grows, they increase overall NAG support but strategically avoid (or reduce) backing groups that target democracies, thereby limiting the probability of severe retaliation from powerful states or their allies. This trade-off balances domestic credibility against external costs.

Using dyadic data from the GRAVE-D framework and the Dangerous Companions Dyadic Target-Supporter Dataset, the analysis employs logistic regression and multi-stage probit/control-function methods to address endogeneity between opposition size and regime behavior. Results confirm the positive effect of opposition on NAG support, the strategic avoidance of democracy-targeting groups, and the survival benefits of this bounded signaling strategy. These findings extend the logic of autocratic coalition management beyond material payoffs, showing how revisionist pressures shape foreign policy as a tool for domestic political survival.


---

## Theory

The combined project examines how autocratic regimes use support for non-state armed groups (NAGs) as a costly signaling mechanism in two directions: to satisfy ideological winning coalitions (Paper 2) and to project resolve to domestic opposition (Paper 3). Both papers build on the same core insight: **revisionist leadership ideology**—a coherent system of ideals seeking radical change in domestic and/or international order—drives visible, risky foreign policy behavior beyond what pure strategic motives would predict.

Three ideal types structure the overall analysis (primarily for supporter signaling in Paper 2, with Paper 3 focusing on opposition dynamics):

| Type                        | Core Claim                                                                 | Key Mechanism / Explanation                                                                 |
|-----------------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| **The Ideological Autocrat** (Baseline) | Revisionist leadership ideology predicts greater NAG support, ideological alignment with supported groups, and targeting of rivals (e.g., democracies). | This is the empirical baseline pattern observed across autocracies; it does not specify the underlying driver and serves as the foundation that both explanatory types seek to explain. |
| **The Rational Autocrat** (Primary Explanation) | The baseline pattern arises because rational leaders instrumentally use NAG support as a costly, visible signal of revisionist commitment to domestic audiences—first to ideological supporters (Paper 2), and second to opponents (Paper 3). | Coalition loyalty maintenance and deterrence via nonmaterial payoffs: visible support satisfies revisionist supporters, deters challengers, enhances legitimation, and boosts leader survival—while leaders strategically avoid excessive external risks (e.g., backing groups that target democracies). |
| **The Messianic Autocrat** (Competing Alternative) | The baseline pattern arises because dynamic, charismatic leaders personally pursue revisionist normative goals abroad. | Leader charisma / personal drive: support for NAGs reflects the leader's own ideological preferences and boldness, rather than calculated domestic signaling. |

The project argues that the **Rational Autocrat** mechanism best explains the data: NAG support functions as a low-cost (relative to direct conflict) ideological signal to domestic audiences, with rational leaders balancing credibility gains against retaliation risks.

### Opposition Signaling Claims (Paper 3 Focus)

Paper 3 extends the framework by examining how the **same highly visible NAG support** also serves as a signal of resolve to domestic opposition. The key claims are:

| Claim / Mechanism                          | Description                                                                 | Role in Signaling to Opposition                                                                 |
|--------------------------------------------|-----------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------|
| **Positive Effect of Opposition Size**     | Larger domestic opposition groups (`v2regoppgroupssize_a`) increase overall NAG support (including hosting training camps). | Projects willingness to use armed force, raising the perceived cost of opposition and deterring challengers. |
| **Dual-Purpose Nature**                    | The same visible act (NAG support) signals commitment to supporters (Paper 2) and resolve to opponents (Paper 3). | Enhances leader survival by satisfying multiple domestic audiences with one costly action. |
| **Strategic Avoidance / Bounded Rationality** | Leaders avoid or reduce support for NAGs targeting democracies when opposition is large, limiting retaliation risks from powerful states/allies. | Balances domestic credibility (project strength) against external costs (sanctions, war, isolation). |
| **Visibility & Costliness**                | Support must be highly visible (e.g., hosting camps on home territory) to credibly signal resolve. | Increases domestic deterrence effect while making denial or misperception less plausible. |
| **Survival Benefit**                       | Rational use of NAG support as dual signaling improves leader tenure/survival when opposition grows. | Nonmaterial payoff: deters opposition mobilization and reduces need for more costly domestic repression. |

These claims emphasize that opposition signaling is **not** a separate logic from supporter signaling but an **extension** of the same rational autocrat behavior—leaders use visible foreign actions to manage both audiences while strategically managing risks.

### Hypotheses

Hypotheses are separated by paper/chapter for clarity. All apply among autocracies and use dyadic GRAVE-D structure (Side A support for NAGs targeting Side B).

#### Paper 2 Hypotheses: Signaling to Supporters / Coalitions

**Tier 1 — Baseline & Simple Models**
- **H1** (Ideological Revisionism — Support Count)  
  Among autocracies, higher revisionist leadership ideology increases support for NAGs targeting the other state in the dyad.  
  *Tests baseline pattern*

- **H2** (Rational Signaling — Support Count)  
  Among autocracies, higher support from revisionist groups increases NAG support as signaling to coalitions.  
  *Rational explanation*

- **H3** (Messianic Drive — Support Count)  
  Among autocracies, higher personalist legitimation increases NAG support.  
  *Messianic explanation*

**Tier 2 — Alignment & Legitimation Mix**
- **H4** (Revisionist Alignment)  
  Higher revisionist ideology boosts support for ideologically congruent NAGs.  
  *Baseline pattern*

- **H5** (Autocratic Goals Alignment)  
  Higher revisionist ideology boosts support for NAGs seeking autocracy in the target.  
  *Baseline pattern*

- **H6** (Targeting Democracies)  
  Higher revisionist ideology boosts support for NAGs targeting democracies.  
  *Baseline pattern*

- **H7** (Legitimation Trade-offs)  
  Higher ideological legitimation ratio increases NAG support, while personalist reduces it.  
  *Rational vs. Messianic*

**Tier 3 — Mechanisms & Survival**
- **H8** (Leadership Moderation)  
  Dynamic leadership amplifies revisionism's effect on NAG support.  
  *Messianic explanation*

- **H9** (Support Group Mediation)  
  Revisionist ideology's effect on aligned NAG support is mediated by ideological support groups.  
  *Rational explanation*

- **H10** (Survival Via Signaling)  
  Aligned NAG support boosts leader survival via ideological legitimation.  
  *Rational explanation*

#### Paper 3 Hypotheses: Signaling to Opposition / Resolve

**Tier 1 — Baseline & Simple Effects**
- **H11** (Opposition Size — General Support)  
  Among autocracies, larger domestic opposition groups increase the likelihood of actively supporting at least one NAG targeting the other state in the dyad, all else equal.  
  *Baseline pattern (from older drafts)*

- **H12** (Opposition Size — Hosting Camps)  
  Among autocracies, larger domestic opposition groups increase the likelihood of hosting one or more domestic training camps for foreign NAGs targeting the other state in the dyad, all else equal.  
  *Specific visible/costly form (from older drafts)*

**Tier 2 — Strategic Avoidance & Bounded Rationality**
- **H13** (Opposition Size — Strategic Avoidance)  
  Among autocracies, larger domestic opposition increases support for NAGs that **do not target democracies** but decreases (or has no effect on) support for NAGs that **do target democracies** (interaction with democracy-targeting indicator), all else equal.  
  *Rational explanation – core bounded signaling claim*

- **H14** (Visibility & Bandwidth)  
  The avoidance of democracy-targeting NAGs in H13 is stronger in high-diplomatic-bandwidth dyads (FBIC measures), where risks are more visible and credible.  
  *Rational explanation – visibility amplifier*

**Tier 3 — Mechanisms & Survival**
- **H15** (Survival via Dual Signaling)  
  NAG support (especially non-democracy-targeting) increases leader survival when domestic opposition is high (mediated path: opposition → support → enhanced legitimation or reduced opposition mobilization → survival).  
  *Rational explanation*

- **H16** (Messianic Test)  
  Dynamic leadership qualities amplify the overall increase in NAG support with opposition but do **not** produce strategic avoidance of democracy-targeting groups.  
  *Messianic vs. Rational test*

### Identification Strategy Note
Endogeneity between opposition size and NAG support is addressed using instrumental-variable or control-function approaches. The preferred method is a **multi-stage probit / control function estimator** (Wooldridge-style) for binary outcomes: first-stage probit on opposition size or support indicator using valid instruments, followed by inclusion of generalized residuals in the second-stage outcome equation. This is implemented in analysis scripts and reported as a robustness check.


---

## Data
Primary: `GRAVE_D_Master_with_Leaders_nags_signals.rds` (from grave_d_data2026 pipeline, now including `capital_dist_km` from Gleditsch/Weidmann capitals data, joined to FBIC spine).

**New in 2026 pipeline**:
- `capital_dist_km` — Static dyadic distance between capitals; transform to `log_capdist = log(capital_dist_km + 1)` for models.
- Enables visibility/proximity tests in H14 (bandwidth amplification) and extensions (e.g., proximity × opposition interactions).

**Derived variables** (R/shared/03_derive_signaling_vars.R):
- `autocracy_a`, `nags_dem_target_support`, `legit_ideol_ratio`, `oppsize_norm`, `high_cost_support`, `low_cost_domestic_support`, `cold_war`, `war_on_terror`, `opposition_training_int`, `bandwidth_visibility`, `log_capdist`, `bandwidth_proximity_int`, `opposition_dem_target_int`.
These power core hypotheses: H9 mediation, H12–H14 visibility/avoidance, H15–H16 dual signaling/survival.

## Running the analysis
```r
source("R/00_packages.R")
source("R/shared/01_load_data.R")           # now loads updated master with capdist
source("R/shared/02_data_prep.R")
source("R/shared/03_derive_signaling_vars.R")  # includes new distance derivations
# Then run paper2/ and paper3/ model scripts
---

## Running the Analysis

```r
# Install/load packages
source("R/00_packages.R")

# Load/prep (includes NAG merge)
source("R/01_load_data.R")
source("R/02_data_prep.R")

# Run models by tier/paper
source("R/03_h1_h3_count.R")     # Tier 1
source("R/04_h4_h7_alignment.R") # Tier 2
source("R/05_h8_h14_mechanisms.R") # Tier 3 + Paper 3

# Tables
source("R/06_reporting_tables.R")


## To render the manuscript

cd docs
quarto render

## Repository Structure

nags_signaling/
├── README.md
├── nags_signaling.Rproj
├── .gitignore
├── data/                                    # gitignored
│   └── GRAVE_D_Master_with_Leaders_nags_signals_trimmed.rds
R/
├── shared/                                  # Common pipeline scripts
│   ├── 00_packages.R
│   ├── 01_load_data.R
│   ├── 02_data_prep.R
│   ├── 03_derive_signaling_vars.R          # All derivations + normalizations
│   ├── 04_trim_and_finalize.R              # Trim, cleanup, save trimmed RDS
|   ├── 06_helpers.R
|   ├── 11_h8_h14_mechanism.R
|   └── 12_reporting_tables.R
├── paper2/                                  # Ideological commitment signaling (supporters)
│   ├── 07_h1_h3_count.R
│   ├── 08_h7_h8_alignment.R
│   └── ... (add as needed)
├── paper3/                                  # Opposition resolve signaling
│   ├── 09_h10_survival_dual.R
│   ├── 10_h14_risk_opposition.$
│   └── ... (add as needed)
└── models/                                  # Shared or standalone model scripts
└── paper2_resolve_baseline.R           # Example

## Related Repositories

## Related Repositories

- Paper 1: [Autocracy, Conflict, and Ideological Signaling](https://github.com/tomhanna-uh/autocracy_conflict_signaling) (or equivalent) — MIDs-focused signaling.
- GRAVE-D Data: [grave_d_data2026](https://github.com/tomhanna-uh/grave_d_data2026) — Master dataset assembly.

## Citation
Hanna, Tom. Non-State Armed Groups and Ideological Signaling. Working manuscript, University of Houston, 2026.

Note: References based on current drafts; full bibliography in Quarto docs.
