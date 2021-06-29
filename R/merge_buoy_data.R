library(stringr)
library(lubridate)
library(dplyr)
library(readr)
library(tidyr)
library(here)
library(purrr)

files <- list.files("C:/Users/JHollist/projects/high_res_cyano/data/buoys", 
                    full.names = TRUE)

# Get rda time
last_rda <- file.info(here("data/merged_buoy_data.rda"))$mtime
# file times
files <- files[file.info(files)$mtime >= last_rda]


clean_buoy_data <- function(csv_file){
  buoy_data_header <- read_csv(csv_file, n_max = 3, col_names = FALSE)
  buoy_data_raw <- read_csv(csv_file, skip = 3, col_names = FALSE)
  shubael_cols <- which(str_ends(buoy_data_header[1,], "Shubael Pond"))
  hamblin_cols <- which(str_ends(buoy_data_header[1,], "Hamblin Pond"))
  shubael_col_header <- make.unique(tolower(c("date_time", 
                          as.character(buoy_data_header[2,shubael_cols]))))
  hamblin_col_header <- make.unique(tolower(c("date_time", 
                          as.character(buoy_data_header[2,hamblin_cols]))))
  shubael_data <- buoy_data_raw[,c(1,shubael_cols)]
  hamblin_data <- buoy_data_raw[,c(1,hamblin_cols)]
  names(shubael_data) <- shubael_col_header
  names(hamblin_data) <- hamblin_col_header
  shubael_data <- mutate(shubael_data, waterbody = "shubael")
  hamblin_data <- mutate(hamblin_data, waterbody = "hamblin")
  buoy_data <- rbind(shubael_data, hamblin_data)
  buoy_data <- mutate(buoy_data, device = "cb150")
  buoy_data <- select(buoy_data, waterbody, date_time, device, everything())
  buoy_data <- pivot_longer(buoy_data, cols = 'processor power':'roll')
  buoy_data <- mutate(buoy_data, date_time = mdy_hms(date_time, 
                                                     tz = "America/New_York"))
  buoy_data
}

merged_buoy_data_new <- map_df(files, clean_buoy_data) %>%
  unique()
load("C:/Users/JHollist/projects/high_res_cyano/data/merged_buoy_data.rda")
merged_buoy_data <- rbind(merged_buoy_data, merged_buoy_data_new) %>%
  unique() %>%
  # Time Zero for both ponds
  filter((waterbody == "shubael" & date_time >= "2021-06-10 12:00:00") |
           (waterbody == "hamblin" & date_time >= "2021-06-10 14:15"))

save(merged_buoy_data, 
     file = "C:/Users/JHollist/projects/high_res_cyano/data/merged_buoy_data.rda",
     compress = "xz")

