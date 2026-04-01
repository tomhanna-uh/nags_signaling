# =============================================================================
# 04_trim_and_finalize.R
# Final trimming to whitelist + saving of production-ready RDS
# Aggressive Global Environment cleanup at the END
# =============================================================================
here::i_am("R/shared/04_trim_and_finalize.R")

source(here::here("R/shared/03_derive_signaling_vars.R")) # chains back to 02 and 01

message("[04] Starting trim and finalize...")

if (!exists("df_prep")) {
  stop("[04] df_prep not found. 03_derive_signaling_vars.R did not complete.")
}

# --- CONFIG: Toggles ---
TRIM_DATASET <- TRUE # FALSE = keep all columns
CLEAN_GLOBAL <- TRUE # FALSE = skip cleanup

# --- CONFIG: Whitelist of variables to KEEP ---
# (your original list + new triadic NAG variables added at the end)
KEEP_VARS <- c(
  "COWcode_a", "COWcode_b", "year", "dyad", "dyad_id", "unregiona",
  "nags_any_support", "nags_active_support", "nags_defacto_support",
  "nags_support_count", "nags_safe_haven", "nags_training", "nags_arms",
  "nags_funds", "nags_troops",
  "high_cost_support", "low_cost_domestic_support", "nags_dem_target_support",
  "nags_targets_democracy", "opposition_training_int", "opposition_dem_target_int",
  "bandwidth_visibility", "bandwidth_proximity",
  "sidea_revisionist_domestic", "revisionist_high",
  "legit_ideol_ratio", "ideol_legit_ratio",
  "v2exl_legitideol_a", "v2exl_legitlead_a", "v2exl_legitperf_a",
  "v2regoppgroupssize_a", "oppsize_norm",
  "sidea_party_elite_support", "sidea_religious_support",
  "sidea_ethnic_racial_support", "sidea_military_support",
  "sidea_rural_worker_support", "sidea_dynamic_leader",
  "politicalbandwidth", "securitybandwidth", "economicbandwidth", "bandwidth",
  "log_capdist", "capital_dist_km",
  "v2x_libdem_a", "autocracy_a", "targets_democracy", "v2x_libdem_b",
  "cold_war", "war_on_terror", "year",
  "cinc_a", "cinc_b", "sidea_winning_coalition_size",
  "revisionism_distance", "nags_ideology_match", "nags_ideology_match_cont",
  "ln_capital_dist_km", "legit_ideol_ratio_norm", "revisionist_norm",
  "politicalbandwidth_norm", "bandwidth_proximity_norm",
  "cinc_a_log", "cinc_b_log",    # V-Dem subtype legitimation probabilities (for H4 sub-type alignment)
  "v2exl_legitideolcr_0_a", "v2exl_legitideolcr_1_a", "v2exl_legitideolcr_2_a",
  "v2exl_legitideolcr_3_a", "v2exl_legitideolcr_4_a",
  "v2exl_legitideolcr_0_b", "v2exl_legitideolcr_1_b", "v2exl_legitideolcr_2_b",
  "v2exl_legitideolcr_3_b", "v2exl_legitideolcr_4_b",
  
  # NEW triadic NAG aspiration variables (added for H5 and H4 corrections)
  "nags_nondem_objective", "nags_auth_support",
  "nags_ethnonationalist", "nags_religious", "nags_leftist",
  "nags_obj_topple", "nags_obj_regimechange", "nags_obj_autonomy",
  "nags_obj_secession", "nags_obj_policy", "nags_obj_other",
  # leader survival and tenure variables
  "leader_survived_year",
  "leader_tenure_years",
  "leader_tenure_current_year",
  "leader_exit_year",
  "leader_exit_event",
  "time_at_risk","tenure",
  # training camp variables
  "Num_DS_TrainCamp","Num_S_TrainCamp")


# --- Trim logic ---
if (TRIM_DATASET) {
  message("[04] Trimming to ", length(KEEP_VARS), " kept variables...")
  
  missing_in_data <- setdiff(KEEP_VARS, names(df_prep))
  if (length(missing_in_data) > 0) {
    warning("[04] Missing whitelisted variables: ", paste(missing_in_data, collapse = ", "))
  }
  
  available_keep <- intersect(KEEP_VARS, names(df_prep))
  df_final <- df_prep[, available_keep, drop = FALSE]
  
  message("[04] After trim: ", ncol(df_final), " columns remaining")
  message("[04] Remaining columns:")
  print(names(df_final))
} else {
  message("[04] TRIM_DATASET = FALSE → keeping all columns")
  df_final <- df_prep
}

# ----------------------------------------------------------------------------
# --- FINAL DATA CLEANING (after trim, before save)
#     Fixes matrix/array scaled variables, logical→integer, Inf→NA
# ----------------------------------------------------------------------------
message("[04] Applying final cleaning (matrix fix + logical→integer + Inf→NA)...")
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

message("[04] Final cleaning complete.")

# --- Final save ---
saveRDS(df_final, here("data", "GRAVE_D_Master_with_Leaders_nags_signals_trimmed.rds"))
message("[04] Final trimmed dataset saved: GRAVE_D_Master_with_Leaders_nags_signals_trimmed.rds")

# --- Aggressive Global Environment cleanup + gc() at the END ---
if (CLEAN_GLOBAL) {
  message("[04] Aggressive Global Environment cleanup...")
  
  # Force gc before removal
  gc(verbose = FALSE, full = TRUE)
  
  all_objs <- ls(envir = .GlobalEnv)
  
  # Explicitly KEEP only these (add any functions/configs you need)
  KEEP_EXPLICIT <- c(
    "df_final", # the trimmed modeling data
    "KEEP_VARS", # whitelist for future edits
    "TRIM_DATASET",
    "CLEAN_GLOBAL"
  )
  
  # Also keep anything that is a function
  keep_functions <- all_objs[sapply(all_objs, function(x) is.function(get(x, envir = .GlobalEnv)))]
  
  # Combine
  keep_final <- unique(c(KEEP_EXPLICIT, keep_functions))
  
  # Objects to remove: everything else
  remove_objs <- setdiff(all_objs, keep_final)
  
  if (length(remove_objs) > 0) {
    message("[04] Removing ", length(remove_objs), " objects (including df_raw, df_prep, temps)...")
    rm(list = remove_objs, envir = .GlobalEnv)
    
    # Final gc after removal
    gc(verbose = FALSE, full = TRUE)
    message("[04] Garbage collection complete.")
  } else {
    message("[04] No objects to remove.")
  }
  
  # Final status
  message("[04] Final Global Environment objects: ", length(ls(envir = .GlobalEnv)))
  message("[04] Remaining: ", paste(ls(envir = .GlobalEnv), collapse = ", "))
} else {
  message("[04] CLEAN_GLOBAL = FALSE → skipping cleanup")
}
message("[04] Done. Environment cleaned. Ready for modeling scripts.")