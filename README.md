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

Three ideal types structure the theory (consistent with Paper 1):

| Type                  | Core Claim                                      | Key Mechanism                          |
|-----------------------|-------------------------------------------------|----------------------------------------|
| **The Ideological Autocrat** | Leadership ideology drives support as direct preference expression | Direct ideological goals               |
| **The Rational Autocrat**    | Support group ideology drives NAG support as costly signal | Coalition loyalty maintenance via nonmaterial payoffs |
| **The Messianic Autocrat**   | Dynamic personal leadership drives support     | Leader charisma / personal drive       |

The **Rational Autocrat** argument is the primary theoretical contribution: NAG support serves as an instrumental, low-cost (relative to direct conflict) signal to ideological supporters, tested against the alternatives.

---

## Hypotheses

Hypotheses are organized in tiers from simplest (main effects) to complex (mechanisms/outcomes). Full details in analysis scripts and Quarto documents.

### Tier 1 — Simple Models (Support Count/Probability)

- **H1** The Ideological Autocrat — Support Count  
- **H2** The Rational Autocrat — Support Count  
- **H3** The Messianic Autocrat — Support Count  

### Tier 2 — Alignment and Legitimation Mix (Dyadic)

- **H4** The Ideological Autocrat — Ideological Alignment  
- **H5** The Ideological Autocrat — Autocratic Alignment  
- **H6** The Ideological Autocrat — Targeting Democracies  
- **H7** Legitimation Mix — Support Count  
- **H11** Ideological Mismatch Penalty  
- **H12** Bandwidth as Signal Amplifier  

### Tier 3 — Mediation, Moderation, and Survival

- **H8** Moderation — Dynamic Leadership  
- **H9** Mediation — Support Groups  
- **H10** Survival Mediation  
- **H13** Regime Age Moderation  
- **H14** Risk-Averse Targeting  

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

## Repository Structure
