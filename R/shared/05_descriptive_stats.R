# =============================================================================
# 05_descriptive_stats.R
# Descriptive statistics, correlation matrix, and corrplots
# =============================================================================
here::i_am("R/shared/05_descriptive_stats.R")

# Load the shared pipeline
source(here("R/shared/04_trim_and_finalize.R"))

message("df_final loaded: ", nrow(df_final), " rows x ", ncol(df_final), " columns")

library(dplyr)
library(corrplot)
library(xtable)

# Variables to include
vars_for_desc <- c(
  "nags_support_count",
  "nags_training",
  "Num_S_TrainCamp",
  "sidea_revisionist_domestic",
  "revisionist_high",
  "revisionist_norm",
  "v2exl_legitideol_a",
  "legit_ideol_ratio",
  "v2regoppgroupssize_a",
  "oppsize_norm",
  "opposition_training_int",
  "nags_dem_target_support",
  "targets_democracy",
  "sidea_dynamic_leader",
  "politicalbandwidth",
  "bandwidth",
  "ln_capital_dist_km",
  "cinc_a_log",
  "cinc_b_log"
)

df_desc <- df_final %>%
  dplyr::select(any_of(vars_for_desc)) %>%
  drop_na()

message("Descriptive subset: ", nrow(df_desc), " rows x ", ncol(df_desc), " columns")

# ===================================================================
# Simple summary statistics using lapply (student-friendly method)
# ===================================================================
stats_list <- lapply(df_desc, function(x) {
  c(
    Mean = mean(x, na.rm = TRUE),
    SD   = sd(x, na.rm = TRUE),
    Min  = min(x, na.rm = TRUE),
    Max  = max(x, na.rm = TRUE),
    N    = sum(!is.na(x))
  )
})

desc_table <- as.data.frame(do.call(rbind, stats_list))
desc_table$Variable <- rownames(desc_table)
desc_table <- desc_table[, c("Variable", "Mean", "SD", "Min", "Max", "N")]
rownames(desc_table) <- NULL

# Round for readability
desc_table[, 2:5] <- round(desc_table[, 2:5], 3)

# Save as CSV and LaTeX
write.csv(desc_table, here("results/tables/descriptive_statistics.csv"), row.names = FALSE)

print(xtable(desc_table, digits = 3), 
      file = here("results/tables/descriptive_statistics.tex"), 
      floating = FALSE)

# ===================================================================
# Correlation matrix
# ===================================================================
cor_matrix <- cor(df_desc, use = "pairwise.complete.obs")

write.csv(round(cor_matrix, 3), here("results/tables/correlation_matrix.csv"), row.names = TRUE)

print(xtable(round(cor_matrix, 3), digits = 3),
      file = here("results/tables/correlation_matrix.tex"), floating = FALSE)

# ===================================================================
# Corrplots
# ===================================================================
png(here("results/plots/corrplot_full.png"), width = 1200, height = 1000, res = 120)
corrplot(cor_matrix, method = "color", type = "upper", order = "hclust",
         tl.cex = 0.8, addCoef.col = "black", number.cex = 0.7)
dev.off()

# Key variables plot (square matrix of only the key variables)
key_vars <- c("nags_support_count", "nags_training", "Num_S_TrainCamp",
              "sidea_revisionist_domestic", "v2exl_legitideol_a",
              "v2regoppgroupssize_a", "opposition_training_int")

df_key <- df_desc[, key_vars, drop = FALSE]
cor_key <- cor(df_key, use = "pairwise.complete.obs")

png(here("results/plots/corrplot_key.png"), width = 1300, height = 1100, res = 130)
corrplot(cor_key, 
         method = "color", 
         type = "upper", 
         order = "hclust",
         tl.cex = 0.75, 
         addCoef.col = "black", 
         number.cex = 0.65)
dev.off()

message("✅ Two full-sized square correlation plots created successfully!")