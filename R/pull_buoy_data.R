library(RCurl)
library(stringr)
library(here)

up <- paste0(Sys.getenv("U"),":", Sys.getenv("P"))

files_string <- RCurl::getURL("sftp://newftp.epa.gov/cb150/", 
                              userpwd = up, 
                              dirlistonly = TRUE)
files <- unlist(str_split(files_string, "\n"))[grepl("data_report", 
                                                         unlist(str_split(
                                                           files_string, "\n")))]
new_files <- files[!files %in% list.files("data/cb150")]

for(i in new_files){
  file_url <- paste0("sftp://newftp.epa.gov/cb150/",i)
  file_path <- paste0(here("data/cb150/"),"/",i)
  writeBin(object = getBinaryURL(url = file_url, 
                                 userpwd = up, 
                                 dirlistonly = FALSE), con = file_path)
}
