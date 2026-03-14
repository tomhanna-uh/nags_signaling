# ==============================================================================
# helpers.R
# Collection of reusable helper functions, custom utilities, and small tools
# used across multiple scripts in the project (e.g., custom model summaries,
# plotting helpers, imputation wrappers, robust SE functions, etc.)
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

# Note: Source this script early (after 00_packages.R) in any file that needs
# custom functions. Functions here should be general-purpose, well-documented,
# and reusable across data prep, modeling, and reporting scripts.

# Declare this script's location relative to project root
here::i_am("R/shared/helpers.R")

# ==============================================================================
# Example helper functions (add your own below as needed)
# ==============================================================================

# 1. Quick function to summarize models with robust SEs (cluster-robust common in dyadic data)
robust_summary <- function(model, cluster_var = NULL, vcov_type = "HC1") {
  if (is.null(cluster_var)) {
    # Standard robust SE
    model_summary <- broom::tidy(model, conf.int = TRUE, vcov = sandwich::vcovHC(model, type = vcov_type))
  } else {
    # Cluster-robust SE
    vcov_cl <- sandwich::vcovCL(model, cluster = cluster_var, type = vcov_type)
    model_summary <- broom::tidy(model, conf.int = TRUE, vcov = vcov_cl)
  }
  model_summary %>%
    mutate(across(where(is.numeric), ~ round(., 4))) %>%
    as_tibble()
}

# 2. Helper to create a formatted message with timestamp (useful for logging in Posit Cloud)
log_msg <- function(msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  message("[", timestamp, "] ", msg)
}

# 3. Wrapper for safe median imputation (handles all-NA groups gracefully)
safe_median_impute <- function(x) {
  if (all(is.na(x))) return(NA_real_)
  median(x, na.rm = TRUE)
}

# 4. Function to quickly check and report missingness in key variables
report_missing <- function(df, vars) {
  missing_summary <- df %>%
    summarise(across(all_of(vars), ~ sum(is.na(.)))) %>%
    pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
    mutate(pct_missing = round(n_missing / nrow(df) * 100, 2))
  
  log_msg("Missingness report:")
  print(missing_summary)
  invisible(missing_summary)
}

# 5. Placeholder for custom plotting theme (add ggplot2 theme elements here)
custom_theme <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5),
      axis.title = element_text(face = "bold"),
      panel.grid.minor = element_blank(),
      strip.background = element_rect(fill = "grey90"),
      strip.text = element_text(face = "bold")
    )
}

# ==============================================================================
# Add your own helper functions below as the project evolves
# Examples:
# - Custom stargazer/modelsummary wrapper for consistent table formatting
# - Function to compute ideological distance/mismatch scores
# - Wrapper for lavaan mediation models with bootstrapped SEs
# - Export function for clean CSV/LaTeX outputs
# ==============================================================================

message("Helpers loaded from helpers.R – custom functions ready for use.")