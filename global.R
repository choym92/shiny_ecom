
library(ggplot2)
library(data.table)
library(shiny)
library(leaflet)
library(DT)
library(shinydashboard)
library(dplyr)
library(shinythemes)

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

intro_str =  "Marketing has always been an industry that is heavily data related. Big firms spent millions of dollars every year on analysising their marketing data, in terms of 
finding insights and make their marketing investment wisely. Because of my marketing background, discovering insights from a marketing dataset 
always insterest me, so I did this project that is using a Brazilian online retail marketplace's sales data to understand the Brazil's E-commerce from mutiple perspectives. This 
shiny app has three major sections. With geographic section, you could visualize data from a geographic standpoint and see some correlations. The trends section is the part to show
sales trends in the particular time range you selected, you could also comparing sales volume between categories. The categories section visualize the data from its different
categories perspective."

intrdata_str = "The dataset I am using is provided by the largest department store in Brazilian marketplaces, called Olist. It inculdes its over 100k orders from late 2016 to 2018.
The dataset's schema is showing below in the graphy. The data is divided into multiple datasets. It allows us to view the Brazilian E-commerce from mutiple demisions like order status,
payments information, geographic location and so on."
