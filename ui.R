## ui.R ##

shinyUI(dashboardPage(skin = "black",
                      
                      
                      ##Dashboard Header-------------
  dashboardHeader(title = "E-Commerce Demand Fulfillment Dashboard", titleWidth = 450),
  ##Dashboard Sidebar----------------
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Sales", tabName = "sales", icon = icon("chart-line")),
      menuItem("Lead Time", tabName = "LT", icon = icon("shipping-fast")),
      menuItem("Backorder", tabName = "backorder", icon = icon("step-backward")),
      menuItem("Conclusion", tabName = "conclusion", icon = icon("globe-americas"))
      )
    ),
###About #----------------
  dashboardBody(        
    tabItems(
      tabItem(tabName = "home",
              fluidRow(
                box(img(src = "scm.png", height = 450, width=510),width = 5,height=470),
                
                box(id = "home",solidHeader = TRUE,height=470,width = 7, 
                    h1("About the Project...", align = 'center'), 
                    br(),
                    p("Supply Chain Management, especially order management side of it, may not sound much interesting to many people. However, sales and operation part of the business is extremly important in the retail industry which can be improved greatly and there is a huge potential just like demand forecasting.", style = "font-size:18px")
                    ,br(),p("Supply Chain network overall is extremely long and complicated process and saving 3-5% of transportation or inventory stocking cost is a big deal to many companies.", style = "font-size:18px"), 
                    p("As seen from decrease of giant brick-and-mortar stores such as Sears, Macy's JCPenney,K-Mart...., e-commerce is a must option for retail companies. As many people have experinced, one of the biggest differentiators between the Amazon and other online retailers' is the speed of delivery.", style = "font-size:18px"),
                    p("The motive of this is to visualize the time sensitive e-com data from the company Olist for product run-rate analysis to pinpoint the optimal retail insights by providing sales and retail capacity indexes.", style = "font-size:18px")
                    ),
                box(img(src = "data_schema.png", height = 500, width=510),width = 5,height=530),
                box(width = 7,height=530,
                    tags$strong("order_dataset:"), p("1) order_id 2) customer_id 3) order_status 4)order_purchase_timestamp 5)order_approved_at 6) order_delivered_carrier_date 7) order_delivered_customer_date 8) order_estimated_delivery_date"),
                    tags$strong("items_dataset:"), p("1) order_id 2) order_item_id 3) product_id 4)seller_id 5)shipping_limit_date 6) price 7) freight_value"),
                    tags$strong("reviews_dataset:"), p("1)review_id 2) order_id 3) review_score 4)review_comment_title 5)review_comment_message 6) review_creation_date 7) review_answer_timestamp"),
                    tags$strong("customers_dataset:"), p("1) customer_id 2) customer_unique_id 3) customer_zip_code_prefix 4)customer_city 5)customer_state"),
                    tags$strong("payments_dataset:"), p("1) seller_id 2) seller_zip_code_prefix 3) seller_city 4)seller_state"),
                    tags$strong("sellers_dataset:"), p("1) product_id 2) product_category_name 3) product_name_lenght 4)product_description_lenght 5)product_photos_qty 6)product_weight_g 7)product_length_cm 8) product_height_cm 9)product_width_cm"),
                    tags$strong("geolocation_dataset:"), p("1) geolocation_zip_code_prefix 2) geolocation_lat 3) geolocation_lng 4)geolocation_city 5)geolocation_state"),
                    tags$strong("category_name_translation:"), p("1)  product_category_name 2)product_category_name_english"),
                    em("This is a Brazilian e-commerce public dataset of orders made at Olist Store. The dataset has information of 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil. (src: Kaggle)", align='center', style = "font-si25pt")
                    )
                  
                    )
              ),

### Sales #------------------------------------------------------------------------------------------------
        tabItem(tabName = "sales",
                fluidRow(column(12,box(
                        dropdownButton(
                          tags$h3("List of Input"),
                          selectInput(inputId = "locYear1", "Year", choices=Years, selected = Years, multiple = T, width='auto'),
                          selectInput(inputId = "category", "Category", choices=category, selected =category, multiple = T, width='auto'),
                          circle = TRUE, status = "success", icon = icon("gear"), width = "300px",
                          tooltip = tooltipOptions(title = "Click to see inputs !")
                        ),
                        pickerInput(inputId = "locWeek1", "Week", choices=c(1:52), selected =c(1:52), options = list(`actions-box` = TRUE),multiple = T, width='auto'),width=2, height=140),
                        box(infoBoxOutput('YoY',width=3),infoBoxOutput('WoW',width=3),infoBoxOutput('oWoW',width=3),infoBoxOutput('YTD',width=3),width=10, height=140),
                  
                fluidRow(column(12, plotOutput(outputId = "sales_plot")))
                  
                ))), 

### Backorder #---------------------------------------------------------------------------------------------------
tabItem(tabName = "backorder",
        fluidRow(column(12,
              box(width=3, height=230,
                 dropdownButton(
                   tags$h3("List of Input"),
                   selectInput(inputId = "locYear1", "Year", choices=Years, selected = Years, multiple = T, width='auto'),
                   selectInput(inputId = "category", "Category", choices=category, selected =category, multiple = T, width='auto'),
                   circle = TRUE, status = "danger", icon = icon("gear"), width = "300px",
                   tooltip = tooltipOptions(title = "Click to see inputs !")),
                 pickerInput(inputId = "locInput", "Location", choices=BRstates, selected = BRstates[1:27], options = list(`actions-box` = TRUE),multiple = T, width='auto'),
                 pickerInput(inputId = "locWeek", "Week", choices=c(1:52), selected =c(1:52), options = list(`actions-box` = TRUE),multiple = T, width='auto')),
              box(width=6, height=230,infoBoxOutput('bshop',width=9),br(),br(),br(),br(),br(),br(),br(),tags$strong("Problem:"), br(),"Customer Satisfaction: Backorder Ratio is on very high side the fact that Customer RDD is ~30 days"),
              box(width=3,img(src = "corr111.png", height = 220, width=270))),
        
        fluidRow(column(12, plotOutput(outputId = "backorder_plot")))
        )
        ),




### LT #---------------------------------------------------------------------------------------------------
      tabItem(tabName = "LT",
          tabsetPanel(
            tabPanel('Lead Time',
              fluidRow(column(12,
                      box(width=3,
                          dropdownButton(
                            tags$h3("List of Input"),
                            pickerInput(inputId = "locWeek", "Week", choices=c(1:52), selected =c(1:52), options = list(`actions-box` = TRUE),multiple = T, width='auto'),
                            selectInput(inputId = "category", "Category", choices=category, selected =category, multiple = T, width='auto'),
                            circle = TRUE, status = "danger", icon = icon("gear"), width = "300px",
                            tooltip = tooltipOptions(title = "Click to see inputs !")),
                      pickerInput(inputId = "locInput", "Location", choices=BRstates, selected = BRstates[1:27], options = list(`actions-box` = TRUE),multiple = T, width='auto'),
                      pickerInput(inputId = "locYear", "Year", choices=Years, selected = Years[2], options = list(`actions-box` = TRUE),multiple = F, width='auto')),
                      box(width=3,
                          tags$strong("Problem:"), br(), "1) Customer RDD is often set too far off: unable to priortize order-inventory consumption",br(),"2) Carrier holds on to the product for too long: inventory stocking cost & vulnerability of theft/ opportunity loss")
                       ,box(width=6,h4('SAP (SCM Module) Index:'),
                             tags$strong("PO:"),"Purchase Order", HTML('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'),
                             tags$strong("SO:"),"Sales Order",  HTML('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'),
                             tags$strong("GI:"),"Goods Issue", HTML('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'),
                             tags$strong("GR:"),"Goods Receipt",br(),
                             tags$strong("POtoSO:"),"duration of purchase_order to sales_order (ex. system ETL, fraud check)", br(),
                             tags$strong("SOtoGI:"),"duration of seller shipping to carrier (Often delayed due to supply limitation)", br(),
                             tags$strong("GItoGR:"),"duration of carrier shipping to end customer (how long carrier took)")
            )),
            fluidRow(column(12, plotOutput(outputId = "LT_plot")))
            ),
            tabPanel('Details',
                     fluidRow(column(3,dateRangeInput("dates", label = h3("Date range"),start="2016-09-15",min="2016-09-15", max = "2018-08-27",end= "2018-08-27"),
                                     selectInput(inputId = "category2", "Category", choices=category, selected =category, multiple = T, width='auto'),
                                     pickerInput(inputId = "LTtype", "Type", choices=LTtype, selected =LTtype[3], options = list(`actions-box` = TRUE),multiple = T, width='auto')),
                              column(9,plotOutput(outputId = "LT_plot2"),br(),plotOutput(outputId = "LT_plot3"))))
                     
        )),
### k-mean #----------------------------------------------------------------------------
      tabItem(tabName = "conclusion",
              fluidRow(column(12,box(width=6, height=780,h4("Choosing WH Location"),
                h4("If we need to choose specific city in Brazil for locating warehouses, where would it be?"),
                "The elbow method was used to determine what will be the best value for K for K-means clustering which can clarify fuzzy coodinate data.",br(),
                "It looks at the percentage of variance explained as a function of the number of clusters:",plotOutput(outputId = 'k_op'),
                "The within cluster variation is calculated as the sum of the euclidean distance between the data points and their respective clusters centroid",
                "adding a new cluster to the total variation within each cluster will be smaller than before and at some point the marginal gain will drop, giving an acute angle in the graph"
                ,br(),br(),"Below is the Ideal Carrier/WH Locations per cluster:",br(),img(src = "wh_city.png", height = 150, width=500)),
                img(src = "Rplot.png", height = 700, width=500)))
                # to go deeper in depth to Determine the optimal model, Bayesian Information Criterion for expectation-maximization is required
                # Compute and plot wss for k = 2 to k = 15
                #plotOutput(outputId = 'k_plot')))
              )

        )
      
    )
  )
)
#A lead time is the latency between the initiation and execution of a process. For example, the lead time between the placement of an order and delivery