library(data.table)
library(leaflet)
library(sp)
library(tmap)
library(spData)
library(plyr)
library(tidyr)
library(lubridate)
library(dplyr)
library(ggplot2)
library(ggmap)
library(corrplot)
library(ggpubr)

setwd('C:/Users/Paul Cho/Desktop/Bootcamp/project/shiny_e_com/')


# [1] "State"                      "Abbreviation"               "Capital"                    "Area (sq.km)"              
# [5] "Population (2010)"          "Density (2010)"             "GDP (% total) (2008)"       "GDP per capita (R$) (2008)"
# [9] "Literacy (2008)
brazil <- fread("./datasets/brazil_state_data.csv", header=TRUE) # brazil data
# [1] "order_id"                      "customer_id"                   "order_status"                 
# [4] "order_purchase_timestamp"      "order_approved_at"             "order_delivered_carrier_date" 
# [7] "order_delivered_customer_date" "order_estimated_delivery_date"
po_delivery <- fread("./datasets/olist_orders_dataset.csv", header=TRUE)
# [1] "order_id"            "order_item_id"       "product_id"          "seller_id"           "shipping_limit_date"
# [6] "price"               "freight_value"   
po_items <- fread("./datasets/olist_order_items_dataset.csv", header=TRUE)
# [1] "review_id"               "order_id"                "review_score"            "review_comment_title"   
# [5] "review_comment_message"  "review_creation_date"    "review_answer_timestamp"
reviews <- fread("./datasets/olist_order_reviews_dataset.csv", header=TRUE)
# [1] "customer_id"              "customer_unique_id"       "customer_zip_code_prefix" "customer_city"           
# [5] "customer_state"  
customers <- fread("./datasets/olist_customers_dataset.csv", header=TRUE)
# [1] "geolocation_zip_code_prefix" "geolocation_lat"             "geolocation_lng"            
# [4] "geolocation_city"            "geolocation_state"  
geo <- fread("./datasets/olist_geolocation_dataset.csv", header=TRUE)
# [1] "order_id"             "payment_sequential"   "payment_type"         "payment_installments" "payment_value"
payment <- fread("./datasets/olist_order_payments_dataset.csv", header=TRUE)
# [1] "seller_id"              "seller_zip_code_prefix" "seller_city"            "seller_state" 
seller <- fread("./datasets/olist_sellers_dataset.csv", header=TRUE)
# [1] "product_id"                 "product_category_name"      "product_name_lenght"        "product_description_lenght"
# [5] "product_photos_qty"         "product_weight_g"           "product_length_cm"          "product_height_cm"         
# [9] "product_width_cm" 
product <- fread("./datasets/olist_products_dataset.csv", header=TRUE)

# english_translation
category_eng <- fread("./datasets/product_category_name_translation.csv", header=TRUE)

#Fixing categorynames columns. font broke due to spanish?
names(category_eng) <- c('product_category_name','product_category_name_english')

# append the translated column
join(product, category_eng,
     type = "left", by = 'product_category_name') -> product

# get volume of each products in meters
product %>% 
  dplyr::mutate(product_volume_m = product_length_cm*product_height_cm*product_width_cm/100) -> product

# get total cost by summing shipping_cost and product_cost
po_items %>% 
  mutate(invoice = price + freight_value) -> po_items


po_items %>% 
  join(product, type='left') %>% 
  join(po_delivery, type='left') %>% 
  join(reviews, type='left') %>% 
  join(customers, type='left') %>% 
  join(payment, type='left') %>% 
  join(seller, type='left') %>% 
  select(customer_id,
         order_id,
         order_item_id,
         order_status,
         order_purchase_timestamp,
         order_approved_at,
         order_delivered_carrier_date,
         shipping_limit_date,
         order_delivered_customer_date,
         order_estimated_delivery_date,
         product_id,
         product_category_name_english,
         product_weight_g,
         product_volume_m,
         price,
         freight_value,
         invoice,
         review_score,
         payment_type,
         customer_zip_code_prefix,
         customer_city,
         customer_state,
         seller_id,
         seller_zip_code_prefix,
         seller_city,
         seller_state) %>% 
    rename(
      PO_date = order_purchase_timestamp, # purchase_order
      SO_date = order_approved_at, #sales_order
      DO_date = shipping_limit_date, #deliver_order
      GI_date = order_delivered_carrier_date, #goods_issue
      GR_date = order_delivered_customer_date, #goods_receipt
      c_RDD = order_estimated_delivery_date, #customer_RequiredDeliveryDate
      c_zip = customer_zip_code_prefix,
      c_city = customer_city,
      c_state = customer_state,
      product_category = product_category_name_english,
      s_zip = seller_zip_code_prefix,
      s_city = seller_city,
      s_state = seller_state) %>%
  mutate(
    PO_date = lubridate::as_datetime(PO_date),
    SO_date = lubridate::as_datetime(SO_date),
    DO_date = lubridate::as_datetime(DO_date), 
    GI_date = lubridate::as_datetime(GI_date),
    GR_date = lubridate::as_datetime(GR_date),
    c_RDD = lubridate::as_datetime(c_RDD)) %>%
  mutate(
    PO_date = lubridate::date(PO_date),
    SO_date = lubridate::date(SO_date),
    GI_date = lubridate::date(GI_date),
    DO_date = lubridate::date(DO_date),
    GR_date = lubridate::date(GR_date),
    c_RDD = lubridate::date(c_RDD)) -> po_master
    

# clean Geo Data
geo %>% 
  select(geolocation_zip_code_prefix,
         geolocation_lat,
         geolocation_lng) %>% 
  group_by(geolocation_zip_code_prefix) %>% 
  summarise(lat = mean(geolocation_lat),
         lng = mean(geolocation_lng)) %>% 
  ungroup()-> cgeo

# attach lat,lng to po_master
po_master %>% 
  left_join(cgeo, by = c("c_zip" = "geolocation_zip_code_prefix")) %>% 
  left_join(cgeo, by = c("s_zip" = "geolocation_zip_code_prefix")) %>% 
  rename(c_lat = lat.x,
         c_lng = lng.x,
         s_lat = lat.y,
         s_lng = lng.y) -> po_master

# LT data
po_master = po_master %>% 
  mutate(POtoSO = SO_date - PO_date, # duration of purchase_order to sales_order due to fraudcheck (fraud check)
         SOtoDO = DO_date - SO_date, # duration of expected seller's shipping date to carrier since the purchase (can be long due to inventory/transportation)
         SOtoGI = GI_date - SO_date, # duration of actual seller's shipping date to carrier since the purchase  (actual when order is confirmed)
         GItoGR = GR_date - GI_date, # duration of expected shipping date to customer receive (how long carrier took)
         GItoGR = GR_date - GI_date, # duration of actual shipping to customer receive (carrier to customer)
         POtoRDD = c_RDD - PO_date,  # duration of expected order purchase to customer receive (expected LeadTime for delivery)
         POtoGR = GR_date - PO_date, # duration of actual order purchase to customer receive (Actual LT for delivery)
         GRvRDD = c_RDD - GR_date,   # comparison of actual delievered date vs expected delivery date (how much faster was LT)
         DOvGI = DO_date - GI_date)  #comparison of actual delivered date vs expected delivery date to carrier (how much seller confirmed)

# update state data
View(po_master)
po_master %>% 
  left_join(brazil, by = c("c_state" = "Abbreviation")) %>% 
  left_join(brazil, by = c("s_state" = "Abbreviation")) %>% 
  mutate(c_state = State.x,
         s_state = State.y) %>% 
  subset(select=-c(State.x,State.y))->po_master


# Cleaning po_master AGAIN
po_master %>% 
  filter(!order_status=='delivered') %>% 
  View()
po_master %>% 
  mutate(
    GR_week = lubridate::as_datetime(PO_date))

po_master %>% 
  filter(GR_date<ymd('2018/08/29')) %>% 
  mutate(delivered_week = lubridate::week(ymd(GR_date)),
         delivered_year = lubridate::year(ymd(GR_date))) ->po_master
po_master %>% 
  mutate(backorder = ifelse(GRvRDD<0,1,0),
         delivered_year = as.factor(delivered_year),
         purchase_week = lubridate::week(ymd(PO_date)),
         purchase_year = lubridate::year(ymd(PO_date)),
         purchase_year=as.factor(purchase_year)) -> po_master



# Write CSV ---------------------
write.csv(po_master, file = "./datasets/po_master.csv")




# corr plot -------------------------------------------------------
po_master %>%
  na.omit ->temp
temp[, unlist(lapply(temp, is.numeric))] -> temp 
temp[,-c(9:22)] -> temp
temp[,-c(1)] ->temp
corrplot(cor(temp),type="upper")


# Lead time analysis --------------------------------------------------

# data cleaning
po_master %>% 
  select('delivered_week','delivered_year','POtoSO','SOtoGI','GItoGR') %>% 
  gather('POtoSO','SOtoGI','GItoGR',key='LT',value=days )%>% 
  na.omit() %>% 
  group_by(delivered_year,delivered_week,LT) %>% 
  summarise(mean2 = mean(days)) %>%
  ungroup() -> LT2

po_master %>% 
  na.omit %>% 
  group_by(delivered_year,delivered_week) %>% 
  summarise(m_POtoRDD = median(POtoRDD), m_POtoDO = mean(POtoSO + SOtoDO)) -> deliveryDays


ggplot() +
  geom_col(data=LT2[LT2$delivered_year==2016,],aes(x=delivered_week,y=mean2,fill=LT))+
  geom_line(data=deliveryDays[deliveryDays$delivered_year==2016,],aes(x=delivered_week,y=m_POtoRDD),linetype = "dashed",size = 1)

ggplot() +
  geom_col(data=LT2[LT2$delivered_year==2017,],aes(x=delivered_week,y=mean2,fill=LT))+
  geom_line(data=deliveryDays[deliveryDays$delivered_year==2017,],aes(x=delivered_week,y=m_POtoRDD),linetype = "dashed",size = 1) 


ggplot() +
  geom_col(data=LT2[LT2$delivered_year==2018,],aes(x=delivered_week,y=mean2,fill=LT))+
  geom_line(data=deliveryDays[deliveryDays$delivered_year==2018,],aes(x=delivered_week,y=m_POtoRDD),linetype = "dashed",size = 1)

# Sales -----------------------------------------
po_master %>%
  na.omit %>% 
  group_by(purchase_year, purchase_week) %>% 
  summarise(sale = sum(price)) -> sales

n<-dim(sales)[1]
sales %>% 
  arrange(purchase_year,purchase_week)->sales
sales<-sales[1:(n-5),]


ggplot()+
  geom_line(data = sales, aes(x=purchase_week, y=sale/1000, color=purchase_year),size = 1)+
  coord_cartesian(xlim = c(1,48)) +
  theme_bw() +
  labs(title='Sales History', x = 'Week Number', y = 'Brazilian Real in Thousands (R$)', color = 'Year') + 
  theme(legend.key=element_blank(), plot.title = element_text(hjust = 0.5)) 

View(po_master)
po_master %>% 
  filter(PO_date > 2018-06-06) %>% 


# backorder ------------------------------------------------

# data cleaning for getting backorder_rate df
po_master %>% 
  group_by(delivered_year, delivered_week) %>% 
  mutate(orderCount = n(),
         backorder = sum(GRvRDD<0),
         backorder_ratio = backorder/orderCount) %>% 
  select(product_category,c_state, seller_id, delivered_week, delivered_year,backorder, backorder_ratio, review_score) -> backorder_rate

backorder_rate %>% 
  ungroup() %>% 
  na.omit() -> backorder_rate

# back-order rate per year
ggplot()+
  geom_line(data = backorder_rate, aes(x=delivered_week, y=backorder_ratio, color=delivered_year),size = 1) +
  labs(title='Backorder Rate', x = 'Week Number', y = 'Ratio(%)', color = 'Year') +
  coord_cartesian(xlim = c(2,49)) +
  scale_y_continuous(labels=scales::percent)+
  theme_bw() + 
  theme(legend.key=element_blank(), plot.title = element_text(hjust = 0.5)) 


backorder_rate %>% 
  group_by(product_category) %>% 
  summarise(count=n(),mean(review_score)) %>% 
  arrange(desc(count))

po_master %>%
  filter(GRvRDD>0) %>% 
  summarise(mean(review_score))



# Kmean Cluster for WH placement------------------------------
# pick the best value for K meaning number of clusters



# data cleaning and scaling
po_master %>% 
  select(c_lat,c_lng) %>% 
  na.omit() ->cluster_df
test1<-scale(na.omit(data.matrix(cluster_df)))
data <- test1
set.seed(123)
# Finding Optimal Number of Clusters
# The problem of determining what will be the best value for the number of clusters is often not very clear from the data set itself.
# The elbow method looks at the percentage of variance explained as a function of the number of clusters:
# The within cluster variation is calculated as the sum of the euclidean distance between the data points and their respective clusters 
# adding a new cluster to the total variation within each cluster will be smaller than before and 
# at some point the marginal gain will drop, giving an acute angle in the graph

# to go depper in depth to Determine the optimal model, Bayesian Information Criterion for expectation-maximization is required
# Compute and plot wss for k = 2 to k = 15.
k.max <- 10
wss <- sapply(1:k.max, function(k){kmeans(data, k, nstart=50,iter.max = 10 )$tot.withinss})
plot(1:k.max, wss,type="b", pch = 19, frame = FALSE, xlab="Number of clusters K", ylab="Total within-clusters sum of squares")

# k-means with k=7
clusters <- kmeans(cluster_df,7)
# bring cluster data into df
cluster_df$clusters <- as.factor(clusters$cluster)

# graph of the cluster result
ggplot(cluster_df, aes(x=c_lng, y=c_lat, color=clusters)) +
  geom_point(alpha=.5)+
  coord_cartesian(xlim = c(-70,-35), ylim = c(-35,10)) + 
  geom_density_2d() +
  theme_bw()


# WH DATAFRAME
WH_coordinate <-  as.data.frame(clusters$centers)
city<- c('Nova Campinas', 'Serrita','Cocalinho', 'Avanhandava', 'Santana de Parnaíba', 'Muitos Capões','Ferros')
WH_coordinate <- cbind(WH_coordinate,city)
WH_coordinate


# fiding bad sellers ------------------------------------------------

po_master %>% 
  na.omit %>% 
  filter (DOvGI<0) %>% 
  group_by(seller_id,delivered_year) %>% 
  summarise(count = n()) %>% 
  arrange(desc(count))
View(po_master)

po_master %>% 
  filter(seller_id == '7c67e1448b00f6e969d365cea6b010ab' & DOvGI<0) %>% 
  View()






