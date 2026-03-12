# ==============================================================================
# 01_load_data.R
# Loads the master GRAVE-D dataset (with leaders and NAG dyadic integrations)
# and performs initial sanity checks
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

# Note: This script assumes the project root has been declared via here::i_am()
# in the sourcing script or master runner. If run standalone, declare location first.

# Declare this script's location relative to project root
here::i_am("R/shared/01_load_data.R")

# Load core packages (sourced from 00_packages.R if not already loaded)
# library(here)
# library(tidyverse)
# etc. – assume already loaded via sourcing 00_packages.R

# Define project-relative paths

data_path <- here("source_data","GRAVE_D_Master_with_Leaders.csv")

# Confirm project root and file location (helpful for Posit Cloud debugging)
message("Project root detected as: ", here::here())
message("Loading master dataset from: ", data_path)

# Load the data with readr for speed and type safety
df_raw <- readr::read_csv(
  data_path,
  col_types = cols(
    COWcode_a         = col_integer(),
    COWcode_b         = col_integer(),
    year              = col_integer(),
    # Core ideology and legitimation vars (add more as needed)
    sidea_revisionist_domestic = col_double(),
    v2exl_legitideol_a = col_double(),
    v2exl_legitlead_a  = col_double(),
    v2exl_legitperf_a  = col_double(),
    # Support group examples
    sidea_religious_support   = col_double(),
    # NAG dyadic vars (added from Dyadic Target-Supporter Dataset)
    nags_support_count        = col_integer(),
    nags_support_binary       = col_integer(),
    nags_ideology_match       = col_double(),
    nags_autocracy_goal       = col_integer(),
    nags_targets_democracy    = col_integer(),
    # Other key controls
    cinc_a                    = col_double(),
    cinc_b                    = col_double(),
    v2x_polyarchy_b           = col_double(),
    reg_trans_a               = col_double()
    # Add or adjust types based on your actual CSV structure
  ),
  na = c("", "NA", -99, -999)  # Common missing value codes in V-Dem/GRAVE-D
)

# After loading df_raw
df_raw <- df_raw %>%
  mutate(
    nags_targets_democracy = case_when(
      nags_support_count > 0 & targets_democracy == 1 ~ 1L,   # Support exists + B is democracy
      nags_support_count == 0 ~ 0L,                           # No support
      TRUE ~ 0L                                               # Support but B not democracy
    )
  )

# Then the summary will work
summary(df_raw %>% 
          dplyr::select(
            year,
            sidea_revisionist_domestic,
            v2exl_legitideol_a,
            nags_support_count,
            nags_targets_democracy
          ))

# Basic sanity checks
message("Dataset dimensions: ", paste(dim(df_raw), collapse = " x "))
message("Years covered: ", min(df_raw$year, na.rm = TRUE), " to ", max(df_raw$year, na.rm = TRUE))

# Quick summary of key variables for quick verification
summary(df_raw %>% 
          dplyr::select(
            year,
            sidea_revisionist_domestic,
            v2exl_legitideol_a,
            nags_support_count,
            nags_targets_democracy
          ))

# Optional: Check for expected NAG integration
if ("nags_support_count" %in% names(df_raw)) {
  message("NAG support variables detected – dyadic merge successful.")
} else {
  warning("NAG support variables not found – check data merge in prep step.")
}

# Assign to global environment for use in downstream scripts
assign("df_raw", df_raw, envir = .GlobalEnv)

message("Master dataset loaded successfully into 'df_raw'.")

