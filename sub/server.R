## server.R ##
shinyServer(
  function(input, output){
    # show data using DataTable
    output$table <- DT::renderDataTable({
      datatable(geo_df, rownames=FALSE) %>% 
        formatStyle(input$selected,  
                    background="skyblue", fontWeight='bold')
      # Highlight selected column using formatStyle.
    })
    # show statistics using infoBox
    output$maxBox <- renderInfoBox({
      max_value <- max(geo_df[,input$selected])
      max_state <- 
        geo_df$geolocation_state[geo_df[,input$selected]==max_value]
      infoBox(max_state, max_value, icon = icon("hand-o-up"))
    })
  }
)