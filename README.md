DAP II Final Project
================

Mikaela Lin, Xiao Liang

Date Created: 2/15/2024

Date Modified: 3/4/2024

Required R packages: tidyverse, rvest, tidytext, textdata, udpipe, SnowballC, igraph, ggraph, ggplot2, dplyr, shiny, plotly, DT, sf, spData, gridExtra, stringr, rlang, corrplot, lmtest, sandwich,readr, tidyr

Version of R used: 2023.12.1+402

# Summary of code:

## 1. *data.R*

In this script we load and wrangle three data sets from either folder "data/raw" or by web scraping, then save then in folder "data" for furthering research.

### 1.1 *Vehicle Registration_AFDC.csv*

For data set 1, we scrape the tables of light-duty vehicle registration counts by state and fuel type from https://afdc.energy.gov/vehicle-registration?year=. Since each spreadsheet contains data within one year, we need to loop through 2016-2022 for the entire data set. 

If internet is not available, you may also refer to line 9-11 for guidelines to load the archived data *data/raw/Vehicle Registration.csv*. 

For data wrangling, we:
- remove the comma in each numeric cell as delimiter
- transform the structure to longer so that columns indicating fuel types are integrated into one variable

After wrangling, we save the clean data set as *data/Vehicle Registration_AFDC.csv*. It contains multiple rows and 5 columns.
- Row: each stands for one state-year-type observation
- Column: 
  - State
  - Year
  - Type: fuel type
  - Count: number of vehicle registrations in the particular state-year-type observation
  - Clean: dummy variable for clean fuel type, 0 for gasoline, diesel and unknown fuel, 1 otherwise
  
### 1.2 *EV Credit_TF.csv*

For data set 2, we read *data/raw/Electric Vehicles EV Taxes by State Details  Analysis.csv* downloaded from https://taxfoundation.org/data/all/state/electric-vehicles-ev-taxes-state/. The data set contains state electric vehicle tax credits and registration fees in US Dollars.

For data wrangling, we:
- replace scope value with the mean, for instance, replace "750-7500" with the mean "4125"
- replace maximum value with the half, for instance, replace "Up to 2400" with the half "1200"
- remove commas and asterisks
- replace NA with 0 (only NA value is Mississippi tax credit, there are local credits and/or rebates, but not on state level)

Since the tax credit is a lump-sum benefit while the registration fee is annually required, we need to adjust by vehicle life. According to the Bureau of Transportation Statistics (https://www.bts.gov/content/average-age-automobiles-and-trucks-operation-united-states), the average age of light vehicles in US is 12.5 years, we will use this as the standard magnifying power of registration fee. In this sense, we calculate the total incentive by:
Total incentive = Tax credit - 12.5 * Registration fee

After wrangling and adjustment, we save the clean data set as *data/EV Credit_TF.csv*. It contains multiple rows and 4 columns.
- Row: each stands for one state observation
- Column: 
  - State
  - exp_incentive_avg: mean of exp_incentive_EV and exp_incentive_hybrid
  - exp_incentive_EV: incentive for EV
  - exp_incentive_hybrid: incentive for hybrid energy vehicle

### 1.3 *Econ Stats_BEA.csv*

For data set 3, we read *data/raw/Table.csv* downloaded from https://www.bea.gov/itable/regional-gdp-and-personal-income. The data set contains state annual summary economic statistics, like personal income, GDP, consumer spending, price indexes, and employment.

For data wrangling, we:
- filter 2016-2022 data that coincide with what we have in the data sets above
- drop end notes
- rename columns for data merging later on
- replace (NA) with NA and set cells as numeric
- transform the structure to longer so that columns indicating econ stats values are integrated into one variable

After wrangling and adjustment, we save the clean data set as *data/Econ Stats_BEA.csv*. It contains multiple rows and 4 columns.
- Row: each stands for one state-year-description observation
- Column: 
  - State
  - Description: econ stats variables, e.g. real GDP, real per capita PCE
  - Year
  - Value: econ stats values, units contingent on particular stats

## 2. *staticplot.R*

staticplot.R is designed to summarize and visualize the across-state distribution of tax benefits and the adoption rates of clean vehicles in the United States. The analysis leverages datasets from the US Department of Energy and the US Tax Foundation.

The codes creates three main visualizations:

1. Clean Vehicle Tax Benefit by State: A choropleth map that visualizes the distribution of tax incentives provided by different states for clean vehicle adoption. It depicts varying levels of tax benefits in dollars and uses a color gradient from red (low benefits) to dark blue (high benefits), with white indicating the midpoint. 

2. Percentage of Clean Vehicles for Selected States by Time: A choropleth map that visualizes the adoption rates of clean vehicles across states as of 2022. It uses clean vehicle registration data *Vehicle Registration_AFDC.csv* to calculate the percentage of clean vehicles relative to total vehicles and visualizes this information. This map uses a green color gradient to represent varying levels of clean vehicle adoption in percentage point, with darker color representing higher values.

3. Distribution of Vehicles by Fuel Type in a Given Year: A grid of histograms; each provides a density distribution of the number of vehicles by fuel type in a year specified by the user.  

## 3. *shinyplot.R*

shinyplot.R is designed to create interactive plots using Shiny. This code is structured into two main parts, intended to 1) visualize the change of quantity and percentage over time for a specific type of vehicle in a specific state 2) filter for a range of tax benefits and view the associated state-level vehicle information.

The code creates two applications:

1. Percentage of Each Type of Vehicles by State and Year
The user interface consists of sidebar inputs for selecting a state and a car type, and the main panel contains tabs for viewing either the quantity or percentage of the selected vehicle type over years. 
The app can be accessed through the following link:
https://m2q0j5-mikaela-lin.shinyapps.io/broken-line-chart/

2. Filtering states to see their clean vehicle information
The user interface allows users to input a range by selecting the minimum and maximum value of tax benefits they're interested in exploring. It includes an action button to apply filters and tabs for viewing a map and a data table of selected states' vehicle and tax information. The map marks the states that are within range with green and the rest with grey. If there are no states in the specified range, the app will display a warning message and stop the process.
The app can be accessed through the following link:
https://m2q0j5-mikaela-lin.shinyapps.io/tax-map/


## 4. *textprocess.R*

In this script we scrape the sub-article texts of State Regulations California Code of Regulations, Title 13 - Motor Vehicles, Division 1 - Department of Motor Vehicles, Chapter 1 - Department of Motor Vehicles, Article 3 - Vehicle Registration and Titling, from https://www.law.cornell.edu/regulations/california/title-13/division-1/chapter-1/article-3. We then conduct sentiment analysis, and draw the frequency bigram and cooccurrence table.

If internet is not available, you may also refer to line 17-19 for guidelines to load the archived data *data/raw/text.txt*. 

For text wrangling, we:
- parse the text by udpipe
- transform lemma to lower case
- remove stop words
- remove punctuation, conjunction, number and others

In the following research, we consider "clean" as the dictionary on EV because EV is referred to as "clean air vehicle" in the California Code.

### 4.1 Sentiment analysis

Through AFINN sentiment analysis, we find out that the overall sentiment in the text is -0.2785, while the sentiment with dependency on EV is 0.7619. This may indicate that the legal texts take a more positive attitudes towards EV registration than the overall vehicle registration.

We make two plots for sentiment analysis and save them as .png:
- *image/text_overall_AFINN.png* refers to the distribution of AFINN values, based on the overall text sentiment. x-axis stands for the AFINN value, y-axis stands for the count of the particular value.
- *image/text_EV_AFINN.png* refers to the distribution of AFINN values, based on text sentiment with dependency on EV. x-axis stands for the AFINN value, y-axis stands for the count of the particular value.

### 4.2 Frequency bigram

We draw a frequency bigram *text_frequency_bigram.png* with dependency on EV ("clean"), that keeps only words with frequency over 3. Among words with higher frequencies:
- "air", "vehicle" are intuitive, as the California Code uses their combination as the term of EV
- "certificate", "decal" may reveal that most sub-articles are provided to grant certificate or decal to EV so that they may enjoy benefits like using High Occupancy Vehicle (HOV, or carpool) lanes

### 4.3 Cooccurrences

The cooccurrence table display similar results with the frequency bigram that "decal" has a extremely high probability (0.8357) of cooccurrence with "clean". It ranks the second just after "air" (0.9754).

## 5. *model.R*

model.R is designed to creates three regression models that explore the impact of tax incentive *exp_incentive_avg* on adoption rates of clean vehicles *PercentageClean*, executing the following tasks:

1. Data Preparation
Merge vehicle registration data (vehicle_pct) with tax benefit data (tax_benefit) on the State column to create tax_vehicle_pct. Prepare economic indicators data from Econ Stats_BEA.csv, simplifying variable names and removing columns with all NA values.

2. Regression Models
Model 1: Basic linear regression analyzing the impact of hybrid and EV tax incentives on the percentage of clean vehicles.
Model 2: Adds state fixed effects to account for unobserved heterogeneity across states.
Model 3: Further controls for economic indicators, such as real personal income and total employment, to understand their influence on clean vehicle adoption.
Correlation Analysis:

3. Computes correlations among economic indicators and visualizes them using a heatmap to identify potential multicollinearity issues.

# Instructions for users:

All R files shall be run in order from top to bottom. Since all cleaned and intermediate data sets have been stored, no particular sequence is required to run the scripts.

Note that the working directory and path need to be reset to your own directory, please refer to:
- line 4 in *data.R*
- line 9 in *static_plot.R*
- line 11 in *shiny_plot.R*
- line 10 in *textprocess.R*
- line 10 in *model.R*

# Explanation of original data source:

All data are acquired from open-source database or by web scraping:
1. Light-Duty Vehicle Registration Counts by State and Fuel Type, from Alternative Fuels Data Center (web-scrapped and archived as *data/raw/Vehicle Registration.csv*). Each row stands for one state-year observation. Columns stands for state, year and various fuel types. All variables are self-explanatory by their labels.
2. State Electric Vehicle Tax Credits and Registration Fees, from Tax Foundation (downloaded as *data/raw/Electric Vehicles EV Taxes by State Details  Analysis.csv*). Each row stands for one state observation. Columns stands for state, EV tax credit, extra registration fee for EV and hybrid fuel vehicles. All variables are self-explanatory by their labels.
3. State annual summary statistics: personal income, GDP, consumer spending, price indexes, and employment, from Bureau of Economic Analysis (downloaded as *data/raw/Table.csv*). Each row stands for one state-description. Columns stands for geographic name, variable description and years. All variables are self-explanatory by their labels.
4. State Regulations California Code of Regulations, Title 13 - Motor Vehicles, Division 1 - Department of Motor Vehicles, Chapter 1 - Department of Motor Vehicles, Article 3 - Vehicle Registration and Titling, from Legal Information Institute, Cornell Law School (web-scrapped and archived as *data/raw/text.txt*). 
