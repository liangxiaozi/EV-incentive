library(tidyverse)
library(ggplot2)
library(dplyr)
library(shiny)
library(plotly)
library(DT)
library(spData)
library(sf)
library(readr)

# Replace with your own working directory!!!
path <- "/Users/mikirin/Documents/GitHub/final-project-mikaela-xiao"

# load vehicle population data set
vehicle_summary <- read_csv(paste0(path,"/data/Vehicle Registration_AFDC.csv"))
# Load the data set of clean vehicle by percentage
vehicle_pct <- read_csv(paste0(path,"/data/vehicle_pct.csv"))

## Third plot: (Dynamic) Percentage of Each Type of Vehicles by State and Year

# Calculate percentages for each type of vehicle
vehicle_type_pct <- vehicle_summary %>%
  group_by(State, Year, Type) %>%
  summarise(
    CountByType = sum(Count), # Total for each vehicle type
    .groups = 'drop'
  ) %>%
  left_join(vehicle_pct %>% select(State, Year, TotalVehicles), by = c("State", "Year")) %>%
  mutate(
    PercentageOfType = (CountByType / TotalVehicles) * 100
  )

# Define UI with tabs
ui <- fluidPage(
  titlePanel("Vehicle Type Analysis by State and Year"),
  sidebarLayout(
    sidebarPanel(
      selectInput("state", "Select a State:", choices = unique(vehicle_type_pct$State)),
      selectInput("type", "Select a Car Type:", choices = unique(vehicle_type_pct$Type))
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Quantity", plotOutput("quantityPlot")),
        tabPanel("Percentage", plotOutput("percentagePlot"))
      )
    )
  )
)


# Define server logic with separate plots for quantity and percentage
server <- function(input, output) {
  
  # Plot for Quantity
  output$quantityPlot <- renderPlot({
    filtered_data <- vehicle_type_pct %>%
      filter(State == input$state, Type == input$type)
    
    ggplot(filtered_data, aes(x = Year, y = CountByType)) +
      geom_point(color = "blue", size = 3, alpha = 0.6) +
      geom_line(color = "blue", alpha = 0.6) +
      labs(y = "Total Number of Cars", x = "Year") +
      expand_limits(y = 0) + # Ensure y-axis starts from 0
      theme_minimal()
  })
  
  # Plot for Percentage
  output$percentagePlot <- renderPlot({
    filtered_data <- vehicle_type_pct %>%
      filter(State == input$state, Type == input$type)
    
    ggplot(filtered_data, aes(x = Year, y = PercentageOfType)) +
      geom_point(color = "red", size = 3, alpha = 0.6) +
      geom_line(color = "red", alpha = 0.6) +
      labs(y = "Percentage of Cars (%)", x = "Year") +
      ylim(0, 100) + # Explicitly set y-axis range from 0 to 100
      theme_minimal()
  })
}

# Run the application
shinyApp(ui = ui, server = server)


## Fourth plot: (Dynamic) Filtering states to see their clean vehicle information

# Load the tax benefit data set
tax_benefit <- read_csv(paste0(path,"/data/EV Credit_TF.csv"))

# Merge vehicle percentage with tax benefit data
tax_vehicle_pct <- left_join(vehicle_pct, tax_benefit, by = c("State" = "State")) 

# Load US states spatial data
data(us_states)

# Merge the vehicle_pct dataset with the spatial data
us_tax_benefit <- left_join(us_states, tax_vehicle_pct, by = c("NAME" = "State"))

# Convert to sf object for plotting
us_tax_benefit_sf <- st_as_sf(us_tax_benefit)

# Define UI for the app
ui <- fluidPage(
  titlePanel("US State Tax Benefits and Clean Vehicle Percentage"),
  sidebarLayout(
    sidebarPanel(
      numericInput("min_tax_benefit", "Minimum Tax Benefit", value = -1000, min = -1500, max = 4000, step = 50),
      numericInput("max_tax_benefit", "Maximum Tax Benefit", value = 1000, min = -1500, max = 4000, step = 50),
      actionButton("btn", "Apply Filter")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Map", plotlyOutput("taxBenefitMap")),
        tabPanel("Data Table", DTOutput("stateTable"))
      ),
      uiOutput("warningMessage") # Dynamic warning message
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive expression for filtered data
  filtered_data <- reactive({
    data <- us_tax_benefit_sf %>%
      mutate(withinRange = exp_incentive_avg >= input$min_tax_benefit & exp_incentive_avg <= input$max_tax_benefit) %>%
      replace_na(list(withinRange = FALSE)) # Ensure NA values in withinRange are treated as FALSE explicitly
    data
  })
  
  observeEvent(input$btn, {
    # Attempt to filter the data based on the input range
    filtered <- filtered_data()
    
    # Determine if any states are within the specified range
    hasStatesWithinRange <- any(filtered$withinRange, na.rm = TRUE)
    
    # Display warning message if no states are within the range
    if(!hasStatesWithinRange) {
      output$warningMessage <- renderUI({
        div(style = "color: red; font-weight: bold; padding-top: 20px;", "No states are within this range!")
      })
    } else {
      # Clear the warning message if states are within the range
      output$warningMessage <- renderUI({})
    }
    
    # Conditionally render the Plotly plot if states are within the range
    output$taxBenefitMap <- renderPlotly({
      req(hasStatesWithinRange) # Proceed only if there are states within the range
      p <- ggplot(filtered, aes(fill = withinRange)) +
        geom_sf(color = "white", size = 0.2) + # Adjust border color and size
        scale_fill_manual(values = c("TRUE" = "palegreen3", "FALSE" = "lightgrey"), guide = FALSE) +
        labs(title = "State Tax Benefits for Clean Vehicles") +
        theme_minimal() +
        theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
              plot.subtitle = element_text(hjust = 0.5, face = "italic", size = 12),
              legend.position = "none",
              plot.background = element_rect(fill = "floralwhite"), # Adjust the plot background color
              panel.background = element_rect(fill = "floralwhite"), # Adjust the panel background color
              panel.grid.major = element_blank(), # Remove major grid lines
              panel.grid.minor = element_blank(), # Remove minor grid lines
              plot.margin = margin(10, 10, 10, 10)) # Adjust plot margins
      ggplotly(p) %>% layout(dragmode = "pan", 
                             geo = list(bgcolor = 'floralwhite')) # Adjust the Plotly specific layout options
    })
    
    output$stateTable <- renderDT({
      datatable(
        filtered_data() %>%
          filter(withinRange) %>%
          select(NAME, Year, CleanVehicles, PercentageClean, exp_incentive_avg, exp_incentive_EV, exp_incentive_hybrid),
        options = list(lengthChange = FALSE, autoWidth = TRUE)
      )
    })
  })
}

# Run the app
shinyApp(ui = ui, server = server)
