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
