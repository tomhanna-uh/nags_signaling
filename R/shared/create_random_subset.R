# Assuming df is your dataframe with columns: dyad_id, year
library(dplyr)

# 1. Filter for the target years (1999-2001)
sub_data <- df_final %>% filter(year %in% 1999:2001)

# 2. Get unique dyad IDs
unique_dyads <- unique(sub_data$dyad)

# 3. Randomly select 20 dyads
set.seed(123) # Set seed for reproducibility
selected_dyads <- sample(unique_dyads, 10)

# 4. Subset the original dataframe to keep only the 10 dyads
final_df <- sub_data %>% filter(dyad %in% selected_dyads)

# 5. Save the subset
write.csv(final_df, "subset_dyads.csv")


# Run this after loading your subset
names(final_df)
# or if it's a data.frame called df_subset:
dplyr::glimpse(final_df)