library(rmarkdown)

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
  output$report <- output$report <- downloadHandler(
    # For PDF output, change this to "report.pdf"
    filename = "report.docx",
    content = function(file) {
      # Copy the report file to a temporary directory before processing it, in
      # case we don't have write permissions to the current working dir (which
      # can happen when deployed).
      tempReport <- file.path(tempdir(), "report.Rmd")
      file.copy("report.Rmd", tempReport, overwrite = TRUE)

      # Set up parameters to pass to Rmd document
      params <- input$slider

      # Knit the document, passing in the `params` list, and eval it in a
      # child of the global environment (this isolates the code in the document
      # from the code in this app).
      rmarkdown::render(tempReport,
        output_file = file,
        params = params,
        envir = new.env(parent = globalenv())
      )
    }
  )
}
