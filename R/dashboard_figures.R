library(dplyr)
library(ggplot2)
library(here)
library(plotly)

load(here("data/merged_buoy_data.rda"))

dash_gg <- merged_buoy_data %>%
  filter(name %in% c("primary power", "no3-n conc", "no3-", "temperature",
                     "ph", "odo", "turbidity", "chlorophyll rfu", 
                     "bga-phycocyanin rfu")) %>%
  ggplot(aes(x=date_time, y = value)) +
  facet_grid(name ~ waterbody, scales = "free") +
  geom_point()

dash_gg_plotly <- ggplotly(dash_gg)

htmlwidgets::saveWidget(dash_gg_plotly, here("../cc_buoys/index.html"))
  
