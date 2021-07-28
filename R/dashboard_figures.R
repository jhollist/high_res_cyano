library(dplyr)
library(lubridate)
library(ggplot2)
library(here)
library(plotly)
library(hrbrthemes)

path <- "C:/Users/JHollist/projects/high_res_cyano"
setwd(path)
system("git pull")

load("C:/Users/JHollist/projects/high_res_cyano/data/merged_buoy_data.rda")

dash_gg <- merged_buoy_data %>%
  filter(name %in% c("no3-", "temperature",
                     "ph", "odo", "chlorophyll rfu", 
                     "bga-phycocyanin rfu","turbidity")) %>%
  mutate(year = year(date_time), month = month(date_time), day = day(date_time),
         hour = hour(date_time), 
         date_hour = ymd_h(paste(year, month, day, hour))) %>%
  group_by(waterbody, date_hour, name) %>%
  filter(value <= quantile(value, c(0.999), na.rm = TRUE)) %>%
  summarize(value = mean(value, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(name = factor(name, levels = c("temperature", "ph", "odo", "no3-",
                                        "chlorophyll rfu", 
                                        "bga-phycocyanin rfu", "turbidity"),
                       labels = c("Temp(C)", "pH", "DO(mg/L)", 
                                  "Nitrate(mg/L)",
                                  "Chlor.(RFU)", "Phyco(RFU)", 
                                  "Turbidity(NTU)")),
         waterbody = factor(waterbody, labels = 
                              c("Hamblin Pond", "Shubael Pond"))) %>%
  ggplot(aes(x=date_hour, y = value)) +
  facet_grid(name ~ waterbody, scales = "free") +
  geom_point(aes(color = waterbody)) + 
  scale_color_manual(values = c("darkred", "darkblue")) +
  labs(x = "", y = "", title = paste("Last Updated:", lubridate::today())) +
  theme_bw() +
  theme(legend.position = "none")

dash_gg_plotly <- ggplotly(dash_gg)

htmlwidgets::saveWidget(dash_gg_plotly, 
                        "C:/Users/JHollist/projects/cc_buoys/index.html", 
                        selfcontained = FALSE)
setwd("C:/Users/JHollist/projects/cc_buoys/")
system("git add -A")
system('git commit -m "auto build"')
system("git push origin main")

      
