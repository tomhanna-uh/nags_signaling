# Coding Rules – nags_signaling Project

**Last updated:** March 2026

These rules ensure memory and CPU efficiency, clean environment management, reproducibility, small file sizes, and an iterative, ground-up development process across all modeling scripts in the repository.

1. **Comment thoroughly**  
   Comment each major section of every script, with special attention to tidyverse functions, package-specific calls, and any non-obvious logic or derivation steps.

2. **Prioritize efficiency**  
   Strive for memory and CPU efficiency in all code (e.g., use vectorized operations, avoid unnecessary copies, prefer `dplyr` over base R loops where appropriate).

3. **Aggressive cleanup**  
   Remove unused objects from the environment immediately after use — after each major section, between models in multi-model scripts, and at script end. Use `rm()` and `gc()` liberally.

4. **Path management**  
   Every script must include a `here::i_am()` call near the top, using the correct relative path and filename (e.g., `here::i_am("R/paper2/08_h7_legitimation_ratios_qp_nb.R")`).

5. **Output saving (tables & plots)**  
   Save tables and plots consistently:  
   - For every model, save tables in `results/tables/` including at least CSV (machine-readable coefficients, SEs, z/t-stats, p-values, conf.int, fit stats like dispersion/deviance/AIC/BIC), LaTeX (via `stargazer` or `modelsummary` for manuscript/Quarto), and plain text (quick review). Multiple formats per model are encouraged.  
   - Any plots that require the full model object in memory must be generated and saved within the same script that fits the model. Save plots to `results/plots/`.

6. **Model saving policy**  
   Models should not be saved as full RDS files.  
   Instead:  
   - Save coefficients, standard errors, z/t-statistics, p-values, confidence intervals, and key model fit statistics (e.g., dispersion, deviance, AIC/BIC if applicable) as CSV files in `results/tables/`.  
   - For LaTeX/Quarto-friendly output, also save formatted tables via `stargazer` or `modelsummary` in `results/tables/` (`.tex`, `.txt`, or `.md` as needed).  
   - When post-estimation tasks (e.g., predicted values, marginal effects, simulations, or replication of `predict()`/`simulate()`) are anticipated for a specific model, save a stripped-down minimal RDS version of the model object in `results/models/` (e.g., `h7_qp_ideol_stripped.rds`).  
     - Strip unnecessary components before saving: remove `data`, `residuals`, `fitted.values`, `effects`, `qr`, `linear.predictors`, `deviance.resids`, `prior.weights`, `weights`, and any other large vectors or structures not required for prediction or basic reuse.  
     - Use strong compression: `saveRDS(..., compress = "xz")`.  
     - These stripped files should be small (typically <5–20% of full model size) and only created when justified by downstream needs (e.g., plotting marginal effects in a later script).  
   - Aggressively clean the full model object from memory immediately after extraction/stripping (Rule 3).  
   - Never save the complete, unmodified model object as RDS.

7. **Script headers**  
   Standardize script headers using the format:

=============================================================================
filename.R   (descriptive title)
=============================================================================


8. **Variable labels in output**  
Use friendly, descriptive English labels for variables in tables, plots, and summaries (e.g., "Ideological Legitimation Share (1-SD, Winsorized)" instead of `legit_ideol_ratio_norm`). Ask for label suggestions if unsure.

9. **Iterative, ground-up development**  
Build and finalize scripts iteratively from the ground up. Ensure each base script (or major revision) is fully working and tested before layering additional models, post-estimation, or pipeline steps on top. Modifications to existing scripts are allowed, but only after confirming the core functionality remains intact.

10. **Avoid namespace pollution / breakage**  
 If a script requires a custom function or helper that conflicts with shared code or prior scripts, define it internally within that script only (or with a unique name). Delete or isolate it after successful execution to prevent breaking downstream or parallel scripts (e.g., when running `runall.R` for Quarto rendering).

11. **Preferred friendly variable labels**  
 Use consistent, readable English names in output tables/plots. See Appendix for common mappings. Expand as needed.

12. **Reference data_summary.md**  
 Always consult https://github.com/tomhanna-uh/nags_signaling/blob/main/data_summary.MD before writing or modifying scripts. Verify variable names, types, ranges, and summary statistics; make efficiency adjustments based on documented sparsity, NA patterns, or extreme values.

13. **No unnecessary changes**  
 Once a fix, convention, or implementation is established and working correctly, do not alter it unless explicitly required for a new analytical goal.

14. **Modeling script template**  
 Every modeling script must begin with:

=============================================================================
[filename.R]   (descriptive title, e.g., 08_h7_legitimation_ratios_qp_nb.R)
=============================================================================

here::i_am("R/[subfolder]/[filename.R]")  # replace with actual path

Force clean load of trimmed + finalized data (Rule 3)

source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")


### Appendix: Preferred Friendly Variable Labels (Starter List)

This is a starting point based on common variables in the project. Edit/add as needed.

- `sidea_revisionist_domestic` → "Revisionist Domestic Ideology (Side A)"  
- `sideb_revisionist_domestic` → "Revisionist Domestic Ideology (Side B)"  
- `legit_ideol_ratio_norm` → "Ideological Legitimation Share (1-SD, Winsorized)"  
- `legit_personalist_ratio_norm` → "Personalist Legitimation Share (1-SD, Winsorized)"  
- `v2exl_legitideol_a` → "Ideological Legitimation Reliance (Side A)"  
- `v2exl_legitlead_a` → "Personalist/Leader Legitimation Reliance (Side A)"  
- `nags_training` → "Count of Foreign NAGs Receiving Military Training Support"  
- `nags_arms` → "Count of Foreign NAGs Receiving Arms Support"  
- `nags_funds` → "Count of Foreign NAGs Receiving Financial Support"  
- `nags_any_support` → "Any Support Provided to Foreign NAGs (Binary)"  
- `cinc_a_log` → "Side A Capabilities (log)"  
- `cinc_b_log` → "Side B Capabilities (log)"  
- `ln_capital_dist_km` → "Log Distance to Capital (km)"  
- `politicalbandwidth_norm` → "Normalized Political Bandwidth"  
- `autocracy_a` → "Autocracy (Side A)"  
- `sidea_dynamic_leader` → "Dynamic/Personalist Leadership (Side A)"  
- `nags_religious`, `nags_leftist`, etc. → "NAG Ideology: Religious / Leftist / ..."  

(Continue expanding for subtypes, opposition variables, etc.)



