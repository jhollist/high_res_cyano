library(stringr)
library(lubridate)
library(dplyr)
library(readr)
library(tidyr)
library(here)

files <- list.files(here("data/buoys"), full.names = TRUE)

clean_buoy_data <- function(csv_file){
  browser()
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
  buoy_data <- pivot_longer(buoy_data,cols = 'processor power':'roll')
  
}

clean_buoy_data(files[9])

