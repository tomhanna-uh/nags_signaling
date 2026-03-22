# =============================================================================
# R/paper2/10_h8_marginal_effects.R
#   H8 Post-estimation: Marginal Effects / Predicted Counts
#   Predicted nags_training across levels of revisionist ideology
#   Stratified by low vs. high dynamic leadership (mean ± 1 SD)
#   Uses stripped-down NB interaction model
# =============================================================================

here::i_am("R/paper2/10_h8_marginal_effects.R")

# ── 1. Load required packages (minimal set)
library(here)
library(dplyr)
library(ggplot2)
library(readr)   # for write_csv

# ── 2. Load the stripped-down model (from H8 script)
#    Assumes you saved it as h8_nb_interaction_stripped.rds
model_path <- here("results/models/h8_nb_interaction_stripped.rds")
if (!file.exists(model_path)) {
  stop("Stripped model not found. Run H8 script and uncomment saveRDS block.")
}
nb_h8_stripped <- readRDS(model_path)
message("Loaded stripped NB model from: ", model_path)

# ── 3. Create prediction grid
#    - Revisionism: fine grid 0 to 1 (adjust if scale differs)
#    - Dynamic leadership: mean ± 1 SD (mean ≈ 0.7175, SD = 1.264554)
#    - Other controls: held at their means (placeholders at 0; replace with actual)

revisionism_seq <- seq(0, 1, length.out = 101)   # 0–1 grid

dynamic_mean <- 0.7175
dynamic_sd   <- 1.264554
dynamic_low  <- dynamic_mean - dynamic_sd     # ≈ -0.547
dynamic_high <- dynamic_mean + dynamic_sd     # ≈ 1.982

dynamic_levels <- c("Low (mean - 1 SD)" = dynamic_low, 
                    "High (mean + 1 SD)" = dynamic_high)

# Prediction grid: all combinations
pred_grid <- expand.grid(
  sidea_revisionist_domestic = revisionism_seq,
  sidea_dynamic_leader = dynamic_levels,
  cinc_a_log = 0,               # placeholder; replace with actual mean if known
  cinc_b_log = 0,
  ln_capital_dist_km = 0,
  politicalbandwidth_norm = 0
) %>%
  mutate(dynamic_label = names(dynamic_levels)[match(sidea_dynamic_leader, dynamic_levels)])

# Note: Replace 0 placeholders with actual means from df_model if available, e.g.:
# cinc_a_log = mean(df_model$cinc_a_log, na.rm = TRUE), etc.

# ── 4. Generate predictions with SEs
preds <- predict(nb_h8_stripped, 
                 newdata = pred_grid, 
                 type = "response", 
                 se.fit = TRUE)

pred_grid <- pred_grid %>%
  mutate(
    predicted_count = preds$fit,
    se = preds$se.fit,
    lower = pmax(predicted_count - 1.96 * se, 0),  # floor at 0 for counts
    upper = predicted_count + 1.96 * se
  )

# ── 5. Save prediction grid as CSV (for tables/appendix/Quarto)
write_csv(
  pred_grid,
  here("results/tables/h8_marginal_effects_grid.csv")
)
message("Prediction grid saved to results/tables/h8_marginal_effects_grid.csv")

# ── 6. Plot 1: Predicted counts vs. revisionism, stratified by dynamic leadership
p1 <- ggplot(pred_grid, aes(x = sidea_revisionist_domestic, y = predicted_count,
                            color = dynamic_label, fill = dynamic_label,
                            group = dynamic_label)) +
  geom_line(linewidth = 1.2) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, color = NA) +
  scale_color_manual(values = c("Low (mean - 1 SD)" = "#1f77b4", 
                                "High (mean + 1 SD)" = "#ff7f0e")) +
  scale_fill_manual(values = c("Low (mean - 1 SD)" = "#1f77b4", 
                               "High (mean + 1 SD)" = "#ff7f0e")) +
  labs(
    title = "Predicted Count of Foreign NAGs Receiving Training Support",
    subtitle = "Conditional on Dynamic Leadership (mean ± 1 SD) and Revisionist Ideology",
    x = "Revisionist Domestic Ideology (Side A)",
    y = "Predicted Count (NB Model)",
    color = "Dynamic Leadership Level",
    fill = "Dynamic Leadership Level"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "top",
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(color = "grey50")
  )

ggsave(here("results/plots/h8_predicted_counts_by_dynamic_revisionism.png"), 
       p1, width = 10, height = 6, dpi = 300)
ggsave(here("results/plots/h8_predicted_counts_by_dynamic_revisionism.pdf"), 
       p1, width = 10, height = 6)

# ── 7. Plot 2: Log scale version (better for low counts / rare events)
p2 <- p1 + 
  scale_y_log10(limits = c(0.001, max(pred_grid$upper, na.rm = TRUE) * 1.1)) +
  labs(y = "Predicted Count (log10 scale)",
       title = "Predicted Count of Foreign NAGs Receiving Training Support (Log Scale)")

ggsave(here("results/plots/h8_predicted_counts_log_scale.png"), 
       p2, width = 10, height = 6, dpi = 300)
ggsave(here("results/plots/h8_predicted_counts_log_scale.pdf"), 
       p2, width = 10, height = 6)

# ── 8. Cleanup
rm(pred_grid, preds, p1, p2, nb_h8_stripped)
gc()

message("H8 marginal effects complete. Plots saved to results/plots/")