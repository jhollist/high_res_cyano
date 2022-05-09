library(dplyr)
library(lubridate)
library(stringr)

id <- c("2021818W11", "2021818WP1", "20211012W21","20211012WP2","20210628SHB1", "20210628SH11", "20211114s31")
val <- rnorm(7)
xdf <- data.frame(id, val)
xdf <- mutate(xdf, wb_s_d = str_extract(.data$id, "[:alpha:]*[0-9]*$"))
xdf <- mutate(xdf, date = str_extract(.data$id, "^[0-9]*"))
xdf <- mutate(xdf, year = str_extract(.data$date, "(.{4})"), 
              mo_day = str_remove(.data$date, "(.{4})"))
xdf <- mutate(xdf, month = case_when(nchar(mo_day) == 3 ~
                                       paste0("0",str_extract(.data$mo_day, "(.{1})")),
                                     TRUE ~ str_extract(.data$mo_day, "(.{2})")),
              day = str_extract(.data$mo_day, "(.{2})$"))
xdf <- mutate(xdf, date = ymd(paste(year, month, day)))



