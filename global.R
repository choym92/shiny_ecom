library(plyr)
library(ggplot2)
library(data.table)
library(shiny)
library(leaflet)
library(DT)
library(shinydashboard)
library(dplyr)
library(shinythemes)

# setwd('C:/Users/Paul Cho/Desktop/Bootcamp/Project/Shiny_e_com')
geo_df <- fread("./datasets/olist_geolocation_dataset.csv", header=TRUE)
po_master<- fread("./datasets/po_master.csv", header=TRUE)
choice <- colnames(geo_df)


po_master %>% 
  filter(GR_date<ymd('2018/08/29')) %>% 
  mutate(delivered_week = lubridate::week(ymd(GR_date)),
         delivered_year = lubridate::year(ymd(GR_date))) %>%
  group_by(delivered_year, delivered_week) %>% 
  mutate(orderCount = n(),
            backorder = sum(GRvRDD<0),
            backorder_ratio = backorder/orderCount) %>% 
  select(product_category,c_state, seller_id, delivered_week, delivered_year,backorder, backorder_ratio) -> backorder_rate

