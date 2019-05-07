library(ggplot2)
library(shiny)
library(leaflet)
library(DT)
library(shinydashboard)
library(dplyr)
library(shinyWidgets)
library(data.table)
library(leaflet)
library(sp)
library(tmap)
library(tidyr)
library(lubridate)
library(ggmap)
library(corrplot)
library(ggpubr)
library(scales)
library(DT)
library(rsconnect)

# setwd('C:/Users/Paul Cho/Desktop/Bootcamp/Project/Shiny_e_com')
po_master<- fread("./datasets/po_master.csv", header=TRUE)
LTtype <- c('POtoSO','SOtoDO','SOtoGI','GItoGR','POtoRDD','POtoGR')
#Brazil States
as.vector(t(po_master %>% distinct(c_state))) -> BRstates
as.vector(t(po_master %>% distinct(delivered_year) %>% arrange(delivered_year))) -> Years
as.vector(t(po_master %>% distinct(product_category))) -> category

# Lead time analysis --------------------------------------------------

















po_master %>% 
  filter(GR_date<ymd('2018/08/29')) %>% 
  mutate(delivered_week = lubridate::week(ymd(GR_date)),
         delivered_year = lubridate::year(ymd(GR_date))) %>%
  group_by(delivered_year, delivered_week) %>% 
  mutate(orderCount = n(),
            backorder = sum(GRvRDD<0),
            backorder_ratio = backorder/orderCount) %>% 
  select(product_category,c_state, seller_id, delivered_week, delivered_year,backorder, backorder_ratio) -> backorder_rate

