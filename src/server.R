
library(rmarkdown)
library(pool)
library(config)
library(DBI)
library(RPostgreSQL)
library(dplyr)
library(ggplot2)
library(lubridate)

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
    # showModal(modalDialog(
    #   title = "Important message",
    #   "This is an important message!"
    # ))
    
    sql <- "WITH sales_info AS (
      SELECT
      nsi.item_id,
      nst.trandate::date AS trandate,
      nstl.item_count * '-1'::integer::numeric AS qty,
      nstl.net_amount * '-1'::integer::numeric AS amount,
      nstl.subsidiary_id,
      nst.sales_order_type_id
      FROM
      netsuite.transaction_lines nstl
      LEFT JOIN netsuite.transactions nst ON nst.transaction_id = nstl.transaction_id
      LEFT JOIN netsuite.items nsi ON nsi.item_id = nstl.item_id
      WHERE (
        nst.transaction_type::text = ANY (ARRAY[
          'Cash Sale'::text,
          'Invoice'::text
          ])
      ) AND (
        nsi.type_name::text = ANY (ARRAY[
          'Non-inventory Item'::character varying::text,
          'Inventory Item'::character varying::text,
          'Assembly/Bill of Materials'::character varying::text,
          'Kit/Package'::character varying::text,
          'Item Group'::character varying::text
          ])
      )
      AND (nst.trandate >= to_date(?begin_date,'YYYY-MM-DD'))
      AND (nst.trandate <= to_date(?end_date,'YYYY-MM-DD'))
      AND (nsi.brand_id = ?brand_id)
    )
    
    SELECT
    sales_info.item_id,
    sales_info.trandate,
    sales_info.qty,
    sales_info.amount,
    sales_info.subsidiary_id,
    sales_info.sales_order_type_id
    FROM sales_info"
   # browser()
    query <- sqlInterpolate(
      pool,
      sql,
      begin_date = '2019-01-01',
      end_date = '2019-03-28',
      brand_id = 277#input$brand_id
    )

    item_sales_rawsales <- dbGetQuery(pool, query)

    item_sales <- item_sales_raw %>% filter(!is.na(amount))
    
    sales_by_week <-  item_sales %>%
      group_by(day=floor_date(trandate, "week"), subsidiary_id) %>%
      summarize(amount=sum(amount))
    
    sales_by_week <- as_tibble(base::merge(sales_by_week, subsidiaries, by="subsidiary_id"))
    
    output$raw_data <- renderTable(sales_by_week)
    
    sales_plot <- sales_by_week %>%
      ggplot() +
      geom_line(data = sales_by_week, aes(x = day, y = amount, group=name, color=name)) +
      labs(title = "Sales by Week",
#           subtitle = "The data frame is sent to the plot using pipes",
           y = "$ (USD)",
           x = "Date")
    
    output$popPlot <- renderPlot(sales_plot)
  })

  observeEvent(input$download_report, {
    showModal(modalDialog(
      title = "Important message",
      "This is an important message!"
    ))
  })
}
