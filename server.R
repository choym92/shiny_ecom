## server.R ##
shinyServer(function(input, output){
  source('./helper.R')

  
### Sales ----------------------------------------------------------------------------
  
  sales_df <- reactive({
    po_master %>% 
      na.omit %>%
      filter(purchase_year %in% input$locYear1) %>% 
      filter(purchase_week %in% input$locWeek1) %>% 
      filter(product_category %in% input$category) %>% 
      group_by(purchase_year, purchase_week) %>% 
      summarise(sale = sum(price)) %>% 
      arrange(purchase_year,purchase_week) -> sales
      sales<-sales[1:86,]
      sales %>% 
        ungroup() %>% 
        mutate(purchase_year = as.factor(as.character(purchase_year)))
  })
  output$sales_plot <- renderPlot({
    sales_df = sales_df()
    ggplot()+
      geom_line(data = sales_df, aes(x=purchase_week, y=sale/1000, color=purchase_year),size = 1.5)+
      coord_cartesian(xlim = c(2,48)) +
      theme_bw() +
      labs(title='Sales History', x = 'Week Number', y = 'Brazilian Real in Thousands (R$)', color = 'Year') + 
      theme(legend.key=element_blank(), plot.title = element_text(hjust = 0.5)) +
      annotate("rect", xmin = 1, xmax = 4, ymin = 0, ymax = 400, alpha = .2, fill='darkgreen')+
      annotate("rect", xmin = 46, xmax = 49, ymin = 0, ymax = 400, alpha = .2, fill='darkgreen') +
      annotate("rect", xmin = 22, xmax = 25, ymin = 0, ymax = 400, alpha = .2, fill='darkgreen') +
      annotate("rect", xmin = 7, xmax = 10, ymin = 0, ymax = 400, alpha = .2, fill='darkgreen')
  }, height = 580) 
  
  output$YoY <- renderInfoBox({
    sum_2018 <- po_master %>% filter(purchase_year==2018, purchase_week==33) %>% summarise(total = sum(price))
    sum_2017 <- po_master %>% filter(purchase_year==2017, purchase_week==33) %>% summarise(total = sum(price))
    YoY <- paste(as.integer((sum_2018-sum_2017)/sum_2017*100), "%", sep="")
    infoBox("YoY (Revenue)", YoY, icon = icon("chart-bar"),color='yellow')
  })
  
  output$WoW <- renderInfoBox({
    sum_ww0 <- po_master %>% filter(purchase_year==2018, purchase_week==33) %>% summarise(total = sum(price))
    sum_ww1 <- po_master %>% filter(purchase_year==2018, purchase_week==34) %>% summarise(total = sum(price))
    YoY <- paste(as.integer((sum_ww0-sum_ww1)/sum_ww1*100), "%", sep="")
    infoBox("WoW (Revenue)", YoY, icon = icon("calendar-check"))
  })
  
  output$YTD <- renderInfoBox({
    ytd <- po_master %>% filter(purchase_year %in% input$locYear1) %>% summarise(total = sum(price))
    ytd <- dollar_format()(as.integer(ytd))
    infoBox("YTD (Revenue)",  ytd, icon = icon("dollar-sign"),color='green')
  })
  
  output$oWoW <- renderInfoBox({
    sum_ww0 <- po_master %>% filter(purchase_year==2018, purchase_week==33) %>% summarise(total = n())
    sum_ww1 <- po_master %>% filter(purchase_year==2018, purchase_week==34) %>% summarise(total = n())
    YoY <- paste(as.integer((sum_ww0-sum_ww1)/sum_ww1*100), "%", sep="")
    infoBox("WoW (Orders)", YoY, icon = icon("shopping-cart"),color='red')
  })
#------------------------------------------------------------------------------------

### Backorder ---------------------------------------------------------------------
  backorder_df <- reactive({
    po_master %>% 
      filter(purchase_year %in% input$locYear1) %>% 
      filter(purchase_week %in% input$locWeek1) %>% 
      filter(product_category %in% input$category) %>%
      filter(c_state %in% input$locInput) %>% 
      group_by(delivered_year, delivered_week) %>% 
      mutate(orderCount = n(),
             backorder = sum(GRvRDD<0),
             backorder_ratio = backorder/orderCount) %>% 
      select(product_category,c_state, seller_id, delivered_week, delivered_year,backorder, backorder_ratio, review_score) %>% 
      ungroup() %>% 
      na.omit() %>% 
      mutate(delivered_year = as.factor(delivered_year))
  })

  output$backorder_plot <- renderPlot({
    backorder_df = backorder_df()
    ggplot()+
      geom_line(data = backorder_df, aes(x=delivered_week, y=backorder_ratio, color=delivered_year),size = 1.5) +
      labs(title='Backorder Rate', x = 'Week Number', y = 'Ratio(%)', color = 'Year') +
      coord_cartesian(xlim = c(2,49)) +
      scale_y_continuous(labels=scales::percent)+
      theme_bw() + 
      theme(legend.key=element_blank(), plot.title = element_text(hjust = 0.5))+ geom_hline(yintercept=.05, linetype="dashed", 
                                                                                            color = "red", size=1.5)     
    
  }, height = 500)

  output$corr_plot <- renderPlot({
    corrplot(cor(temp3),type="upper")
  },width = 300, height = 300)
  
  

  output$bshop <- renderInfoBox({
    shopper <- po_master %>% na.omit %>% filter (DOvGI<0) %>% group_by(seller_id) %>% summarise(count = n()) %>% arrange(desc(count))
    seller <- paste("Bad Seller:",as.character(shopper[1,1]),sep = " ")
    scount <- paste("Late Count:",as.integer(shopper[1,2]), sep = " ")
    infoBox(seller, scount, icon = icon("shopping-cart"),color='red')
  })
  output$bcat <- renderInfoBox({
    po_master %>% 
      na.omit %>% 
      filter (DOvGI<0) %>% 
      group_by(product_category) %>% 
      summarise(count = n()) %>% 
      arrange(desc(count)) -> bcat
    seller <- paste("Bad Category:",as.character(bcat[1,1]),sep = " ")
    scount <- paste("Late Count:",as.integer(bcat[1,2]), sep = " ")
    infoBox(seller, scount, icon = icon("shopping-cart"),color='red')
  })
  
  

  
### LT -------------------------------------------------------------------------------
  LT_df <- reactive({
    LT2 %>% 
      filter(delivered_year %in% input$locYear)%>% 
      filter(delivered_week %in% input$locWeek) %>% 
      filter(c_state %in% input$locInput) %>% 
      group_by(delivered_year,delivered_week,LT) %>% 
      summarise(mean2 = mean(days)) %>%
      ungroup()
  })
  dD_df <- reactive({
    po_master %>% 
      na.omit %>% 
      filter(delivered_year %in% input$locYear) %>% 
      
      group_by(delivered_year,delivered_week)%>%
      summarise(m_POtoRDD = median(POtoRDD), m_POtoDO = mean(POtoSO + SOtoDO))
  })
  output$LT_plot <- renderPlot({
    LT_df = LT_df()
    dD_df = dD_df()
    ggplot() +
      geom_col(data=LT_df,aes(x=delivered_week,y=mean2,fill=LT))+
      geom_line(data=dD_df,aes(x=delivered_week,y=m_POtoRDD),linetype = "dashed",size = 1, label = 'POtoRDD')+
      theme_bw() +
      labs(title='Lead Time: Order Purchase to Delivery', x = 'Week Number', y = 'Number of Days (average)', color = 'Year')+ 
      theme(legend.key=element_blank(), plot.title = element_text(size=15, face='bold',hjust = 0.5)) +
      coord_cartesian(xlim = c(3,51))
  }, height = 520)
  
  
  DDperState<- reactive({
    po_master %>% 
      filter(PO_date>=input$dates[1],PO_date<=input$dates[2]) %>% 
      filter(product_category %in% input$category2) %>% 
      group_by(c_state) %>% 
      summarise(a = mean(POtoGR), b = mean(review_score))
  })

  output$LT_plot2<-renderPlot({
    DDperState = DDperState()
    ggplot(DDperState, aes(c_state,a,group=c_state))+
      geom_bar(stat="identity",aes(reorder(c_state, -a, sum),fill=a))+
      scale_fill_gradient(low="#56B1F7", high='black')+ 
      labs(title="Average Delivery Days per State", 
           x = 'State',
           y = 'Day') +
      theme_bw()+
      theme(legend.position = "none",axis.text.x = element_text(angle=45, vjust=0.6), plot.title = element_text(hjust = 0.5))
  })
  LTperCAT<- reactive({
    po_master %>% 
      gather('POtoSO','SOtoDO','SOtoGI','GItoGR','POtoRDD','POtoGR',key='LT',value=days )%>% 
      filter(LT==input$LTtype) %>% 
      na.omit %>% 
      group_by(product_category) %>% 
      summarise(a=mean(days)) %>% 
      arrange(desc(a))  
  })
  output$LT_plot3<-renderPlot({
    LTperCAT = LTperCAT()
    ggplot(LTperCAT, aes(product_category,a,group=product_category))+
      geom_bar(stat="identity",aes(reorder(product_category, -a, sum),fill=a))+
      scale_fill_gradient(low="#56B1F7", high='black')+ 
      labs(title="Average Delivery Days per State", 
           x = 'State',
           y = 'Day') +
      theme_bw()+
      theme(legend.position = "none",axis.text.x = element_text(angle=45, vjust=0.6), plot.title = element_text(hjust = 0.5))
    
  }, height = 620)
  
  
  
### K-mean ----------------------------------------------------------------------------------
  
  output$k_op <- renderPlot({
    plot(1:k.max, wss,type="b", pch = 19, frame = FALSE, xlab="Number of clusters K", ylab="Total within-clusters sum of squares")
  })

  
  # graph of the cluster result
  output$k_plot <- renderPlot({
    ggplot(cluster_df, aes(x=c_lng, y=c_lat, color=clusters)) +
      geom_point(alpha=.5)+
      coord_cartesian(xlim = c(-70,-35), ylim = c(-35,10)) + 
      geom_density_2d() +
      theme_bw()
  })
  
  
  
})


  

### DT -------------------------------------------------------------------------------------


  # # show data using DataTable
  # output$table <- DT::renderDataTable({
  #   datatable(po_master, rownames=FALSE) %>% 
  #     formatStyle(input$text,  
  #                 background="skyblue", fontWeight='bold')
  #   # Highlight selected column using formatStyle
  # })