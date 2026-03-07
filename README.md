# Non-State Armed Groups and Ideological Signaling

**Author:** Tom Hanna  
**ORCID:** 0000-0002-8054-0335  
**Affiliation:** University of Houston, Department of Political Science  
**License:** [CC BY-NC-SA 4.0](http://creativecommons.org/licenses/by-nc-sa/4.0/)  
**Copyright:** Tom Hanna, 2020–2026  

---

## Overview

This repository consolidates research on autocratic use of non-state armed groups (NAGs) as tools of ideological signaling and autocracy promotion. It combines two closely related dissertation papers (Papers 2 and 3) that extend the signaling framework developed in Paper 1 ("Autocracy, Conflict, and Ideological Signaling"; see separate repository at [https://github.com/tomhanna-uh/autocracy_conflict_signaling](https://github.com/tomhanna-uh/autocracy_conflict_signaling) or equivalent).

- **Paper 2** ("Autocracy, Non-State Armed Groups, and Ideological Signaling") argues that rational autocrats provide support to NAGs as a costly, visible signal of ideological commitment to domestic revisionist support coalitions, enhancing leader survival through nonmaterial payoffs (parallel to material incentives in selectorate theory). It tests the **Rational Autocrat** hypothesis against **Ideological Autocrat** (direct preference) and **Messianic Autocrat** (charismatic drive) alternatives, using dyadic models of support initiation, alignment, and mediation.

- **Paper 3** ("Non-State Armed Groups as Signals of Resolve to Domestic Opposition") builds on this by examining the dual role of highly visible NAG support: while primarily signaling to supporters, it also projects resolve to domestic opponents, improving survival odds—but with rational limits to avoid excessive external risks (e.g., targeting powerful democracies).

Both papers use an integrated GRAVE-D dyadic framework (state A support for NAGs targeting state B), drawing on the Non-State Armed Groups Database (via Dyadic Target-Supporter Dataset) merged into GRAVE-D. They emphasize revisionist ideology and domestic coalition dynamics over purely strategic or charismatic explanations.

---

## Abstract (Paper 2: Core Signaling to Supporters)

Why do some autocratic regimes provide support to non-state armed groups, including insurgents and terrorists, even when such actions risk international isolation, sanctions, or retaliation? While strategic motives explain some instances of conflict export, they fail to account for the persistence of support in cases where material gains are minimal or negative. This paper argues that rational autocrats use support for non-state armed groups as a costly signal of ideological commitment to their domestic support coalitions, particularly when those coalitions are dominated by revisionist ideological factions. Just as material payoffs secure loyalty in resource-based regimes, visible ideological signals—such as backing aligned armed groups abroad—enhance leader survival by satisfying the nonmaterial demands of key supporters, regardless of the groups' success on the ground.

This project tests the **Rational Autocrat** hypothesis against the competing **Messianic Autocrat** explanation, which attributes such behavior to charismatic leaders pursuing personal normative preferences. Drawing on dyadic data from the Non-State Armed Groups Database integrated into GRAVE-D (with leadership ideology measures and V-Dem legitimation variables), the analysis employs negative binomial and logistic regression models to examine patterns of support initiation, target selection, and alignment. The results demonstrate that revisionist ideology drives support for ideologically congruent groups, that this signaling mechanism boosts domestic legitimation, and that it accounts for a significant portion of conflict export not explained by strategic factors alone. These findings highlight how domestic ideological pressures shape autocratic foreign policy, extending the logic of coalition maintenance beyond material incentives.

*(Abstract for Paper 3 forthcoming; focuses on dual signaling to opposition and bounded rationality in risk-taking.)*

---

## Theoretical Framework

Three ideal types structure the analysis of autocratic support for non-state armed groups (NAGs). The framework treats **revisionist leadership ideology** as the core driver of the empirical pattern: higher revisionism predicts greater NAG support, ideological alignment with supported groups, and targeting of rivals (e.g., democracies). This baseline pattern is labeled **Ideological Autocrat** and is the shared starting point across explanations.

The two explanatory subtypes then compete to account for *why* this pattern emerges:

| Type                        | Core Claim                                                                 | Key Mechanism / Explanation                                                                 |
|-----------------------------|----------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| **The Ideological Autocrat** (Baseline) | Revisionist leadership ideology predicts NAG support, alignment, and targeting of ideological rivals. | This is the core empirical baseline pattern observed across autocracies; it does not specify the underlying driver and serves as the foundation that both explanatory types seek to explain. |
| **The Rational Autocrat** (Primary Explanation) | The baseline pattern arises because rational leaders instrumentally use NAG support as a costly, visible signal of revisionist commitment to their domestic ideological winning coalitions. | Coalition loyalty maintenance via nonmaterial payoffs: visible support satisfies revisionist supporters, enhances legitimation, and boosts leader survival—independent of personal normative zeal. |
| **The Messianic Autocrat** (Competing Alternative) | The baseline pattern arises because dynamic, charismatic leaders personally pursue revisionist normative goals abroad. | Leader charisma / personal drive: support for NAGs reflects the leader's own ideological preferences and boldness, rather than calculated coalition signaling. |

The project argues that the **Rational Autocrat** mechanism best explains the data: NAG support functions as a low-cost (relative to direct interstate conflict) ideological signal to winning coalitions, accounting for patterns not fully captured by strategic motives alone. The Ideological Autocrat hypotheses establish the baseline association, while Rational and Messianic hypotheses test competing mechanisms through interactions, mediation, moderation, and survival outcomes.

## Hypotheses

Hypotheses are organized in tiers from simplest (establishing the baseline pattern) to more complex (testing explanatory mechanisms and outcomes). All apply among autocracies and use dyadic GRAVE-D structure (Side A support for NAGs targeting Side B).

### Tier 1 — Simple Models (Baseline Pattern: Support Count/Probability)

| Label | Substantive Name                          | Statement                                                                                          | Tests Which Type?          |
|-------|-------------------------------------------|----------------------------------------------------------------------------------------------------|----------------------------|
| **H1** | Ideological Revisionism — Support Count   | Among autocracies, higher revisionist leadership ideology (`sidea_revisionist_domestic` or subtypes) increases support for NAGs targeting the other state in the dyad. | Baseline (Ideological Autocrat pattern) |
| **H2** | Rational Signaling — Support Count        | Among autocracies, higher support from revisionist groups (e.g., `sidea_religious_support`) increases NAG support targeting the other state in the dyad as signaling to coalitions. | Rational Autocrat explanation |
| **H3** | Messianic Drive — Support Count           | Among autocracies, higher personalist legitimation (`v2exl_legitlead_a` or `sidea_dynamic_leader`) increases NAG support targeting the other state in the dyad. | Messianic Autocrat explanation |

### Tier 2 — Alignment and Legitimation Mix (Dyadic: Refining the Baseline and Mechanisms)

| Label | Substantive Name                  | Statement                                                                                          | Tests Which Type?          |
|-------|-----------------------------------|----------------------------------------------------------------------------------------------------|----------------------------|
| **H4** | Revisionist Alignment             | Among autocracies, higher revisionist ideology boosts support for ideologically congruent NAGs targeting the other state in the dyad (subtype match in NAG data). | Baseline pattern           |
| **H5** | Autocratic Goals Alignment        | Among autocracies, higher revisionist ideology boosts support for NAGs seeking autocracy in the target state (per NAG objectives). | Baseline pattern           |
| **H6** | Targeting Democracies             | Among autocracies, higher revisionist ideology boosts support for NAGs targeting democracies in the dyad (`v2x_polyarchy_b`). | Baseline pattern           |
| **H7** | Legitimation Trade-offs           | Among autocracies, higher ideological legitimation ratio (`v2exl_legitideol_a`) increases NAG support targeting the other state in the dyad, while personalist reduces it. | Rational vs. Messianic     |
| **H11**| Ideological Mismatch Penalty      | Among autocracies, ideological mismatch (Side A subtype vs. NAG ideology) decreases support probability for NAGs targeting the other state in the dyad. | Rational explanation (signal credibility) |
| **H12**| Visibility Amplifier              | Among autocracies, revisionist states prefer NAG support in high-bandwidth dyads (FBIC measures) for stronger signaling. | Rational explanation       |

### Tier 3 — Mediation, Moderation, and Survival (Mechanisms and Outcomes)

| Label | Substantive Name              | Statement                                                                                          | Tests Which Type?          |
|-------|-------------------------------|----------------------------------------------------------------------------------------------------|----------------------------|
| **H8** | Leadership Moderation         | Among autocracies, dynamic leadership (`sidea_dynamic_leader`) amplifies revisionism's effect on NAG support. | Messianic explanation      |
| **H9** | Support Group Mediation       | Among autocracies, revisionist ideology's effect on aligned NAG support is mediated by ideological support groups. | Rational explanation       |
| **H10**| Survival Via Signaling        | Among autocracies, aligned NAG support boosts leader survival via ideological legitimation (mediated: support → `v2exl_legitideol_a` → survival). | Rational explanation       |
| **H13**| Regime Age Moderation         | Among autocracies, revisionism's effect on NAG support is stronger in new regimes (low `reg_trans_a`) for coalition consolidation. | Rational explanation       |
| **H14**| Risk Balancing                | Among autocracies, revisionist states avoid NAG support targeting powerful states in the dyad (`cinc_b` interaction) to limit retaliation risks. | Rational explanation (bounded signaling) |

---

*(Paper 3 hypotheses focus on opposition signaling, resolve projection, and risk limits; detailed in dedicated scripts.)*

---







---

## Data

Primary dataset: **GRAVE_D_Master_with_Leaders.csv** (dyad-year, 1946–2020), augmented with NAG support variables (Side A support for groups targeting Side B) from the Dyadic Target-Supporter Dataset / Non-State Armed Groups Database.

Key sources:
- GRAVE-D: Ideology (`sidea_revisionist_domestic`, subtypes), support groups (`sidea_religious_support` etc.), legitimation (V-Dem `v2exl_legitideol_a` etc.), FBIC connectivity.
- NAG integration: Binary/count support, group ideology/objectives, targets (e.g., democracies).
- Other: COW CINC, MIDs (for risk proxies), leader tenure.

Data files gitignored; place in `data/` before running.

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
├── data/                          # gitignored — place GRAVE-D and NAG-derived files here
│   └── GRAVE_D_Master_with_Leaders.csv  # plus NAG support merges
R/
├── paper2/                # New subfolder for core signaling (supporters)
│   ├── 03_h1_h3_count.R
│   ├── 04_h4_h7_alignment.R
│   └── ... (Tier 1-2 mostly)
├── paper3/                # For opposition/resolve extensions
│   ├── 07_h10_survival_dual.R   # e.g., H10 + opposition mods
│   └── 08_h14_risk_opposition.R
├── shared/                # Common across both
│   ├── 01_load_data.R
│   ├── 02_data_prep.R
│   ├── 05_h8_h14_mechanisms.R   # Core mediation/survival shared
│   └── 06_reporting_tables.R
└── 00_packages.R
└── docs/
├── _quarto.yml
├── theory.qmd                 # Combined theory chapter
├── data_methods.qmd           # GRAVE-D + NAG integration
├── results_paper2.qmd         # Paper 2 results
├── results_paper3.qmd         # Paper 3 results
└── appendix.qmd               # Robustness, descriptives

## Related Repositories

## Related Repositories

- Paper 1: [Autocracy, Conflict, and Ideological Signaling](https://github.com/tomhanna-uh/autocracy_conflict_signaling) (or equivalent) — MIDs-focused signaling.
- GRAVE-D Data: [grave_d_data2026](https://github.com/tomhanna-uh/grave_d_data2026) — Master dataset assembly.

## Citation
Hanna, Tom. Non-State Armed Groups and Ideological Signaling. Working manuscript, University of Houston, 2026.

Note: References based on current drafts; full bibliography in Quarto docs.
