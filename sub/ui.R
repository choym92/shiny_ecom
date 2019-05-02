## ui.R ##
shinyUI(
  dashboardPage(
    dashboardHeader(title = "Title"),
    
    dashboardSidebar(sidebarUserPanel("Your Name",
                          image = 'data:image/png;base64,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'),
                     
                     sidebarMenu(
                       menuItem("Map", tabName = "map", icon = icon("map-marked-alt")),
                       menuItem("Back Order", tabname = "backorder", icon = icon("database")),
                       menuItem("Data", tabName = "data", icon = icon("database"))
                       )
                     ),
    
    
    
    dashboardBody(
      tabItems(
        tabItem(tabName = "map",
                'fluidRow(box(htmlOutput("map"), height = 400))'
                ),
        tabItem(tabName = "data",
                'fluidRow(infoBoxOutput("maxBox"),width = 6),
                fluidRow(box(DT::dataTableOutput("table"), width = 12))'
                ),
        tabItem(tabName ='backorder',
                'aa'
                )
        
        
        
        )
    )
  )
)
