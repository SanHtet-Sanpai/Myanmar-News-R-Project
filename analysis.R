library(dplyr)
library(readr)
library(tidytext)
library(tidyr)
library(textdata)
library(xts)

GetData <- function( file = 'news.csv'){
  
news <- read_csv(file)

news <- mutate(news, date = as.POSIXct(date, format = "%Y-%m-%d %H:%M", tz = "GMT")) %>% 
  mutate(news, source = as.factor(source)) %>% 
  distinct()

news <- news[!duplicated(news[ ,  c("title", "source")]), ]


return (news)
}

GetTidyData <- function (dt = GetData()){
  
data(stop_words)

tidy_news <- dt %>% 
  select(title, source, date) %>% 
  mutate(ID=row_number()) %>% 
  relocate(ID, .before = title)  %>% 
  group_by(source) %>%
  ungroup() %>%
  unnest_tokens(word, title) %>%
  anti_join(stop_words)

return (tidy_news)

}

#top_words_in_title

get_topwords <- function(df = GetTidyData()){

  Tf_idf <- df %>%
    count(source, word) %>%
    bind_tf_idf(word, source, n) %>% 
    select(word, tf_idf)
  
  Tf_idf <-  aggregate(Tf_idf$tf_idf, by = list(word =Tf_idf$word), 
                       FUN = mean) %>% 
    arrange(desc(x)) %>% 
    rename(tf_idf = x)
  
  dt <- df %>% 
    count(word, sort=T)  %>%
    filter(!word %in% c("myanmar", "myanmar's")) %>%
    mutate(word = reorder(word, n)) %>% 
    left_join(Tf_idf, by = "word")
  
  return(dt)
}

#top_sources

get_topsources <- function(dt = GetData()) {
  return( dt <- dt %>%
            count(source,sort=T) %>%
            mutate(source = reorder(source, n)))
}


#word_source_heatmap

get_heatmap_data <- function( heatmapdata = GetTidyData(), ts = get_topsources(), tw= get_topwords()) {

  heatmapdata <- heatmapdata %>% 
                  count(word, source, sort=T) %>% 
                  filter(!word %in% c("myanmar", "myanmar's", "aung", "san", "suu", "kyi")) %>%
                  mutate(word = reorder(word, n))
 
 return(heatmapdata)
 
}


#average sentiments by source

get_avg_sent <- function(dt1 = GetData(),  dt2 = GetTidyData()) {
  
afinn <- dt2 %>% 
  inner_join(get_sentiments("afinn")) %>% 
  group_by(Source = source) %>% 
  summarise(Sentiment = mean(value)) %>% 
  mutate(Lexicon = "AFINN")

source_articles <- dt1 %>% count(source)

bing_and_nrc <- bind_rows(
  dt2 %>% 
    inner_join(get_sentiments("bing")) %>%
    mutate(Lexicon = "Bing et al."),
  dt2 %>% 
    inner_join(get_sentiments("nrc") %>% 
                 filter(sentiment %in% c("positive", 
                                         "negative"))
    ) %>%
    mutate(Lexicon = "NRC")) %>%
  count(Lexicon, Source = source, sentiment) %>%
  pivot_wider(names_from = sentiment,
              values_from = n,
              values_fill = 0) %>% 
 left_join(y=source_articles, by = c("Source"="source")) %>%
  mutate(Sentiment = (positive - negative)/n)

  df <- bind_rows(afinn, bing_and_nrc)
  
  return(df)
}


#Sentiment timeline

get_time_sent <- function( dt1 = GetData(), dt2 = GetTidyData() ) {
  
afinnT <- dt2 %>% 
  inner_join(get_sentiments("afinn")) %>% 
  group_by(Time = as.Date(date, format = "%Y-%m-%d")) %>% 
  summarise(Sentiment = mean(value)) %>% 
  mutate(Lexicon = "AFINN")

time_articles <- dt1 %>% 
  mutate(date = (as.Date(date, format = "%Y-%m-%d"))) %>%
  count(date)

bing_and_nrcT <- bind_rows(
  dt2 %>% 
    inner_join(get_sentiments("bing")) %>%
    mutate(Lexicon = "Bing et al."),
  dt2 %>% 
    inner_join(get_sentiments("nrc") %>% 
                 filter(sentiment %in% c("positive", 
                                         "negative"))
               ) %>%
    mutate(Lexicon = "NRC")) %>%
  count(Lexicon, Time = as.Date(date, format = "%Y-%m-%d"), sentiment) %>%
  pivot_wider(names_from = sentiment,
              values_from = n,
              values_fill = 0) %>% 
  left_join(y=time_articles, by = c("Time"="date")) %>%
  mutate(Sentiment = (positive - negative)/n)

df <- bind_rows(afinnT, bing_and_nrcT) 

timeline <- subset(df, select= c(Time, Sentiment, Lexicon)) %>%
  pivot_wider(names_from = Lexicon,
              values_from = Sentiment,
              values_fill = 0)

timeline_xts <- xts(x= timeline[,-1], order.by = timeline$Time)

return(timeline_xts)
}

get_time_article <- function( dt1 = GetData() ) {
  
time_articles <- dt1 %>% 
  mutate(date = (as.Date(date, format = "%Y-%m-%d"))) %>%
  count(date)

df <- xts(x= time_articles[,-1], order.by = time_articles$date)

  return(df)
}

news <- GetData()
tidy_news <- GetTidyData(news)
topwords <- get_topwords(tidy_news)
topsources <- get_topsources(news)
heatmap <- get_heatmap_data(tidy_news, topsources, topwords)
avg_sent <- get_avg_sent(news, tidy_news)
time_sent <- get_time_sent(news, tidy_news)
time_article <- get_time_article(news)
  
save(news, tidy_news, topwords, topsources, heatmap, 
     avg_sent, time_sent, time_article,
     file = "news_data.RData")