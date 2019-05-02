library(data.table)
library(leaflet)
library(sp)
library(tmap)
library(spData)
library(plyr)
library(tidyr)
library(lubridate)
library(dplyr)

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


po_master %>% 
  filter(!order_status=='delivered') %>% 
  View()
po_master %>% 
  mutate(
    GR_week = lubridate::as_datetime(PO_date))




write.csv(po_master, file = "po_master.csv")



library(tidyverse)
library(googleVis)
library(leaflet)
library(maps)
library(datasets)

reviews = read.csv('datasets/olist_order_reviews_dataset.csv',
                   stringsAsFactors = F)
payments = read.csv('datasets/olist_order_payments_dataset.csv',
                    stringsAsFactors = F)
orders = read.csv('datasets/olist_orders_dataset.csv',
                  stringsAsFactors = F)
customer = read.csv('datasets/olist_customers_dataset.csv',
                    stringsAsFactors = F)
products = read.csv('datasets/olist_products_dataset.csv',
                    stringsAsFactors = F)
items = read.csv('datasets/olist_order_items_dataset.csv',
                 stringsAsFactors = F)
sellers = read.csv('datasets/olist_sellers_dataset.csv',
                   stringsAsFactors = F)
geolocation = read.csv('datasets/olist_geolocation_dataset.csv',
                       stringsAsFactors = F)
categorynames = read.csv('datasets/product_category_name_translation.csv',
                         stringsAsFactors = F)


names(categorynames)
names(categorynames) <- c('product_category_name','product_category_name_english')
cleaned_cat = products %>%
  select(product_id, product_category_name) %>%
  left_join(categorynames, by = 'product_category_name') %>%
  select(-2)


cleaned_cat




# Cleaning Geographical data
cleaned_geo = geolocation %>%
  select(geolocation_zip_code_prefix,
         geolocation_lat,
         geolocation_lng) %>%
  group_by(geolocation_zip_code_prefix) %>%
  summarise(lat = mean(geolocation_lat),
            lng = mean(geolocation_lng))

# Cleaning Payment Table
cleaned_pay = payments %>%
  group_by(order_id) %>%
  summarise(value = sum(payment_value))

shipping_cost = items %>%
  group_by(order_id) %>%
  summarise(shipping_cost = sum(freight_value))

# Joining all tables
joined_order = orders %>%
  left_join(cleaned_pay, by = "order_id") %>%
  left_join(customer, by = "customer_id") %>%
  left_join(cleaned_geo,
            by = c("customer_zip_code_prefix" = "geolocation_zip_code_prefix")) %>%
  left_join(reviews, by = "order_id") %>%
  left_join(shipping_cost, by = "order_id") %>%
  left_join(items, by = "order_id") %>%
  left_join(cleaned_cat, by = "product_id") %>%
  select(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    value,
    customer_unique_id,
    customer_zip_code_prefix,
    lat,
    lng,
    customer_city,
    customer_state,
    review_score,
    product_id,
    product_category_name_english,
    shipping_cost
  ) 

# Cleaning Gaint Table Data
final_order = joined_order %>%
  filter(order_status != "canceled" & value > 0) %>%
  rename(
    purchase_date = order_purchase_timestamp,
    delivered_date = order_delivered_customer_date,
    est_delivered_date = order_estimated_delivery_date,
    zip = customer_zip_code_prefix,
    city = customer_city,
    state = customer_state,
    product_category = product_category_name_english
  ) %>%
  mutate(
    purchase_date = lubridate::as_datetime(purchase_date),
    delivered_date = lubridate::as_datetime(delivered_date),
    est_delivered_date = lubridate::as_datetime(est_delivered_date)
  ) %>%
  distinct() %>%
  mutate(
    purchase_date = lubridate::date(purchase_date),
    delivered_date = lubridate::date(delivered_date),
    est_delivered_date = lubridate::date(est_delivered_date)
  ) %>%
  mutate(delivery_days = delivered_date - purchase_date,
         diff_estdel = est_delivered_date - delivered_date) %>%
  mutate(
    product_category = case_when(
      product_category == "home_appliances_2" ~ "home_appliances",
      product_category == "home_comfort_2" ~ "home_comfort",
      product_category == "home_confort" ~ "home_comfort",
      product_category == "fashio_female_clothing" ~ "fashion_female_clothing",
      product_category == "art" ~ "arts_and_craftmanship",
      product_category == "drinks" |
        product_category == "food" ~ "food_drink",
      TRUE ~ as.character(product_category)
    )
  )



# Generating df for geo analysis
geo_df = final_order %>%
  filter(
    is.na(shipping_cost) == F &
      is.na(delivery_days) == F &
      is.na(review_score) == F,
    is.na(diff_estdel) == F
  ) %>%
  group_by(state) %>%
  summarise(
    .
    sales = sum(value),
    salesperorder = round(sum(value) / n(), 2),
    avg_shipcost = round(mean(shipping_cost), 2),
    avg_shcsratio = round(mean(shipping_cost / value), 2),
    avg_delidays = round(mean(delivery_days), 2),
    avg_review = round(mean(review_score), 3),
    avg_diffestdel = round(mean(diff_estdel), 2)
  ) %>%
  mutate(state = case_when(state == "AC" ~ "Acre",
                           state == "AL" ~ "Alagoas",
                           state == "AP" ~ "Amapá",
                           state == "AM" ~ "Amazonas",
                           state == "BA" ~ "Bahia", 
                           state == "CE" ~ "Ceará", 
                           state == "DF" ~ "Distrito Federal",
                           state == "ES" ~ "Espírito Santo",
                           state == "GO" ~ "Goiás",
                           state == "MA" ~ "Maranhão", 
                           state == "MT" ~ "Mato Grosso",
                           state == "MS" ~ "Mato Grosso do Sul",
                           state == "MG" ~ "Minas Gerais",
                           state == "PA" ~ "Pará",
                           state == "PB" ~ "Paraíba",
                           state == "PR" ~ "Paraná",
                           state == "PE" ~ "Pernambuco",
                           state == "PI" ~ "Piauí",
                           state == "RJ" ~ "Rio de Janeiro",
                           state == "RN" ~ "Rio Grande do Norte",
                           state == "RS" ~ "Rio Grande do Sul",
                           state == "RO" ~ "Rondônia",
                           state == "RR" ~ "Roraima",
                           state == "SC" ~ "Santa Catarina",
                           state == "SP" ~ "São Paulo",
                           state == "SE" ~ "Sergipe",
                           state == "TO" ~ "Tocantins",
                           TRUE ~ as.character(state)))

# Generating analysis by time
time_df = final_order %>%
  filter(is.na(purchase_date) == F) %>%
  mutate(purchase_date = as.Date(purchase_date)) %>%
  group_by(purchase_date) %>%
  summarise(salesbyday = sum(value))

# Generating analysis by categories
detailed_cat_df = final_order %>%
  filter(is.na(product_category) == F) %>%
  group_by(product_category) %>%
  summarise(
    total_sales = sum(value),
    salesperitem = round(sum(value) / n(), 2),
    avg_review = round(mean(review_score), 3)) 

detailed_cat_df = detailed_cat_df %>% 
  mutate(category = case_when(product_category %in% c("health_beauty", "perfumery", "diapers_and_hygiene") ~ "Chemists.Drgustores", 
                              product_category %in% c("watches_gifts", "fashion_bags_accessories", "luggage_accessories", "fashion_shoes", 
                                                      "fashion_male_clothing", "fashion_female_clothing", "fashion_childrens_clothes", 
                                                      "fashion_underwear_beach") ~ "Clothing",
                              product_category %in% c("cool_stuff", "construction_tools_construction", "home_construction", "construction_tools_lights", 
                                                      "construction_tools_safety", "arts_and_craftmanship", "costruction_tools_tools") ~ "DIY Goods",
                              product_category %in% c("computers_accessories", "telephony", "computers", "electronics", "consoles_games", 
                                                      "fixed_telephony", "air_conditioning", "tablets_printing_image", "cine_photo") ~ "Eletrical Goods",
                              product_category %in% c("food_drink", "la_cuisine", "flowers") ~ "Food.Consumables", 
                              product_category %in% c("furniture_decor", "office_furniture", "furniture_living_room", "home_comfort", 
                                                      "kitchen_dining_laundry_garden_furniture", "small_appliances_home_oven_and_coffee", 
                                                      "furniture_bedroom", "furniture_mattress_and_upholstery") ~ "Furniture.Carpets",
                              product_category %in% c("garden_tools", "costruction_tools_garden") ~ "Garden Products", 
                              product_category %in% c("bed_bath_table", "housewares", "auto", "toys", "baby", "stationery", "pet_shop",
                                                      "pet_shop", "home_appliances", "small_appliances", "party_supplies", "christmas_supplies") ~ "Household.Textiles", 
                              product_category %in% c("musical_instruments", "audio", "cds_dvds_musicals", "dvds_blu_ray", "music", "books_imported", 
                                                      "books_technical", "books_general_interest") ~ "Music, Films.Books",
                              product_category %in% c("sports_leisure", "fashion_sport") ~ "Sports Equipments", 
                              product_category %in% c("market_place", "agro_industry_and_commerce", "industry_commerce_and_business", "signaling_and_security",
                                                      "security_and_services") ~ "Services", 
                              TRUE ~ "Other")) %>%
  rename(sub_category = product_category)

cat_df = detailed_cat_df %>%
  group_by(category) %>%
  summarise(total_sales = mean(total_sales), aov = mean(salesperitem), avg_review = mean(avg_review))



# Categrorical sales by time
time_df2 = time_df %>%
  rename(sales = salesbyday) %>%
  mutate(category = "Total Sales") %>%
  select(purchase_date, category, sales)

cat_time_df = final_order %>%
  filter(is.na(product_category) == F) %>%
  mutate(category = case_when(product_category %in% c("health_beauty", "perfumery", "diapers_and_hygiene") ~ "Chemists.Drgustores", 
                              product_category %in% c("watches_gifts", "fashion_bags_accessories", "luggage_accessories", "fashion_shoes", 
                                                      "fashion_male_clothing", "fashion_female_clothing", "fashion_childrens_clothes", 
                                                      "fashion_underwear_beach") ~ "Clothing",
                              product_category %in% c("cool_stuff", "construction_tools_construction", "home_construction", "construction_tools_lights", 
                                                      "construction_tools_safety", "arts_and_craftmanship", "costruction_tools_tools") ~ "DIY Goods",
                              product_category %in% c("computers_accessories", "telephony", "computers", "electronics", "consoles_games", 
                                                      "fixed_telephony", "air_conditioning", "tablets_printing_image", "cine_photo") ~ "Eletrical Goods",
                              product_category %in% c("food_drink", "la_cuisine", "flowers") ~ "Food.Consumables", 
                              product_category %in% c("furniture_decor", "office_furniture", "furniture_living_room", "home_comfort", 
                                                      "kitchen_dining_laundry_garden_furniture", "small_appliances_home_oven_and_coffee", 
                                                      "furniture_bedroom", "furniture_mattress_and_upholstery") ~ "Furniture.Carpets",
                              product_category %in% c("garden_tools", "costruction_tools_garden") ~ "Garden Products", 
                              product_category %in% c("bed_bath_table", "housewares", "auto", "toys", "baby", "stationery", "pet_shop",
                                                      "pet_shop", "home_appliances", "small_appliances", "party_supplies", "christmas_supplies") ~ "Household.Textiles", 
                              product_category %in% c("musical_instruments", "audio", "cds_dvds_musicals", "dvds_blu_ray", "music", "books_imported", 
                                                      "books_technical", "books_general_interest") ~ "Music, Films.Books",
                              product_category %in% c("sports_leisure", "fashion_sport") ~ "Sports Equipments", 
                              product_category %in% c("market_place", "agro_industry_and_commerce", "industry_commerce_and_business", "signaling_and_security",
                                                      "security_and_services") ~ "Services", 
                              TRUE ~ "Other")) %>%
  group_by(purchase_date, category) %>%
  summarise(sales = sum(value)) %>%
  bind_rows(time_df2) %>%
  spread(key = "category", value = "sales")
