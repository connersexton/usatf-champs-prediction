# LIBRARIES:
suppressMessages({
  library(RSelenium)
  library(wdman)
  library(netstat)
  library(rvest)
  library(tidyverse)
})

selenium()
selenium_object <- selenium(retcomand = T, check = F)
selenium_object

binman::list_versions("chromedriver")
driver <- rsDriver(browser = "chrome",
                   chromever = NULL,
                   verbose = F,
                   port = netstat::free_port())

remote_driver <- driver[["client"]]
remote_driver$open()

## USATF Entries page
remote_driver$navigate("https://www.usatf.org/events/2023/2023-toyota-usatf-outdoor-championships/status-of-entries")

## List for results:
results <- list()

## Events to pull
event_indices <- 1:11
event_names <- c("100m", 
                 "200m", 
                 "400m", 
                 "800m",
                 "1500m",
                 "5000m",
                 "10000m",
                 "100m Hurdles",
                 "110m Hurdles",
                 "400m Hurdles",
                 "3000m Steeplechase")
names(event_indices) <- event_names

event_indices <- event_indices[!(names(event_indices) %in% c("100m Hurdles", "110m Hurdles"))]

gender_indices <- 1:2
names(gender_indices) <- c("men", "women")

for (e in 1:length(event_indices)){
  event_list <- list()
  event_xpath_root <- paste0('//*[@id="13IndoorChampsMenu"]/div/div[',
                             unname(event_indices)[e],
                             "]/")
  event_xpath <- paste0(event_xpath_root,
                        'span')
  event_option <- remote_driver$findElement(using = 'xpath', event_xpath)
  event_option$clickElement()
  Sys.sleep(2)
  for (g in 1:length(gender_indices)){
    gender_xpath <- paste0(event_xpath_root,
                           'div/span[',
                           unname(gender_indices)[g],
                           ']'
                           )
    gender_xpath_nested <- paste0(event_xpath_root,
                                  'div/div[',
                                  unname(gender_indices)[g],
                                  ']/span[',
                                  unname(gender_indices)[g],
                                  ']'
                                  )
    gender <- remote_driver$findElement(using = 'xpath', gender_xpath)
    gender$clickElement()
    gender_nested <- remote_driver$findElement(using = 'xpath', gender_xpath_nested)
    gender_nested$clickElement()
    
    Sys.sleep(5)
    
    remote_driver$getPageSource()[[1]] %>% 
      read_html() %>%
      html_table() -> table
    
    table <- table[[1]]
    table_columns <- as.character(table[1,])
    table <- table[-1,]
    colnames(table) <- table_columns
    table[,"gender"] <- names(gender_indices)[g]
    table[,"event"] <- names(event_indices)[e]
    event_list[[g]] <- table
  }
  results[[names(event_indices)[e]]] <- bind_rows(event_list)
  message(names(event_indices)[e], '...done')
}

## Export CSVs
export_names <- paste0(gsub("\\s+","_",names(results)),".csv")

for (l in 1:length(results)){
  write.csv(results[[l]],export_names[l])
}
