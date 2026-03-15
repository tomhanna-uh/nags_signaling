# GRAVE-D Data Summary for nags_signaling Project
**Last updated:** March 14, 2026  
**Dataset:** `df_final` (after `02_data_prep.R` + `03_derive_signaling_vars.R` + `04_trim_and_finalize.R`)  
**Purpose:** Autocratic dyad-year panel for Papers 2 & 3 (ideological signaling + opposition resolve via NAG support)

## Dataset Overview
- **Rows:** 1,126,609  
- **Columns:** 63  
- **Time span:** 1960–2020  
- **Units:** Directed dyad-year (Sender A = autocracy only; v2x_libdem_a < 0.5)  
- **Source:** GRAVE-D master (spine_ideology_nags.rds → controls → master → imputation → trim)

## Key NAG Variables (now correctly merged and with real variation)
These are the core outcome variables for your signaling hypotheses:

| Variable                  | Type    | Min | Max | Mean   | Non-zero rows | Notes |
|---------------------------|---------|-----|-----|--------|---------------|-------|
| nags_support_count        | integer | 0   | 7   | 0.0037 | ~4,200        | Count of distinct NAGs supported |
| nags_training             | numeric | 0   | 9   | 0.0030 | ~3,083        | Training camps/support count |
| nags_arms                 | numeric | 0   | 5   | 0.0031 | ~3,608        | Weapons/logistics count |
| nags_funds                | numeric | 0   | 5   | 0.0028 | ~3,903        | Financial aid count |
| nags_troops               | numeric | 0   | 4   | 0.0004 | ~398          | Troop support count |
| nags_safe_haven           | numeric | 0   | 7   | 0.0043 | ~5,485        | Safe haven count |
| nags_any_support          | numeric | 0   | 1   | 0.0055 | ~6,200        | Binary (any support) |
| nags_active_support       | numeric | 0   | 1   | 0.0046 | ~6,618        | Binary (active types) |
| nags_defacto_support      | numeric | 0   | 1   | 0.0036 | ~4,000        | Binary (de-facto) |

## Derived Signaling & Interaction Variables
- `high_cost_support` & `low_cost_domestic_support`: logical (TRUE/FALSE) – consider converting to integer 0/1 for models.
- `opposition_training_int`: numeric interaction (oppsize_norm × nags_training)
- `bandwidth_visibility` & `bandwidth_proximity`: numeric (some Inf values in proximity due to log(0))
- `nags_dem_target_support` & `nags_targets_democracy`: numeric/binary

## Ideology & Legitimation Variables (core predictors)
- `sidea_revisionist_domestic`: numeric (mean 0.307, range -2.70 to 3.54)
- `revisionist_high`: integer 0/1
- `ideol_legit_ratio` & `legit_ideol_ratio`: numeric (some large negative values from division)
- `v2exl_legitideol_a`, `v2exl_legitlead_a`, `v2exl_legitperf_a`: V-Dem legitimation scores

## Controls & Normalization Notes
- Most continuous controls (`cinc_a`, `politicalbandwidth`, `capital_dist_km`, etc.) are numeric.
- Several normalized variables are stored as **matrix/array** (from `scale()` inside `mutate`):
  - `opposition_dem_target_int`
  - `legit_ideol_ratio_norm`
  - `revisionist_norm`
  - `politicalbandwidth_norm`
  - `bandwidth_proximity_norm`
- `oppsize_norm`: numeric (good)
- `ln_capital_dist_km` & `cinc_a_log` / `cinc_b_log`: numeric (recommended transformations)

## Data Types Summary (from `sapply(df_final, class)`)
- **integer**: 12 vars (counts, binaries, year, COW codes)
- **numeric**: 42 vars (most controls, NAG counts, scaled vars)
- **character**: 3 vars (dyad, unregiona)
- **logical**: 3 vars (`autocracy_a`, `high_cost_support`, `low_cost_domestic_support`)
- **factor**: 1 var (`dyad_id`)
- **matrix/array**: 5 vars (the problematic scaled ones above)


