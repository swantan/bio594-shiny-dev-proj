
library(rmarkdown)
library(pool)
library(config)
library(DBI)
library(RPostgreSQL)


get_db_pool <- function(config) {
  # create db pool per https://shiny.rstudio.com/articles/pool-basics.html

  pgsqldrv <- dbDriver("PostgreSQL")

  pool <- dbPool(
    drv = pgsqldrv,
    user = config$netsuite$user,
    password = config$netsuite$password,
    dbname = config$netsuite$dbname,
    host = config$netsuite$host
  )

  return(pool)
}

load_vendors <- function(pool) {
  query <- "
    select
      vendor_id,
      companyname
    from netsuite.vendors
    where vendor_type_id = 5
    order by companyname;
  "
  vendors <- dbGetQuery(pool, query)

  return(vendors)
}

load_subsidiaries <- function(pool) {
  query <- "
    SELECT
      subsidiary_id,
      name
    FROM
      netsuite.subsidiaries;
  "

  subsidiaries <- dbGetQuery(pool, query)

  return(subsidiaries)
}

load_brands <- function(pool) {
  query <- "
    SELECT
      brand_id,
      brand_name
    FROM
      netsuite.brand
    ORDER BY
      brand_name;
  "

  brands <- dbGetQuery(pool, query)
}

shine_server <- function(input, output, session) {
  # load config file
  config <- config::get()
  # get a db pool
  pool <- get_db_pool(config)
  # load 'constant' data
  vendors <- load_vendors(pool)
  subsidiaries <- load_subsidiaries(pool)
  brands <- load_brands(pool)

  vendor_select <- vendors$vendor_id
  names(vendor_select) <- vendors$companyname

  brand_select <- brands$brand_id
  names(brand_select) <- brands$brand_name

  na.omit.list <- function(y) {
    return(y[!sapply(y, function(x) all(is.na(x)))])
  }

  vendor_select <- na.omit.list(vendor_select)

  # browser()
  # set up dropdown list for ui from the vendor data
  observe({
    updateSelectInput(session, "vendor_select", "ASSET CLASS",
      choices = vendor_select
    )
  })

  observe({
    updateSelectInput(session, "brand_select", "ASSET CLASS",
      choices = brand_select
    )
  })

  onStop(function() {
    poolClose(pool)
  })

  # display <- reactive({
  #   input$display
  # })
  # num <- callModule(sliderText, "module", display)
  # output$value <- renderText({
  #   paste0("slider1+5: ", num())
  # })



  # output$report <- output$report <- downloadHandler(
  #   # For PDF output, change this to "report.pdf"
  #   filename = "report.docx",
  #   content = function(file) {
  #     # Copy the report file to a temporary directory before processing it, in
  #     # case we don't have write permissions to the current working dir (which
  #     # can happen when deployed).
  #     tempReport <- file.path(tempdir(), "report.Rmd")
  #     file.copy("report.Rmd", tempReport, overwrite = TRUE)
  #
  #     # Set up parameters to pass to Rmd document
  #     params <- input$slider
  #
  #     # Knit the document, passing in the `params` list, and eval it in a
  #     # child of the global environment (this isolates the code in the document
  #     # from the code in this app).
  #     rmarkdown::render(tempReport,
  #       output_file = file,
  #       params = params,
  #       envir = new.env(parent = globalenv())
  #     )
  #   }
  # )

  observeEvent(input$refresh_report, {
    showModal(modalDialog(
      title = "Important message",
      "This is an important message!"
    ))
  })

  observeEvent(input$download_report, {
    showModal(modalDialog(
      title = "Important message",
      "This is an important message!"
    ))
  })
}
