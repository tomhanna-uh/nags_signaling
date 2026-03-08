# ==============================================================================
# 00_packages.R
# Centralized loading of all required packages for reproducible analysis
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

# Note: Source this script at the beginning of all analysis files to ensure
# consistent package availability. Install missing packages only once via
# install.packages() in the console if needed.

# Step 1: Declare this script's location relative to project root
# Adjust the path string to match where THIS script lives in your structure
# (use forward slashes, relative from root)
here::i_am("R/shared/00_packages.R")  # <-- This is the key line!

# Load core packages
library(here)          # Project-relative paths (essential for Posit Cloud)
library(tidyverse)     # Core data wrangling and visualization (dplyr, ggplot2, tidyr, readr, purrr, stringr, forcats)

# Other packages we will definitely want (add more as models evolve)
library(readr)         # Fast CSV reading (already in tidyverse, but explicit for clarity)
library(modelsummary)  # Beautiful model tables (stargazer alternative)
library(stargazer)     # LaTeX/HTML tables for publication
library(MASS)          # Negative binomial models (glm.nb)
library(lavaan)        # Structural equation modeling / mediation
library(survival)      # Cox proportional hazards for leader survival
library(plm)           # Panel data models (fixed effects)
library(broom)         # Tidy model outputs
library(fs)            # File system operations (optional for dir_tree checks)

# Optional extras (uncomment as needed)
# library(lme4)        # Mixed-effects models if dyadic clustering required
# library(sandwich)    # Robust standard errors (cluster-robust)
# library(lmtest)      # Coefficient tests

message("Core packages loaded from 00_packages.R")