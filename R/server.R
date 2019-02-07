sliderText <- function(input, output, session, show) {
  output$number <- renderText({
    if (show()) {
      input$slider
    } else {
      NULL
    }
  })
  reactive({
    input$slider + 5
  })
}

shine_server <- function(input, output) {
  display <- reactive({
    input$display
  })
  num <- callModule(sliderText, "module", display)
  output$value <- renderText({
    paste0("slider1+5: ", num())
  })
}