library(dplyr)
library(stringr)
library(rlang)
library(corrplot)
library(lmtest)
library(sandwich)
library(readr)
library(tidyr)

# Replace with your own working directory!!!
path <- "/Users/mikirin/Documents/GitHub/final-project-mikaela-xiao"
vehicle_pct <- read_csv(paste0(path, "/data/vehicle_pct.csv"))
tax_benefit <- read_csv(paste0(path,"/data/EV Credit_TF.csv"))

# Merge with tax benefit data
tax_vehicle_pct <- left_join(vehicle_pct, tax_benefit, by = c("State" = "State")) 

# Model 1: Basic regression with incentives only
model1 <- lm(PercentageClean ~ exp_incentive_hybrid + exp_incentive_EV, data = tax_vehicle_pct)
summary(model1)

# Model 2: Regression with state fixed effects
model2 <- lm(PercentageClean ~ exp_incentive_EV + exp_incentive_hybrid +
               factor(State), data = tax_vehicle_pct)
summary(model2)

# Model 3: Regression that controls for certain economic indicators

df <- read_csv(paste0(path, "/data/Econ Stats_BEA.csv"))

wide_df <- df %>%
  pivot_wider(
    names_from = Description,  
    values_from = Value       
  )

# Simplify variable names
wide_df <- wide_df %>%
  rename_with(~str_remove_all(.x, "\\s+\\d+$")) %>% # Remove trailing numbers
  rename_with(~str_extract(.x, "^[^\\(]+")) %>% # Keep only text before the first "(" 
  rename_with(~trimws(.x, which = "both")) # Remove leading and trailing spaces

# Remove columns with all NA values
wide_df <- wide_df[, colSums(is.na(wide_df)) != nrow(wide_df)]
names(wide_df)

# Compute correlations using pairwise complete observations
df.num <- wide_df[,-c(1,2)]
cor_matrix <- cor(df.num, use = "pairwise.complete.obs")

# Create a heatmap of the correlations
corrplot(cor_matrix, method = "color", type = "full", 
         order = "hclust", 
         tl.col = "black", tl.srt = 90, tl.cex = 0.5,
         diag = FALSE)

# Merge the dataframes
names(wide_df) <- gsub("\\s", "_", names(wide_df))
merged_df <- merge(tax_vehicle_pct, wide_df, by = c("State", "Year"))

model3 <- lm(PercentageClean ~ exp_incentive_EV + exp_incentive_hybrid + 
               Real_personal_income + Total_employment + Disposable_personal_income + 
               Regional_price_parities + Real_per_capita_PCE,
             data = merged_df)
summary(model3)
