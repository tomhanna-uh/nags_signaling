# ==============================================================================
# 00_run_all.R
# Master runner script to execute the full analysis pipeline in sequence
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

# Note: This script sources all major analysis steps in logical order.
# Run this file interactively or via Rscript to reproduce the full pipeline.
# It assumes:
#   - Project root is correctly detected (via here::i_am() in sourced scripts)
#   - Data file exists in data/
#   - All required packages are installed (source 00_packages.R first if needed)

# Declare this script's location relative to project root
here::i_am("R/shared/00_run_all.R")

# Step 0: Load all packages (centralized)
source(here::here("R", "shared", "00_packages.R"))

# Step 1: Load raw data
source(here::here("R", "shared", "01_load_data.R"))

# Step 2: Data preparation, imputation, derivation, and NAG merge checks
source(here::here("R", "shared", "02_data_prep.R"))

# Step 3: Tier 1 models (baseline pattern – support count/probability)
source(here::here("R", "paper2", "03_h1_h3_count.R"))

# Step 4: Tier 2 models (alignment, legitimation mix, visibility/mismatch)
source(here::here("R", "paper2", "04_h4_h7_alignment.R"))

# Step 5: Tier 3 models (mediation, moderation, survival, risk balancing)
source(here::here("R", "shared", "05_h8_h14_mechanisms.R"))

# Step 6: Generate consolidated tables and outputs
source(here::here("R", "shared", "06_reporting_tables.R"))

# Optional: Paper 3-specific extensions (uncomment when ready)
# source(here::here("R", "paper3", "07_h10_survival_dual.R"))
# source(here::here("R", "paper3", "08_h14_risk_opposition.R"))

# Final confirmation
message("Full analysis pipeline completed successfully.")
message("Check output files in output/ or rendered Quarto docs for results.")