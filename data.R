library(tidyverse)
library(rvest)

# replace with your own working directory!!!
setwd("/Users/liangxiao/Desktop/Y2 Winter/R II/Final Project/final-project-mikaela-xiao")

# Dataset 1: Light-Duty Vehicle Registration Counts by State and Fuel Type, from Alternative Fuels Data Center ----

# Alternative: directly get access to the archived data by applying:
### df_vehicle <- read.csv("data/raw/Vehicle Registration.csv") ###
# And jump to line 52
scrape_vehicle <- function(year) {
  url <- paste0("https://afdc.energy.gov/vehicle-registration?year=", year)
  html <- read_html(url)
  
  # scrape tables
  table_body <- html |> 
    html_elements("tbody") |> 
    html_table()
  
  table_all <- table_body[[1]]
  
  # scrape table headers (variable names)
  tabel_names <- html |> 
    html_elements(".sub-header") |> 
    html_elements("th") |> 
    html_text2()
  
  # rename table columns with variable names
  names(table_all) <- tabel_names
  
  table_all <- table_all |> 
    mutate(Year = year) |> # mutate a year variable
    relocate(Year, .after = State) |> 
    mutate(across(!State, \(x) str_remove_all(x, ",")), # remove "," in numeric
           across(!State, \(x) as.numeric(x)))
  
  return(table_all)
}

# loop
# setting
df_vehicle <- list()
years <- 2016:2022

for (i in years) {
  df_vehicle[[i-2015]] <- scrape_vehicle(i) # store all tables into a list
}

df_vehicle <- reduce(df_vehicle, full_join) # reduce the list

# If you load the archived data, start from here!!!
df_vehicle_long <- df_vehicle |> # transform the data into longer form
  pivot_longer(cols = 3:14,
               names_to = "Type",
               values_to = "Count") |> 
  mutate(Clean = if_else(!Type %in% c("Gasoline", "Diesel", "Unknown Fuel"), 1, 0)) # mutate a variable indicating clean energy or not

write_csv(df_vehicle_long, "data/Vehicle Registration_AFDC.csv")

# Dataset 2: State Electric Vehicle Tax Credits and Registration Fees, from Tax Foundation ----

df_tax <- read_csv("data/raw/Electric Vehicles EV Taxes by State Details Analysis.csv")

# write a function that replace, for instance, "750-7500" with their mean "4125"
replace_with_mean <- function(string) {
  nums <- as.numeric(str_split(string, "-")[[1]])
  mean(nums)
}

# write a function that replace, for instance, "Up to 2400" with its half "1200"
replace_with_half <- function(string) {
  nums <- as.numeric(str_extract(string, "\\b\\d+\\b"))
  nums <- nums / 2
}

# clean the numeric data
df_tax_clean <- df_tax |> 
  mutate(across(!State, \(x) str_remove_all(x, ",")), # remove ","
         across(!State, \(x) str_remove_all(x, "\\s*\\([a-z]\\)")), # remove " (*)"
         across(!State, ~ str_replace_all(.x, "\\b(\\d+)-(\\d+)\\b", \(x) replace_with_mean(x))), # detect "*-*" and replace with mean
         across(!State, \(x) replace_with_half(x))) |> # detect "Up/up to *" and replace with half
  mutate(across(!State, \(x) as.numeric(x)),
         across(!State, \(x) replace_na(x, 0))) # replace NA with 0

# according to Bureau of Transportation Statistics (https://www.bts.gov/content/average-age-automobiles-and-trucks-operation-united-states), the average age of light vehicles in US is 12.5 years, we will use this as the standard magnifying power of registration fee

df_incentive <- df_tax_clean |> 
  mutate(exp_incentive_avg = `EV Purchase Tax Credit` - 12.5 * 1/2 * (`Additional EV Annual Registration Fee` + `Additional Hybrid Annual Registration Fee`),
         exp_incentive_EV = `EV Purchase Tax Credit` - 12.5 * `Additional EV Annual Registration Fee`,
         exp_incentive_hybrid = `EV Purchase Tax Credit` - 12.5 * `Additional Hybrid Annual Registration Fee`) |> 
  select(State, starts_with("exp"))

write_csv(df_incentive, "data/EV Credit_TF.csv")

# Dataset 3: State annual summary statistics: personal income, GDP, consumer spending, price indexes, and employment, from Bureau of Economic Analysis ----

df_econ <- read_csv("data/raw/Table.csv", skip = 3)

df_econ <- df_econ |> 
  select(GeoName, Description, 23:29) |> 
  filter(!is.na(GeoName)) |> 
  rename(State = GeoName) |> 
  mutate(across(!c(State, Description), \(x) na_if(x, "(NA)")), # replace "(NA)" with NA
         across(!c(State, Description), \(x) as.numeric(x)))

# transform the data into longer form
df_econ_long <- df_econ |> 
  pivot_longer(cols = !c(State, Description),
               names_to = "Year",
               values_to = "Value") |> 
  filter(State != "United States")

write_csv(df_econ_long, "data/Econ Stats_BEA.csv")
