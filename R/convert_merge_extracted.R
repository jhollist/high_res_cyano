library(compeco)
library(purrr)
library(dplyr)
library(here)
library(readr)
library(ggplot2)

phyco_files <- list.files(here("data/"),pattern = "phyco", full.names = TRUE)
chla_files <- list.files(here("data/"), pattern = "chla", full.names = TRUE)

phyco_data <- map_df(phyco_files, function(x) ce_convert_rfus(x, "phyco", 
                                                              "2021", "ours",
                                                              std_check = FALSE))
chla_data <- map_df(chla_files, function(x) ce_convert_rfus(x, "ext_chla", 
                                                              "2021", "ours",
                                                              std_check = FALSE))
extracted <- bind_rows(phyco_data, chla_data) %>%
  mutate(waterbody = case_when(waterbody == "shubeal" ~
                                 "shubael",
                               TRUE ~ waterbody))
write_csv(extracted, here("data/extracted_2021.csv"))

extracted <- read_csv(here("data/extracted_2021.csv"))
extracted %>% 
  filter(units == "µg/L") %>%
  ggplot(aes(x = date, y = value)) +
  geom_point() +
  facet_grid(variable ~ waterbody, scales = "free")
