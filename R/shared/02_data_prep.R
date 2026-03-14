# ==============================================================================
# 02_data_prep.R
# Prepares the loaded GRAVE-D master dataset: filtering to autocracies,
# imputation of missing values, derivation of key variables (revisionist indicators,
# legitimation ratios, risk proxies, signaling interactions), and checks for NAG dyadic integration
#
# Non-State Armed Groups and Ideological Signaling:
# Autocratic Use of Non-State Armed Groups as Tools of Revisionist Signaling
# and Autocracy Promotion
#
# This script is part of the combined analysis for dissertation Papers 2 and 3.
# It builds on earlier work:
# - April 2022: "Authoritarian Leadership Politics and Conflict Export..."
# - July 2024: "Ideology and Autocracy Promotion Through Non-State Armed Groups..."
# - March 2026: Integrated capital distance, FBIC bandwidth interactions, opposition signaling
#
# Tom Hanna
# University of Houston
# Department of Political Science
# tlhanna@uh.edu
#
# Working manuscript and code repository
# Copyright © Tom Hanna, 2020–2026
# Licensed under CC BY-NC-SA 4.0
# Draft date: March 2026
# ==============================================================================
# Note: This script assumes:
# - df_raw has been loaded via 01_load_data.R
# - Project root is declared (via here::i_am() in the sourcing script or here)
# Run after sourcing 00_packages.R and 01_load_data.R

here::i_am("R/shared/02_data_prep.R")

# Confirm dependencies are loaded
if (!exists("df_raw")) {
  stop("df_raw not found. Please source 01_load_data.R first.")
}
message("Starting data preparation from raw GRAVE-D master dataset...")

# Step 1: Filter to relevant subset (autocracies only, non-missing key vars)
df_prep <- df_raw %>%
  # Sender (A) must be autocratic (V-Dem liberal democracy index threshold)
  filter(v2x_libdem_a < 0.5) %>%
  # Drop rows with structural missing on core ideology/legit vars
  drop_na(sidea_revisionist_domestic, v2exl_legitideol_a, v2exl_legitlead_a)
message("Filtered to autocracies: ", nrow(df_prep), " rows remaining")

# Step 2: Derive simplified variables + ALL signaling & interaction variables
df_prep <- df_prep %>%
  mutate(
    # --- Existing derivations ---
    # Binary high-revisionist indicator
    revisionist_high = if_else(
      sidea_revisionist_domestic > median(sidea_revisionist_domestic, na.rm = TRUE),
      1L,
      0L
    ),
    
    # Ideological legitimation ratio (safe against zero denominator)
    ideol_legit_ratio = v2exl_legitideol_a /
      (v2exl_legitideol_a + v2exl_legitlead_a + v2exl_legitperf_a + 1e-6),
    
    # Risk proxy
    risk_powerful_target = cinc_b * revisionist_high,
    
    # Dyad ID
    dyad_id = as.factor(paste(COWcode_a, COWcode_b, sep = "_")),
    
    # Regime newness proxy (use leader tenure if available, fallback to 0)
    regime_new = if_else(tenure < 5, 1L, 0L),
    
    # --- NEW: Opposition & signaling variables (Paper 3 core) ---
    oppsize_norm = scale(v2regoppgroupssize_a),  # standardized opposition group size
    
    # --- NEW: Distance & visibility proxies (H14 bandwidth amplification) ---
    log_capdist          = log(capital_dist_km + 1),  # +1 avoids log(0)
    bandwidth_visibility = politicalbandwidth * nags_training,                # classic visibility interaction
    bandwidth_proximity  = politicalbandwidth * (1 / log_capdist),           # stronger when close + high bandwidth
    
    # --- NEW: High-cost vs low-cost support composites ---
    high_cost_support       = nags_troops | nags_training | nags_arms,
    low_cost_domestic_support = (nags_funds | nags_safe_haven) & (targets_democracy == 0),
    
    # --- NEW: Period dummies ---
    cold_war     = as.integer(year <= 1991),
    war_on_terror = as.integer(year >= 2001),
    
    # --- NEW: Key interactions for opposition resolve signaling (H15–H16) ---
    opposition_training_int     = oppsize_norm * nags_training,
    opposition_dem_target_int   = oppsize_norm * (nags_support_count > 0 & targets_democracy == 1),
    
    # --- NEW: NAG democracy-targeting (already partially present, made consistent) ---
    nags_targets_democracy = as.integer(nags_support_count > 0 & targets_democracy == 1)
  )

# Step 3: Imputation (following GRAVE-D codebook protocol: linear within A-year, then regional-year median)
df_prep <- df_prep %>%
  group_by(COWcode_a) %>%
  arrange(year) %>%
  mutate(across(
    c(sidea_revisionist_domestic, v2exl_legitideol_a, v2exl_legitlead_a, v2exl_legitperf_a,
      oppsize_norm, log_capdist, politicalbandwidth),  # added new vars that may need imputation
    ~ zoo::na.approx(., na.rm = FALSE)
  )) %>%
  ungroup() %>%
  group_by(unregiona, year) %>%
  mutate(across(
    c(sidea_revisionist_domestic, v2exl_legitideol_a, v2exl_legitlead_a, v2exl_legitperf_a,
      oppsize_norm, log_capdist, politicalbandwidth),
    ~ if_else(is.na(.), median(., na.rm = TRUE), .)
  )) %>%
  ungroup()

# Step 4: Derive NAG ideology match variables (after imputation so distances are available)
df_prep <- df_prep %>%
  mutate(
    # Continuous match: lower distance = better ideological match (0–1 scale if normalized)
    nags_ideology_match_cont = case_when(
      nags_support_count > 0 ~ 1 - revisionism_distance, # invert distance (assuming 0–1 scale)
      TRUE ~ 0
    ),
    
    # Binary match: high-revisionist state + any support = presumed match
    nags_ideology_match = case_when(
      nags_support_count > 0 & revisionist_high == 1 ~ 1L,
      nags_support_count > 0 & !is.na(revisionism_distance) & revisionism_distance < 0.5 ~ 1L,
      TRUE ~ 0L
    ),
    
    # Optional subtype matches (uncomment if subtypes become central later)
    # nags_socialist_match  = if_else(nags_support_count > 0 & sidea_socialist_revisionist_domestic > 0.5, 1L, 0L),
    # nags_religious_match  = if_else(nags_support_count > 0 & sidea_religious_revisionist_domestic > 0.5, 1L, 0L),
  )

message("Post-prep dimensions: ", paste(dim(df_prep), collapse = " x "))

# Summary of key variables (expanded to cover new derivations)
df_prep %>%
  summarise(across(
    c(sidea_revisionist_domestic, revisionist_high, ideol_legit_ratio,
      oppsize_norm, log_capdist, bandwidth_visibility, bandwidth_proximity,
      high_cost_support, low_cost_domestic_support,
      opposition_training_int, opposition_dem_target_int,
      nags_support_count, nags_ideology_match, nags_targets_democracy,
      nags_training, nags_arms, nags_funds),
    list(n_missing = ~sum(is.na(.)), mean = ~mean(., na.rm = TRUE), median = ~median(., na.rm = TRUE)),
    .names = "{.col}_{.fn}"
  )) %>%
  print()

# Warning if key signaling vars still missing
if (any(is.na(df_prep$nags_targets_democracy))) {
  warning("Some nags_targets_democracy values NA – check support and target regime data.")
}
if (any(is.na(df_prep$opposition_training_int))) {
  warning("Some opposition_training_int values NA – check v2regoppgroupssize_a or nags_training.")
}

# Step 5: Assign prepared data globally for downstream scripts
assign("df_prep", df_prep, envir = .GlobalEnv)
message("Data preparation complete. 'df_prep' ready for modeling.")
message("Key derived vars added/updated: oppsize_norm, log_capdist, bandwidth_visibility, bandwidth_proximity, high_cost_support, opposition_training_int, opposition_dem_target_int")
