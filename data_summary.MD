# Data Summary – Final Trimmed Dataset (March 14, 2026)

This is the `summary(df_final)` output from the trimmed dataset (`GRAVE_D_Master_with_Leaders_nags_signals_trimmed.rds`) after all derivations, transformations, and whitelisting in the `nags_signaling` pipeline.

Total rows: **1,126,609**  
Total columns after trimming: **~65** (exact count depends on missingness in whitelist)

## Key Identifiers and Structure

| Variable       | Min     | 1st Qu. | Median  | Mean    | 3rd Qu. | Max     | Notes                          |
|----------------|---------|---------|---------|---------|---------|---------|--------------------------------|
| COWcode_a      | 31.0    | 365.0   | 517.0   | 492.7   | 692.0   | 950.0   | Sender COW code                |
| COWcode_b      | 2.0     | 230.0   | 452.0   | 463.3   | 670.0   | 990.0   | Target COW code                |
| year           | 1960    | 1981    | 1995    | 1994    | 2008    | 2020    | Dyad-year                      |
| dyad           | -       | -       | -       | -       | -       | -       | Character dyad identifier      |
| dyad_id        | -       | -       | -       | -       | -       | -       | Factorized dyad                |
| unregiona      | -       | -       | -       | -       | -       | -       | Sender UN region               |

## NAG Support Outcomes

| Variable                  | Min   | 1st Qu. | Median | Mean    | 3rd Qu. | Max   | Notes                                      |
|---------------------------|-------|---------|--------|---------|---------|-------|--------------------------------------------|
| nags_any_support          | 0     | 0       | 0      | 0       | 0       | 0     | Any support (active + de facto)            |
| nags_support_count        | 0     | 0       | 0      | 0       | 0       | 0     | Count of supported NAGs                    |
| nags_training             | 0.000 | 0.000   | 0.000  | 0.00134 | 0.000   | 1.000 | Training support (visible/high-cost)       |
| nags_arms                 | 0.000 | 0.000   | 0.000  | 0.00154 | 0.000   | 1.000 | Arms/transport support                     |
| nags_funds                | 0.000 | 0.000   | 0.000  | 0.00122 | 0.000   | 1.000 | Financial support                          |
| nags_troops               | 0.000 | 0.000   | 0.000  | 0.00033 | 0.000   | 1.000 | Troop support                              |
| high_cost_support         | FALSE (1,124,232) / TRUE (2,377) | - | - | - | - | - | Troops, training, or arms (logical)        |
| low_cost_domestic_support | FALSE (1,124,040) / TRUE (2,569) | - | - | - | - | - | Funds/safe haven, non-democracy targeting  |

## Signaling & Interaction Variables

| Variable                      | Min      | 1st Qu. | Median | Mean | 3rd Qu. | Max     | NA's   | Notes                                      |
|-------------------------------|----------|---------|--------|------|---------|---------|--------|--------------------------------------------|
| oppsize_norm                  | -3.136   | -0.741  | 0.177  | 0.000| 0.769   | 2.177   | 63,965 | Normalized opposition group size (SD units)|
| opposition_training_int       | -2.829   | 0.000   | 0.000  | 0.000| 0.000   | 2.177   | 63,965 | Opp size × training (resolve signal)       |
| bandwidth_visibility          | 0.000    | 0.000   | 0.000  | 0.000| 0.000   | 0.191   | 42,703 | Bandwidth × training (visibility amp)      |
| bandwidth_proximity_norm      | -1.307   | -0.633  | -0.371 | 0.000| 0.154   | 3.188   | 42,703 | Normalized winsorized proximity-bandwidth  |

## Main Predictors (Normalized where applied)

| Variable                   | Min      | 1st Qu. | Median | Mean | 3rd Qu. | Max     | NA's   | Notes                                      |
|----------------------------|----------|---------|--------|------|---------|---------|--------|--------------------------------------------|
| revisionist_norm           | -2.308   | -0.830  | -0.022 | 0.000| 0.707   | 2.478   | -      | Normalized sidea_revisionist_domestic      |
| legit_ideol_ratio_norm     | -4.497   | -0.110  | 0.019  | 0.000| 0.141   | 4.192   | -      | Normalized winsorized legit ratio          |
| sidea_revisionist_domestic | -2.701   | -0.774  | 0.279  | 0.307| 1.229   | 3.536   | -      | Raw V-Dem ideology latent                  |

## Controls & Other Continuous

| Variable              | Min       | 1st Qu. | Median | Mean  | 3rd Qu. | Max     | NA's   | Notes                                      |
|-----------------------|-----------|---------|--------|-------|---------|---------|--------|--------------------------------------------|
| ln_capital_dist_km    | 0.000     | 8.370   | 8.878  | 8.733 | 9.286   | 9.899   | 42,703 | Logged capital distance (km + 1)           |
| cinc_a_log            | -12.925   | -8.156  | -7.154 | -7.228| -5.835  | -1.465  | -      | Logged capabilities (A)                    |
| cinc_b_log            | -13.597   | -8.478  | -7.120 | -7.347| -5.690  | -1.465  | -      | Logged capabilities (B)                    |
| politicalbandwidth_norm | -1.382  | -0.633  | -0.348 | 0.000 | 0.198   | 3.954   | -      | Normalized political bandwidth             |

### Notes
- NAs primarily in V-Dem variables (e.g., 63,965 for opposition-related, 42,703 for distance/bandwidth) — typical for autocracy subset and dyadic sparsity.
- All continuous predictors used in main models are either normalized (mean 0, sd 1) or logged to address scale mismatch and improve stability/interpretability.
- Raw versions (e.g., `sidea_revisionist_domestic`, `capital_dist_km`) are retained for robustness checks.

This summary reflects the state after all transformations and trimming in the `nags_signaling` pipeline (March 14, 2026).
