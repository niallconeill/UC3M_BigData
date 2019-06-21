library(shiny)
require(pacman)
library(leaflet)
library(plotly)
library(dplyr)


# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # Application title
    titlePanel("Air quality in metro stations (2001 - 2018, Madrid)"),
    
    # Sidebar with a slider input for the number of bins
    sidebarLayout(
        sidebarPanel(
            selectInput("gas", label = h4("Gas"), 
                        choices = list("SO_2" = 1, "CO" = 6, "NO" = 7, "NO_2" = 8, "PM2.5" = 9, "PM10" = 10, "NOx" = 12,
                                       "O_3" = 14, "TOL" = 20, "BEN" = 30, "EBE" = 35), 
                        selected = 1),
            sliderInput("year", label = h4("Year"), 
                        min = 2001, max=2018, sep = "",
                        value = 2001),            
            sliderInput("month", label = h4("Month"),
                        min = 1, max = 12,
                        value = 1),
            tableOutput("table")
        ),
        
        # Show a plot of the generated distribution
        mainPanel(
            leafletOutput("map"),
            plotlyOutput("timeseries")
        )
    )
))
