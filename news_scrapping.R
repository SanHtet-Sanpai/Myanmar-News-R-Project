library(rvest)
library(dplyr)

news = data.frame()

for (page_number in seq(from = 0, to = 3199, by = 1))
{
  url=paste0("https://newslookup.com/results?p=",page_number,"&q=myanmar&dp=5&mt=-1&ps=10&s=&cat=-1&fmt=&groupby=no&site=&dp=5&tp=-720")
  page = read_html(url)
  
  title = page %>% html_nodes(".title") %>% html_text()
  source = page %>% html_nodes("br+ .source") %>% html_text()
  date = page %>% html_nodes(".stime") %>% html_text()
  intro = page %>% html_nodes(".desc") %>% html_text()
  link = page %>% html_nodes(".title") %>% html_attr("href")
  
  news = rbind(news, data.frame(title, source, date, intro, link, stringsAsFactors = F))
  
  print(paste("Page:", page_number))  
}

write.csv(news,"news.csv")

