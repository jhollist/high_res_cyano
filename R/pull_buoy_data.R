library(RCurl)
library(stringr)
library(here)

path <- "C:/Users/JHollist/projects/high_res_cyano"
up <- paste0(Sys.getenv("NEWFTPU"),":", Sys.getenv("NEWFTPP"))
up

files_string <- RCurl::getURL("sftp://newftp.epa.gov/buoys/", 
                              userpwd = up, 
                              dirlistonly = TRUE)
files <- unlist(str_split(files_string, "\n"))[grepl("data_report", 
                                                         unlist(str_split(
                                                           files_string, "\n")))]
new_files <- files[!files %in% list.files("data/buoys")]

for(i in new_files){
  file_url <- paste0("sftp://newftp.epa.gov/buoys/",i)
  file_path <- paste0(path, "/data/buoys/", i)
  writeBin(object = getBinaryURL(url = file_url, 
                                 userpwd = up, 
                                 dirlistonly = FALSE), con = file_path)
}

setwd(path)
system("git add -A")
system('git commit -m "auto download data files"')
system("git push origin main")
