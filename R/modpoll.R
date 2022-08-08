modpoll <- function(port_host, output = "data.txt", options = ...){
  modpoll_args <- list(options)
  modpoll_exe <- "modpoll"
  browser()
  #modpoll -t4:float -a 2 -r 389 -b 38400 -p none -m rtu COM5
  modpoll_cmd <- 
    paste0(modpoll_exe, " ",
           paste(modpoll_args[[1]], collapse = " "), " ", 
           "-1 ",
           port_host)
  x <- system(modpoll_cmd, intern = TRUE)
  data_idx <- which(str_detect(x, "Polling")) + 1
  data <- x[data_idx]
  data <- str_split(data, ":", simplify = TRUE)
  data <- data.frame(data)
  names(data) <- c("register", "value")
  data$date_time <- Sys.time()
  data
}