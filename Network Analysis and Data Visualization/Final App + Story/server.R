library(shiny)
require(pacman)
library(ggplot2)
library(plotly)
library(leaflet)
library(leaflet.extras)
library(lubridate)
library(dplyr)

data = read.csv("data/clean_data.csv", header=TRUE, sep=",")
formatted_data = read.csv("data/formatted_data_ts.csv", header=TRUE, sep=",")
formatted_data$Date = as.Date(formatted_data$Date, format="%Y-%m-%d")

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    observe({
        val = input$year
        if(input$gas == 9) {
            if (val < 2003 ) {val = 2003}
            updateSliderInput(session, "year", min=2003, max=2018, step=1, value=val)
        } else {
            updateSliderInput(session, "year", min=2001, max=2018, step=1, value=val)
        }
    })

    # Expression that generates a histogram. The expression is
    # wrapped in a call to renderPlot to indicate that:
    #
    #  1) It is "reactive" and therefore should be automatically
    #     re-executed when inputs change
    #  2) Its output type is a plot

    plotInput = reactive({
        filtered = data[which(data$MAGNITUD == input$gas & data$ANO == input$year &
                                  data$MES == input$month),
                        c("Station", "Longitude", "Latitude", "MONTHLYMAX")]
        
        max_val <- max(data$MONTHLYMAX[data$MAGNITUD == input$gas], na.rm = TRUE)
        filtered$intensity <- filtered$MONTHLYMAX/max_val
        leaflet(filtered) %>%
            addProviderTiles(providers$Esri.WorldStreetMap) %>%
            setView(lat = 40.4168, lng = -3.7038, zoom = 11) %>%
            addMarkers(lat = ~Latitude, lng = ~Longitude, label = ~as.character(Station)) %>%
            addHeatmap(lat = ~Latitude, lng = ~Longitude, intensity = filtered$intensity,  blur = 25, 
                            max = 1, radius = 70)
    })
    
    output$map = renderLeaflet({
        plotInput()
    })
    
    seriesInput = reactive({
        filtered = formatted_data[which(formatted_data$Gas==input$gas
                                        & year(formatted_data$Date)==input$year),]
        gg = ggplot(filtered, aes(x = Date, y = Value)) +
            geom_line(color = "#00AFBB") + facet_wrap(~Station) +
            ggtitle(paste("Daily levels of selected gas in", as.character(input$year))) +
            ylab("Daily level") + scale_x_date(date_labels = "%b")
        ggplotly(gg)
    })
    
    output$timeseries = renderPlotly({
        seriesInput()
    })
    
    tableInput = reactive({
        filtered = formatted_data[which(formatted_data$Gas==input$gas
                                        & year(formatted_data$Date)==input$year
                                        & month(formatted_data$Date)==input$month),]
        filtered %>%
            group_by(Station) %>%
            summarise(High = max(as.vector(Value)), Average = mean(as.vector(Value)), Low = min(as.vector(Value)))
    })
    
    output$table = renderTable({
        tableInput()
    })
})
