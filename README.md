# About

## Background
Coup d'état staged by the Tatmadaw (Myanmar Military) back in February has jeopardized the young democracy the country was enjoying, and undermined its development as well as the livelihood of its people.

## Approach
In this project, ~32000 news articles from various news sources were scrapped from the internet and news titles were analyzed using R. The project consists of 3 stages-   
1. Web-scrapping the news  
2. Cleaning and processing data  
3. Visualizing the data in a Dashboard (view dashboard @ https://sanhtetaung.shinyapps.io/myanmarnewsdashboard/ )

Some of the packages used in each stage are  
1. rvest, dplyr  
2. readr, dplyr, tidyr, tidytext, xts  
3. ggplot2, plotly, wordcloud2, DT, dygraphs, viridis  

Dashboard was built as Shiny Interactive Dashboard using Flexdashboard package

## Qualitative Summary of Analysis
Unsurprisingly, some of the most commonly used words in news title were "coup", "military", "protest", etc. reflecting the political turmoil of the country. In addition, the average sentiment of all articles by each news source for the duration of time data were collected were overwhelmingly negative. In fact, the sentiments of news article titles significantly dropped after Feb 1st - the day the coup was staged
