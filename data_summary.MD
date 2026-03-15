# GRAVE-D Data Summary for nags_signaling Project
**Last updated:** March 14, 2026  
**Dataset:** `df_final` (after `04_trim_and_finalize.R`)  
**Rows:** 1,126,609  
**Columns:** 45 (trimmed whitelist)  
**Time span:** 1960–2020  
**Units:** Directed dyad-year (autocracies only)

## Status of Fixes (March 14, 2026)
- All `_norm` variables are now plain numeric (no matrix/array).
- Logical flags (`high_cost_support`, `low_cost_domestic_support`, `autocracy_a`) are now integer 0/1.
- `bandwidth_proximity` Inf values replaced with NA.
- NAG counts are numeric with real variation.
- All variables are model-ready.

## Key NAG Variables (real variation present)
| Variable                | Type    | Min | Max | Mean   | Non-zero rows | Notes |
|-------------------------|---------|-----|-----|--------|---------------|-------|
| nags_support_count      | numeric | 0   | 7   | 0.0037 | ~4,200        | Count of distinct NAGs |
| nags_training           | numeric | 0   | 9   | 0.0030 | ~3,083        | Training count |
| nags_arms               | numeric | 0   | 5   | 0.0031 | ~3,608        | Arms/logistics count |
| nags_funds              | numeric | 0   | 5   | 0.0028 | ~3,903        | Financial aid count |
| nags_troops             | numeric | 0   | 4   | 0.0004 | ~398          | Troop count |
| nags_safe_haven         | numeric | 0   | 7   | 0.0043 | ~5,485        | Safe-haven count |
| nags_any_support        | numeric | 0   | 1   | 0.0055 | ~6,200        | Any support (binary) |
| nags_active_support     | numeric | 0   | 1   | 0.0046 | ~6,618        | Active support (binary) |
| nags_defacto_support    | numeric | 0   | 1   | 0.0036 | ~4,000        | De-facto support (binary) |

## Derived Signaling Variables
- `high_cost_support`, `low_cost_domestic_support`: numeric 0/1 (fixed from logical)
- `opposition_training_int`: numeric interaction
- `bandwidth_visibility`, `bandwidth_proximity`: numeric (no Inf)
- `nags_dem_target_support`, `nags_targets_democracy`: numeric/binary

## Ideology & Legitimation (core predictors)
- `sidea_revisionist_domestic`: numeric (-2.70 to 3.54)
- `revisionist_high`: numeric 0/1
- `ideol_legit_ratio`: numeric (some large negatives from division)
- Normalized versions (`_norm` columns): now clean numeric

## Controls & Transformations
- `ln_capital_dist_km`, `cinc_a_log`, `cinc_b_log`: numeric (recommended)
- `politicalbandwidth_norm`, etc.: numeric

## Data Types (all clean)
- **numeric**: 38 variables  
- **integer**: 7 variables  
- No matrix/array, no logical flags left.

## Recommendations for Future Scripts
1. **Use friendly English labels** in all tables/plots (e.g., “NAG Training Support (count)” instead of `nags_training`).
2. **Drop NAs** only on key variables in models:
   ```r
   df_model <- df_final %>% drop_na(nags_training, sidea_revisionist_domestic)
