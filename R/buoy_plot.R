library(lubridate)
library(dplyr)
library(xts)
library(dygraphs)

load("C:/Users/JHollist/projects/high_res_cyano/data/merged_buoy_data.rda")

buoy_plot <- function(data, pond, variable){
  browser()
  dat <- data %>%
    filter(name %in% variable) %>%
    filter(waterbody %in% pond) %>%
    mutate(year = year(date_time), month = month(date_time), day = day(date_time),
           hour = hour(date_time), 
           date_hour = ymd_h(paste(year, month, day, hour))) %>%
    group_by(waterbody, date_hour, name) %>%
    filter(value <= quantile(value, c(0.999), na.rm = TRUE)) %>%
    summarize(value = mean(value, na.rm = TRUE)) %>%
    ungroup()
  dat_xts <- xts(x = dat$value, order.by = dat$date_hour)
  
  p <- dygraph(dat_xts, main = pond, ylab = variable) %>%
    dyOptions(labelsUTC = TRUE, fillGraph=TRUE, fillAlpha=0.1, drawGrid = FALSE, colors="#88E3B6") %>%
    dyRangeSelector() %>%
    dyCrosshair(direction = "vertical") %>%
    dyHighlight(highlightCircleSize = 5, highlightSeriesBackgroundAlpha = 0.2, hideOnMouseOut = FALSE)  
  
  p
}

buoy_plot(merged_buoy_data, "shubael", "chlorophyll rfu")
