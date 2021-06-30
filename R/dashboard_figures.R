library(dplyr)
library(lubridate)
library(ggplot2)
library(here)
library(plotly)

load(here("data/merged_buoy_data.rda"))

dash_gg <- merged_buoy_data %>%
  filter(name %in% c("primary power", "no3-n conc", "no3-", "temperature",
                     "ph", "odo", "turbidity", "chlorophyll rfu", 
                     "bga-phycocyanin rfu")) %>%
  mutate(year = year(date_time), month = month(date_time), day = day(date_time),
         hour = hour(date_time), 
         date_hour = ymd_h(paste(year, month, day, hour))) %>%
  group_by(waterbody, date_hour, name) %>%
  filter(value <= quantile(value, c(0.999), na.rm = TRUE)) %>%
  summarize(value = mean(value, na.rm = TRUE)) %>%
  ungroup() %>%
  ggplot(aes(x=date_hour, y = value)) +
  facet_grid(name ~ waterbody, scales = "free") +
  geom_point()

dash_gg_plotly <- ggplotly(dash_gg)

htmlwidgets::saveWidget(dash_gg_plotly, here("../cc_buoys/index.html"))
  
