source(here::here("R/shared/02_data_prep.R"))  # ensures spine loaded

master <- master |>
  mutate(
    autocracy_a = v2x_libdem_a < 0.5,
    nags_dem_target_support = nags_any_support * targets_democracy,
    legit_ideol_ratio = v2exl_legitideol_a / (v2exl_legitideol_a + v2exl_legitlead_a + v2exl_legitperf_a),
    oppsize_norm = scale(v2regoppgroupssize_a),
    high_cost_support = nags_troops | nags_training | nags_arms,
    low_cost_domestic_support = (nags_funds | nags_safe_haven) & !nags_dem_target_support,
    cold_war = year <= 1991,
    war_on_terror = year >= 2001,
    opposition_training_int = oppsize_norm * nags_training,
    bandwidth_visibility = politicalbandwidth * nags_training
  )

saveRDS(master, here("data", "GRAVE_D_Master_with_Leaders_nags_signals.rds"))
