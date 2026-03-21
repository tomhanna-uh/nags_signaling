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

here::i_am("R/shared/02_data_prep.R")

source(here::here("R/shared/01_load_data.R"))  # Loads df_raw

message("Starting data preparation from raw GRAVE-D master dataset...")

if (!exists("df_raw")) {
  stop("df_raw not found. 01_load_data.R did not complete successfully.")
}

# Step 1: Filter to autocracies (v2x_libdem_a < 0.5)
df_prep <- df_raw |>
  filter(v2x_libdem_a < 0.5)

message("Filtered to autocracies: ", nrow(df_prep), " rows remaining")

# Step 2: Imputation of missing values (simple mean/median for continuous, mode for categorical)
# (your original imputation logic stays here; add any new variables if needed)

# Step 3: Derive revisionist indicators (from V-Dem legitimation)
df_prep <- df_prep |>
  mutate(
    autocracy_a = v2x_libdem_a < 0.5,
    
    # Overall revisionist legitimation
    sidea_revisionist_domestic = v2exl_legitideol_a,
    
    # Subtype indicators (direct from v2exl_legitideolcr_*)
    sidea_nationalist_revisionist_domestic = v2exl_legitideolcr_0_a,
    sidea_socialist_revisionist_domestic   = v2exl_legitideolcr_1_a,
    sidea_reactionary_revisionist_domestic = v2exl_legitideolcr_2_a,
    sidea_separatist_revisionist_domestic  = v2exl_legitideolcr_3_a,
    sidea_religious_revisionist_domestic   = v2exl_legitideolcr_4_a,
    
    # High revisionist flag (e.g., above median or threshold)
    revisionist_high = if_else(sidea_revisionist_domestic > median(sidea_revisionist_domestic, na.rm = TRUE), 1L, 0L)
  )

# Diagnostic: confirm subtype variables are present
message("Summary of V-Dem subtype legitimation variables (should be 0–1):")
df_prep |>
  summarise(across(
    starts_with("sidea_") & contains("revisionist_domestic"),
    list(mean = ~mean(., na.rm = TRUE), n_missing = ~sum(is.na(.))),
    .names = "{.col}_{.fn}"
  )) |>
  print()

# Step 4: Derive NAG ideology match variables (using triadic identity data)
df_prep <- df_prep |>
  mutate(
    # Continuous match: weighted alignment score (0–1 scale)
    nags_ideology_match_cont = case_when(
      nags_support_count > 0 ~ pmin(
        (sidea_nationalist_revisionist_domestic * nags_ethnonationalist +
           sidea_socialist_revisionist_domestic   * nags_leftist +
           sidea_religious_revisionist_domestic   * nags_religious) / 
          (sidea_nationalist_revisionist_domestic + sidea_socialist_revisionist_domestic +
             sidea_religious_revisionist_domestic + 1e-6),
        1
      ),
      TRUE ~ 0
    ),
    
    # Binary match: leader subtype high + matching NAG identity
    nags_ideology_match = case_when(
      nags_support_count > 0 & (
        (sidea_nationalist_revisionist_domestic > 0.5 & nags_ethnonationalist == 1) |
          (sidea_socialist_revisionist_domestic   > 0.5 & nags_leftist == 1) |
          (sidea_religious_revisionist_domestic   > 0.5 & nags_religious == 1)
      ) ~ 1L,
      TRUE ~ 0L
    )
  )

# Step 5: Other signaling variables (fixed log_capital_dist_km alias)
df_prep <- df_prep |>
  mutate(
    oppsize_norm = scale(v2regoppgroupssize_a),
    log_capdist = log(capital_dist_km + 1),
    log_capital_dist_km = log_capdist,  # alias for consistency in bandwidth_proximity
    bandwidth_visibility = politicalbandwidth / (politicalbandwidth + 1e-6),
    bandwidth_proximity = 1 / (log_capital_dist_km + 1e-6),
    high_cost_support = nags_training + nags_arms + nags_funds + nags_troops,
    low_cost_domestic_support = nags_safe_haven,
    opposition_training_int = oppsize_norm * nags_training,
    opposition_dem_target_int = oppsize_norm * nags_targets_democracy
  )

# Summary diagnostics
message("Post-derivation summary of key signaling variables:")
df_prep |>
  summarise(across(
    c(nags_ideology_match, nags_ideology_match_cont,
      oppsize_norm, log_capdist, log_capital_dist_km, bandwidth_visibility, bandwidth_proximity,
      high_cost_support, low_cost_domestic_support,
      opposition_training_int, opposition_dem_target_int,
      nags_support_count, nags_targets_democracy,
      nags_training, nags_arms, nags_funds),
    list(n_missing = ~sum(is.na(.)), mean = ~mean(., na.rm = TRUE), median = ~median(., na.rm = TRUE)),
    .names = "{.col}_{.fn}"
  )) |>
  print()

# Warning if key signaling vars still missing
if (any(is.na(df_prep$nags_targets_democracy))) {
  warning("Some nags_targets_democracy values NA – check support and target regime data.")
}
if (any(is.na(df_prep$opposition_training_int))) {
  warning("Some opposition_training_int values NA – check v2regoppgroupssize_a or nags_training.")
}
if (any(is.na(df_prep$nags_ideology_match))) {
  warning("Some nags_ideology_match values NA – check triadic NAG identity merge.")
}

# Step 6: Assign prepared data globally for downstream scripts
assign("df_prep", df_prep, envir = .GlobalEnv)
message("Data preparation complete. 'df_prep' ready for modeling.")
message("Key derived vars added/updated: oppsize_norm, log_capdist, log_capital_dist_km, bandwidth_visibility, bandwidth_proximity, high_cost_support, low_cost_domestic_support, opposition_training_int, opposition_dem_target_int, nags_ideology_match, nags_ideology_match_cont")