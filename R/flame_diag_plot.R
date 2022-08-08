library(readr)
library(dplyr)
library(ggplot2)
library(here)

flame_dat <- read_csv(here("data/FLAMe/satlink/Sutron Satlink 3_log_20220803_20220803_03.csv"),
                      col_names = FALSE) %>%
  rename("date" = "X1", 
         "time" = "X2", 
         "variable" = "X3", 
         "value" = "X4", 
         "units" = "X5", 
         "qa_flag" = "X6")

flame_dat %>%
  ggplot(aes(x = time, y = value)) +
  geom_line() +
  facet_grid(variable ~ ., scales = "free")
