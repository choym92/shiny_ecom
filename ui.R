## ui.R ##
library(shinydashboard)

shinyUI(dashboardPage(skin = "black",
                      
                      
                      ##Dashboard Header-------------
  dashboardHeader(title = "E-Commerce Demand Fulfillment Dashboard", titleWidth = 450),
  ##Dashboard Sidebar----------------
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Lead Time", tabName = "LT", icon = icon("shipping-fast")),
      menuItem("Geographic", tabName = "geo", icon = icon("map")),
      menuItem("About", tabName = "about", icon = icon("info"))
      )
    ),
  ##Dashboard Body----------------
  dashboardBody(        
    tabItems(
      tabItem(tabName = "about",
              fluidRow(
                box(background = "navy",id = "home",solidHeader = TRUE,width = 12, 
                    h1("About the Project...", align = 'center'), 
                    br(),
                    h3("Supply Chain Management, especially order management side of it, may not sound much interesting to many people. However, it is very important part of the industry which can be improved greatly and there is a huge potential there.
                        Supply Chain network overall is extremely long and complicated process and saving 3-5% of transportation or inventory stocking cost is a big deal to many companies."), 
                    h3("As seen by the fall of giant brick-and-mortar stores such as Sears, Maceys JCPenney..., e-commerce is a must option for retail companies going forward. As many of you all experinced, one of the biggest differentiators between the Amazon and other online retailers' is the speed of delivery."),
                    h3("The motive of this is to visualize the time sensitive e-com data from the company Olist for product run-rate analysis to pinpoint the optimal retail insights by providing sales and retail capacity indexes."),
                    br(),br(),
                    img(src = "scm.png", height = 600, width=795),
                    img(src = "data_schema.png", align = 'center', height = 600, width = 795),
                    p(em("This is a Brazilian e-commerce public dataset of orders made at Olist Store. The dataset has information of 100k orders from 2016 to 2018 made at multiple marketplaces in Brazil. (src: Kaggle)", align='center', style = "font-si25pt"))
                    ))
              ),
      tabItem(tabName = "LT",
              fluidRow(
                column(2,
                       box("Sidebar")
                       ),
                column(10,
                box(plotOutput("plot1", height = 250)),
                box(title = "Controls", sliderInput("slider", "Number of observations:", 1, 100, 50))
                )
              )),
      tabItem(tabName = "geo",
              fluidRow(
                column(
                  width = 9,
                  box(
                    title = "Map",
                    solidHeader = T,
                    status = "info",
                    leafletOutput("geo", height = 800),
                    width = NULL,
                    height = "auto"
                  )),
                column(
                  width = 3,
                  box(title = "Select to Plot", solidHeader = T,
                    width = NULL,
                    status = "info"
                    # , selectizeInput("geoin", label = NULL, geo_choices)
                  ),
                  box(
                    
                  )
                  )
                )
              )
      )
    )
  )
)
#A lead time is the latency between the initiation and execution of a process. For example, the lead time between the placement of an order and delivery