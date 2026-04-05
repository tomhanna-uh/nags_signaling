library(here)
library(dplyr)

# Tables
cat("=== RESULTS/TABLES ===\n")
tibble(
  file = list.files(here("results/tables"), full.names = TRUE)
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(file) / 1024
  ) %>%
  arrange(basename) %>%
  print(n = Inf)

# Plots
cat("\n=== RESULTS/PLOTS ===\n")
tibble(
  file = list.files(here("results/plots"), full.names = TRUE)
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(file) / 1024
  ) %>%
  arrange(basename) %>%
  print(n = Inf)


# Mediation tables and plots


# Tables
cat("=== RESULTS/5000_bootstrap ===\n")
tibble(
  file = list.files(here("results/5000_bootstrap"), full.names = TRUE)
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(file) / 1024
  ) %>%
  arrange(basename) %>%
  print(n = Inf)

library(here)
library(dplyr)

# Tables
cat("=== RESULTS/TABLES ===\n")
tibble(
  file = file.path("results/tables", list.files(here("results/tables")))
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(here(file)) / 1024
  ) %>%
  filter(startsWith(basename, "h10")) %>%
  arrange(basename) %>%
  print(n = Inf)


# Tables
cat("=== RESULTS/TABLES ===\n")
tibble(
  file = file.path("results/tables", list.files(here("results/tables")))
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(here(file)) / 1024
  ) %>%
  filter(startsWith(basename, "paper2_h9")) %>%
  arrange(basename) %>%
  print(n = Inf)

# Tables
cat("=== RESULTS/TABLES ===\n")
tibble(
  file = file.path("results/tables", list.files(here("results/tables")))
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(here(file)) / 1024
  ) %>%
  filter(startsWith(basename, "h9")) %>%
  arrange(basename) %>%
  print(n = Inf)

# Models
cat("=== RESULTS/models ===\n")
tibble(
  file = file.path("results/tables", list.files(here("results/models")))
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(here(file)) / 1024
  ) %>%
  filter(startsWith(basename, "h9")) %>%
  arrange(basename) %>%
  print(n = Inf)



# Tables
cat("=== RESULTS/TABLES ===\n")
tibble(
  file = file.path("results/tables", list.files(here("results/tables")))
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(here(file)) / 1024
  ) %>%
  arrange(basename) %>%
  print(n = Inf)

# plots
cat("=== quarto/plots ===\n")
tibble(
  file = file.path("results/tables", list.files(here("quarto/plots")))
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(here(file)) / 1024
  ) %>%
  arrange(basename) %>%
  print(n = Inf)


# plots
cat("=== results/models ===\n")
tibble(
  file = file.path("results/tables", list.files(here("results/models")))
) %>%
  mutate(
    basename = basename(file),
    size_kb = file.size(here(file)) / 1024
  ) %>%
  arrange(basename) %>%
  print(n = Inf)