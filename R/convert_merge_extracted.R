library(compeco)
library(purrr)
library(dplyr)
library(here)
library(readr)
library(ggplot2)

phyco_files <- list.files(here("data/"),pattern = "phyco", full.names = TRUE)
chla_files <- list.files(here("data/"), pattern = "chla", full.names = TRUE)


phyco_data <- map_df(phyco_files, function(x) {
  x <- readr::read_csv(x, na = c("NA", "", "na"))
  ce_convert_rfus(x, "phyco", "2021", "g04",std_check = FALSE)})
chla_files_old <- chla_files[grepl("5_13_&_6_28_&_7_14", chla_files)]
chla_data_old <- map_df(chla_files_old, function(x) {
  x <- readr::read_csv(x, na = c("NA", "", "na"))
  ce_convert_rfus(x, "ext_chla", "2021", "g04", std_check = FALSE)})
chla_files_new <- chla_files[!grepl("5_13_&_6_28_&_7_14", chla_files)]
chla_data_new <- map_df(chla_files_new, function(x) {
  x <- readr::read_csv(x, na = c("NA", "", "na"))
  ce_convert_rfus(x, "ext_chla", "2022", "g04", std_check = FALSE)})
extracted <- bind_rows(phyco_data, chla_data_old, chla_data_new) %>%
  mutate(waterbody = case_when(waterbody == "shubeal" ~
                                 "shubael",
                               TRUE ~ waterbody))
write_csv(extracted, here("data/cape_extracted_2021.csv"))

extracted <- read_csv(here("data/cape_extracted_2021.csv"))
extracted %>% 
  filter(units == "µg/L") %>%
  ggplot(aes(x = date, y = value)) +
  geom_point() +
  facet_grid(variable ~ waterbody, scales = "free")
