library(tidyverse)
library(ggplot2)
library(dplyr)
library(sf)
library(spData)
library(gridExtra)
library(readr)

# Replace with your own working directory!!!
path <- "/Users/mikirin/Documents/GitHub/final-project-mikaela-xiao"

## First plot: (Static) Clean Vehicle Tax Benefit by State
# Load the tax benefit dataset
tax_benefit <- read_csv(paste0(path,"/data/EV Credit_TF.csv"))

# Load US states spatial data
data(us_states)

# Merge the vehicle_pct dataset with the spatial data
us_tax_benefit <- left_join(us_states, tax_benefit, by = c("NAME" = "State"))

# Convert to sf object for plotting
us_tax_benefit_sf <- st_as_sf(us_tax_benefit)

ggplot() +
  geom_sf(data = us_tax_benefit_sf, aes(fill = exp_incentive_avg)) +
  scale_fill_gradient2(low = "red", mid = "white", high = "darkblue", midpoint = 0) + 
  labs(title = "Clean Vehicle Tax Benefit by State", 
       fill = "",
       caption = "Source: US Tax Foundation") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

## Second plot: (Static) Percentage of Clean Vehicles for Selected States by Time
# Load the vehicle population dataset
vehicle_summary <- read_csv(paste0(path,"/data/Vehicle Registration_AFDC.csv"))

# Compute the quantity and percentage of clean vehicles
vehicle_pct <- vehicle_summary %>%
  group_by(State, Year) %>%
  summarise(
    TotalVehicles = sum(Count), # Total number of vehicles
    CleanVehicles = sum(Count * Clean), # Number of clean vehicles
    NotCleanVehicles = sum(Count * (1 - Clean)) # Number of not clean vehicles
  ) %>%
  ungroup() %>%
  mutate(
    CleanVehicles = CleanVehicles,
    NotCleanVehicles = NotCleanVehicles,
    PercentageClean = (CleanVehicles / TotalVehicles) * 100,
    PercentageNotClean = (NotCleanVehicles / TotalVehicles) * 100
  ) 

vehicle_pct_2022 <- vehicle_pct %>%
  filter(Year == 2022)

# Load US states spatial data
data(us_states)

# Merge the vehicle_pct dataset with the spatial data
us_vehicles_2022 <- left_join(us_states, vehicle_pct_2022, by = c("NAME" = "State"))

# Convert to sf object for plotting
us_vehicles_2022_sf <- st_as_sf(us_vehicles_2022)

ggplot() +
  geom_sf(data = us_vehicles_2022_sf, aes(fill = PercentageClean)) +
  scale_fill_gradient(low = "white", high = "darkgreen") + 
  labs(title = "Percentage of Clean Vehicles by State as of 2022 (%)", 
       fill = element_blank(),
       caption = "Source: US Department of Energy") +
  theme_void() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Histogram of numeric variable distribution

wide_vehicle <- vehicle_summary %>%
  select(-5) %>%
  pivot_wider(
    names_from = Type,  
    values_from = Count       
  )

create_histograms_by_year <- function(data, year) {
  # Filter the data for the specified year
  year_data <- data %>%
    filter(Year == year) %>%
    select(-c(State, Year)) # Remove State and Year columns for plotting
  
  # Get the variable names for plotting
  cols <- names(year_data)
  
  # Initialize an empty list to store the plots
  plot_list <- list()
  
  # Loop through the variables and create a histogram for each
  for (col in cols) {
    p <- ggplot(year_data, aes(x = .data[[col]])) + 
      geom_histogram(aes(y = after_stat(density)), bins = 50, color = "skyblue3", fill = "lightblue") + 
      geom_density(color = "skyblue4") + 
      theme_minimal()
    plot_list[[col]] <- p
  }
  
  # Arrange the plots into a grid
  do.call(grid.arrange, c(plot_list, ncol = 3))
}

# Use the function to create histograms for a specific year
create_histograms_by_year(wide_vehicle, 2022)


