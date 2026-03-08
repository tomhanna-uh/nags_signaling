# ==============================================================================
# 02_data_prep.R
# Prepares the loaded GRAVE-D master dataset: filtering to autocracies,
# imputation of missing values, derivation of key variables (revisionist indicators,
# legitimation ratios, risk proxies), and checks for NAG dyadic integration
#
# Non-State Armed Groups and Ideological Signaling:
# Autocratic Use of Non-State Armed Groups as Tools of Revisionist Signaling
# and Autocracy Promotion
#
# This script is part of the combined analysis for dissertation Papers 2 and 3.
# It builds on earlier work:
#   - April 2022: "Authoritarian Leadership Politics and Conflict Export:
#     Insurgency and terrorism as tools of autocratic ideology promotion"
#   - July 2024: "Ideology and Autocracy Promotion Through Non-State
#     Armed Groups: Draft" (shift from "transformative" to "revisionist"
#     framing and emphasis on rational two-level signaling)
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
#   - df_raw has been loaded via 01_load_data.R
#   - Project root is declared (via here::i_am() in the sourcing script or here)
# Run after sourcing 00_packages.R and 01_load_data.R

# Declare this script's location relative to project root
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

# Step 2: Derive simplified variables for analysis (revisionism, legit ratios, etc.)
df_prep <- df_prep %>%
  mutate(
    # Binary high-revisionist indicator (above median for quick subgroup analysis)
    revisionist_high = if_else(
      sidea_revisionist_domestic > median(sidea_revisionist_domestic, na.rm = TRUE),
      1L,
      0L
    ),
    
    # Ideological legitimation ratio (ideology vs. performance/personalist)
    ideol_legit_ratio = v2exl_legitideol_a / 
      (v2exl_legitideol_a + v2exl_legitlead_a + v2exl_legitperf_a + 1e-6),  # Avoid div-by-zero
    
    # Risk proxy for H14 (powerful target interaction)
    risk_powerful_target = cinc_b * revisionist_high,
    
    # Dyad identifier for fixed effects/panel models
    dyad_id = as.factor(paste(COWcode_a, COWcode_b, sep = "_")),
    
    # Regime age category (for H13 moderation)
    regime_new = if_else(reg_trans_a < 5, 1L, 0L),  # e.g., <5 years since transition
    
    # Optional: Subtype-specific revisionism (uncomment if testing separately)
    # socialist_revisionist_high = if_else(sidea_socialist_revisionist_domestic > 0.5, 1L, 0L),
    # religious_revisionist_high = if_else(sidea_religious_revisionist_domestic > 0.5, 1L, 0L)
  )

# Step 3: Imputation (following GRAVE-D codebook protocol: linear within A-year, then regional-year median)
df_prep <- df_prep %>%
  group_by(COWcode_a) %>%
  arrange(year) %>%
  mutate(across(
    c(sidea_revisionist_domestic, v2exl_legitideol_a, v2exl_legitlead_a, v2exl_legitperf_a),
    ~ zoo::na.approx(., na.rm = FALSE)
  )) %>%
  ungroup() %>%
  group_by(unregiona, year) %>%
  mutate(across(
    c(sidea_revisionist_domestic, v2exl_legitideol_a, v2exl_legitlead_a, v2exl_legitperf_a),
    ~ if_else(is.na(.), median(., na.rm = TRUE), .)
  )) %>%
  ungroup()

# Step 4: Final checks and warnings
message("Post-prep dimensions: ", paste(dim(df_prep), collapse = " x "))
message("Missing values in key vars after imputation:")
summary(df_prep %>% select(
  sidea_revisionist_domestic, revisionist_high, ideol_legit_ratio,
  nags_support_count, nags_ideology_match, nags_targets_democracy
))

if (any(is.na(df_prep$revisionist_high))) {
  warning("Some revisionist_high values still NA after imputation – check structural missing.")
}

# Step 5: Assign prepared data globally for downstream scripts
assign("df_prep", df_prep, envir = .GlobalEnv)

message("Data preparation complete. 'df_prep' ready for modeling.")
message("Key derived vars: revisionist_high, ideol_legit_ratio, risk_powerful_target, dyad_id, regime_new")