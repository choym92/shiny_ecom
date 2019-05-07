
### Sales # ---------------------------------------------------------------------------------

a <- po_master[-c(40:53)]
a %>%
  na.omit -> a
Filter(is.numeric, a) -> temp3
temp3[,-c(1,9:14,15:24,26,29,28)] -> temp3



### LT # ---------------------------------------------------------------------------------
# data cleaning
po_master %>% 
  select('delivered_week','delivered_year','POtoSO','SOtoGI','GItoGR','c_state') %>% 
  gather('POtoSO','SOtoGI','GItoGR',key='LT',value=days )%>% 
  na.omit()  -> LT2


LTtype <- c('POtoSO','SOtoDO','SOtoGI','GItoGR','POtoRDD','POtoGR')

#-------------------------------------------------------------------------------------------

po_master %>% 
  select(c_lat,c_lng) %>% 
  na.omit() ->cluster_df
test1<-scale(na.omit(data.matrix(cluster_df)))
data <- test1
set.seed(123)

k.max <- 10
# wss <- sapply(1:k.max, function(k){kmeans(data, k, nstart=30,iter.max = 10 )$tot.withinss})
wss <- c(229002.00, 122816.76,  81439.26,  60885.26,  44202.21,  35547.20,  27490.15,  23758.06,  21126.72,  17679.27)


# k-means with k=7
clusters <- kmeans(cluster_df,5)
# bring cluster data into df
cluster_df$clusters <- as.factor(clusters$cluster)






















