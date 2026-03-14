# =============================================================================
# 03_derive_signaling_vars.R
# Derives signaling-specific variables and interactions on top of prepared data
# =============================================================================

source(here::here("R/shared/02_data_prep.R"))  # Loads and prepares df_prep

message("Starting derivation of signaling variables on df_prep...")

if (!exists("df_prep")) {
  stop("df_prep not found. 02_data_prep.R did not complete successfully.")
}

# Pre-mutate diagnostic: check opposition variable
message("Pre-derivation summary of v2regoppgroupssize_a:")
summary(df_prep$v2regoppgroupssize_a)

df_prep <- df_prep |>
  mutate(
    autocracy_a = v2x_libdem_a < 0.5,
    nags_dem_target_support = nags_any_support * targets_democracy,
    legit_ideol_ratio = v2exl_legitideol_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + v2exl_legitperf_a + 1e-6),
    
    # Opposition normalization (safe against all-NA or constant)
    oppsize_norm = if (all(is.na(v2regoppgroupssize_a)) || sd(v2regoppgroupssize_a, na.rm = TRUE) == 0) {
      rep(0, n())  # fallback if no variation
    } else {
      as.vector(scale(v2regoppgroupssize_a))
    },
    
    high_cost_support = nags_troops | nags_training | nags_arms,
    low_cost_domestic_support = (nags_funds | nags_safe_haven) & !nags_dem_target_support,
    cold_war = as.integer(year <= 1991),
    war_on_terror = as.integer(year >= 2001),
    opposition_training_int = oppsize_norm * nags_training,
    bandwidth_visibility = politicalbandwidth * nags_training,
    bandwidth_proximity = politicalbandwidth * (1 / log(capital_dist_km + 1))
  )

# --- Additional transformations & normalizations for modeling stability ---
# These create scaled/winsorized versions of key continuous predictors
# All are optional but recommended for interaction-heavy models
df_prep <- df_prep |>
  mutate(
    # 1. Capital distance: already logged, just rename for clarity
    ln_capital_dist_km = log(capital_dist_km + 1),  # existing, renamed
    
    # 2. Winsorize & normalize legit_ideol_ratio (extreme range from division instability)
    legit_ideol_ratio_wins = pmax(pmin(legit_ideol_ratio, 10), -10),  # cap at ±10
    legit_ideol_ratio_norm = scale(legit_ideol_ratio_wins),
    
    # 3. Normalize sidea_revisionist_domestic (V-Dem latent, subset shift)
    revisionist_norm = scale(sidea_revisionist_domestic),
    
    # 4. Normalize politicalbandwidth (visibility amplifier, used in interactions)
    politicalbandwidth_norm = scale(politicalbandwidth),
    
    # 5. Winsorize & normalize bandwidth_proximity (Inf values from 1/log(0+1))
    bandwidth_proximity_cap = pmin(
      bandwidth_proximity,
      quantile(bandwidth_proximity, 0.99, na.rm = TRUE)
    ),
    bandwidth_proximity_norm = scale(bandwidth_proximity_cap),
    
    # 6. Optional: log-transform CINC (tiny values, common in capabilities models)
    cinc_a_log = log(cinc_a + 1e-6),
    cinc_b_log = log(cinc_b + 1e-6)
  )

# Post-mutate diagnostics
# Post-mutate diagnostics
message("Post-derivation summary of oppsize_norm:")
summary(df_prep$oppsize_norm)

message("First 5 rows of key signaling columns (using base-R subset):")
key_cols <- c("year", "COWcode_a", "COWcode_b", "oppsize_norm", 
              "opposition_training_int", "bandwidth_visibility", "high_cost_support")
available_cols <- key_cols[key_cols %in% names(df_prep)]
print(df_prep[1:5, available_cols, drop = FALSE])

# Save
saveRDS(df_prep, here("data", "GRAVE_D_Master_with_Leaders_nags_signals.rds"))
message("Enriched dataset saved: GRAVE_D_Master_with_Leaders_nags_signals.rds")
message("Derivation complete.")