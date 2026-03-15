# =============================================================================
# 04_trim_and_finalize.R
# Final trimming to whitelist + production-ready cleaning + saving of slim RDS
#
# This script:
#   - Sources 03_derive_signaling_vars.R (which chains back to 02 and 01)
#   - Applies whitelist trim
#   - Performs final data cleaning (matrix→vector, logical→integer, Inf→NA)
#   - Saves slim df_final for modeling
#   - Cleans global environment
#
# Non-State Armed Groups and Ideological Signaling
# Tom Hanna, University of Houston
# Copyright © Tom Hanna, 2020–2026
# Licensed under CC BY-NC-SA 4.0
# Draft date: March 2026
# =============================================================================

here::i_am("R/shared/04_trim_and_finalize.R")
source(here::here("R/shared/03_derive_signaling_vars.R"))  # chains back to 02/01

message("[04] Starting trim and final cleaning...")

# ----------------------------------------------------------------------------
# 1. Define whitelist (add any new vars here if needed)
# ----------------------------------------------------------------------------
KEEP_VARS <- c(
  # Core identifiers
  "COWcode_a", "COWcode_b", "year", "dyad", "dyad_id",
  
  # NAG outcome variables (counts + binaries)
  "nags_support_count", "nags_training", "nags_arms", "nags_funds",
  "nags_troops", "nags_safe_haven", "nags_any_support",
  "nags_active_support", "nags_defacto_support",
  
  # Signaling interactions
  "high_cost_support", "low_cost_domestic_support",
  "opposition_training_int", "bandwidth_visibility", "bandwidth_proximity",
  
  # Ideology & legitimation
  "sidea_revisionist_domestic", "revisionist_high", "ideol_legit_ratio",
  "nags_ideology_match", "nags_ideology_match_cont",
  
  # Controls & transformations
  "politicalbandwidth", "securitybandwidth", "economicbandwidth", "bandwidth",
  "ln_capital_dist_km", "capital_dist_km", "log_capdist",
  "v2x_libdem_a", "targets_democracy", "cold_war", "war_on_terror",
  "cinc_a", "cinc_b", "sidea_winning_coalition_size",
  "revisionism_distance", "v2regoppgroupssize_a", "oppsize_norm",
  
  # Normalized versions (cleaned in next section)
  "legit_ideol_ratio_norm", "revisionist_norm",
  "politicalbandwidth_norm", "bandwidth_proximity_norm"
)

# Toggle: set to FALSE only for debugging
TRIM_DATASET <- TRUE

# ----------------------------------------------------------------------------
# 2. Trim to whitelist
# ----------------------------------------------------------------------------
if (TRIM_DATASET) {
  message("[04] Trimming to ", length(KEEP_VARS), " kept variables...")
  
  missing_in_data <- setdiff(KEEP_VARS, names(df_prep))
  if (length(missing_in_data) > 0) {
    warning("[04] These whitelisted variables are missing: ",
            paste(missing_in_data, collapse = ", "))
  }
  
  df_final <- df_prep |>
    select(any_of(KEEP_VARS))
  
  message("[04] After trim: ", ncol(df_final), " columns remaining")
} else {
  message("[04] TRIM_DATASET = FALSE → keeping all columns")
  df_final <- df_prep
}

# ----------------------------------------------------------------------------
# 3. Final data cleaning (matrix fix, logical→integer, Inf→NA)
#    One efficient mutate pass — memory/CPU friendly
# ----------------------------------------------------------------------------
message("[04] Applying final cleaning...")
df_final <- df_final |>
  mutate(
    # 1. Convert any _norm matrix/array back to plain numeric vectors
    across(ends_with("_norm"), ~as.vector(.)),
    
    # 2. Convert logical flags to integer 0/1 (for glm/stargazer compatibility)
    across(c(high_cost_support, low_cost_domestic_support, autocracy_a),
           as.integer),
    
    # 3. Replace Inf in bandwidth_proximity with NA
    bandwidth_proximity = if_else(is.infinite(bandwidth_proximity),
                                  NA_real_, bandwidth_proximity)
  ) |>
  # One-pass zero-fill for safety
  mutate(across(starts_with("nags_"), ~replace_na(., 0L)))

message("[04] Cleaning complete.")

# ----------------------------------------------------------------------------
# 4. Quick diagnostic (remove in production if you want)
# ----------------------------------------------------------------------------
message("[04] Post-cleaning summary of key variables:")
df_final |>
  summarise(across(c(ends_with("_norm"), high_cost_support,
                     low_cost_domestic_support, bandwidth_proximity),
                   list(class = ~class(.), max = ~max(., na.rm = TRUE)))) |>
  print()

# ----------------------------------------------------------------------------
# 5. Save production-ready dataset + tables
# ----------------------------------------------------------------------------
saveRDS(df_final, here("data", "df_final.rds"))
message("[04] Saved: data/df_final.rds (production version)")

# Optional CSV table of summary statistics (useful for QMD files)
write_csv(
  df_final |> summarise(across(everything(), list(mean = ~mean(., na.rm = TRUE),
                                                  sd   = ~sd(., na.rm = TRUE),
                                                  min  = ~min(., na.rm = TRUE),
                                                  max  = ~max(., na.rm = TRUE)))),
  here("results/tables", "df_final_summary.csv")
)
message("[04] Saved summary table: results/tables/df_final_summary.csv")

# ----------------------------------------------------------------------------
# 6. Aggressive environment cleanup
# ----------------------------------------------------------------------------
rm(list = setdiff(ls(), c("df_final", "KEEP_VARS", "TRIM_DATASET")))
gc()
message("[04] Global environment cleaned. Only df_final remains.")

message("[04_trim_and_finalize.R] Done.")