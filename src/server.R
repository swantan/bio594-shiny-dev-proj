
library(rmarkdown)
library(pool)
library(config)
library(DBI)
library(RPostgreSQL)
library(dplyr)
library(ggplot2)
library(lubridate)
library(plotly)
library(shinycssloaders)


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
    where vendor_type_id = 5 and vendor_id in (150492, 149864, 150469)
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
  r_values <- reactiveValues()
  
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

  # suppress the plot until the data's called at least once
  r_values$first_run <- 1
  
  observeEvent(input$refresh_report, {
    validate(
      need(input$date_range[2] > input$date_range[1], "end date is earlier than start date"
      )
    )
    
    
    # first run, draw the plot
    if (r_values$first_run) {
      output$dataPlot <- renderUI({
        withSpinner(plotlyOutput("popPlot"))
      })
    }
    
    # shiny::validate(
    #   need(input$date_range[1] < input$date_range[2], message = "Please select a data set")
    # )
    
    # showModal(modalDialog(
    #   title = "Important message",
    #   paste("This is an important message!",input$date_range[1]," ohhhh ",input$date_range[2])
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
      AND (nstl.subsidiary_id = ?sub_ids)
    )
    
    SELECT
    sales_info.item_id,
    sales_info.trandate,
    sales_info.qty,
    sales_info.amount,
    sales_info.subsidiary_id,
    sales_info.sales_order_type_id
    FROM sales_info"

    query <- sqlInterpolate(
      pool,
      sql,
      begin_date = as.character(input$date_range[1]),
      end_date = as.character(input$date_range[2]),
      brand_id = input$brand_select,
      sub_ids = input$sub_select
    )


        
    item_sales_raw <- dbGetQuery(pool, query)

    item_sales <- item_sales_raw %>% filter(!is.na(amount))
    
    # appropriately summarize
    
    summary_text = "by week"
    if (input$sum_by == "m") {
      summary_text = "by month"
    } else if (input$sum_by == "y") {
      summary_text = "by year"
    }
    
    if (input$sum_by == "w") {
      sales_summary <-  item_sales %>%
        group_by(day=floor_date(trandate, "week"), subsidiary_id) %>%
        summarize(amount=sum(amount))
    } else if (input$sum_by == "m") {
      sales_summary <-  item_sales %>%
        group_by(day=floor_date(trandate, "month"), subsidiary_id) %>%
        summarize(amount=sum(amount))
    } else if (input$sum_by == "y") {
      sales_summary <-  item_sales %>%
        group_by(day=floor_date(trandate, "year"), subsidiary_id) %>%
        summarize(amount=sum(amount))
    }

    sales_summary <- as_tibble(base::merge(sales_summary, subsidiaries, by="subsidiary_id"))
    
    # output$raw_data <- renderTable(sales_summary,
    #   striped = TRUE,
    #   bordered = TRUE,
    #   colnames = TRUE,
    # )
    
    output$tbltbl <- renderDT(sales_summary)
    
    sales_plot <- sales_summary %>%
      ggplot() +
      geom_line(data = sales_summary, aes(x = day, y = amount, group=name, color=name)) +
      labs(title = paste("Sales",summary_text),
#           subtitle = "The data frame is sent to the plot using pipes",
           y = "$ (USD)",
           x = "Date")
    
    # r_values$sales_plot <- sales_plot
    
    sale_plot <- ggplotly(sales_plot)
    
    output$popPlot <- renderPlotly(sales_plot)
    
    # mark first run over at end of computation to avoid issue with doc button
    if (r_values$first_run) {
      r_values$first_run <- 0
    }
    
    
    output$download_report <- downloadHandler(
      # For PDF output, change this to "report.pdf"
      filename = "report.docx",
      content = function(file) {
        # Copy the report file to a temporary directory before processing it, in
        # case we don't have write permissions to the current working dir (which
        # can happen when deployed).
        tempReport <- file.path(tempdir(), "report.Rmd")
        file.copy("report.Rmd", tempReport, overwrite = TRUE)
        
        # Set up parameters to pass to Rmd document
        params <- list(
          sales_plot = sales_plot
        )
        
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
    
  })
}
