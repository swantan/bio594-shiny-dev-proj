
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
      netsuite.subsidiaries
    WHERE
      subsidiary_id in (2,3);
  "

  subsidiaries <- dbGetQuery(pool, query) %>%
    rename(subsidiary_name = name)
  
  return(subsidiaries)
}

load_brands <- function(pool) {
  query <- "
    SELECT
      brand_id,
      brand_name
    FROM
      netsuite.brand
    where brand_id in (221, 179, 277)
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

  brands_reverse_select <- names(brand_select)
  names(brands_reverse_select) <- brand_select
  
  sub_select <- subsidiaries$subsidiary_id
  names(sub_select) <- subsidiaries$subsidiary_name

  na.omit.list <- function(y) {
    return(y[!sapply(y, function(x) all(is.na(x)))])
  }

  vendor_select <- na.omit.list(vendor_select)

  # browser()
  # set up dropdown list for ui from the vendor data
  observe({
    updateSelectInput(session, "sub_select", "ASSET CLASS",
      choices = sub_select
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

  observeEvent(input$about_app, {
    showModal(modalDialog(
      title = "About This App",
      h3("App Usage"),
      p("To use this app, choose a date range, one to three brands
        to report on and a summary function. The app will then generate
        plots for those brands for comparison as well as the top 20 overall
        items sold in that time period. All numbers are in USD."),
      p("When you're happy with the output, you can click the download report
        button and get a word document with some pre-generated text in it and the
        data that you just displayed."),
      h3("Intended Audience"),
      p("Admittedly, this app is a little unusual. The intended audience is
        specifically members of one company that have issues when it comes to quickly
        and reliably producing reports and disseminating them to other staff members
        or companies."),
      h3("About The Code"),
      p("If you look at the main branch of the linked repository, you'll see that this
        app actually uses pool to query a database. That's _not_ happening in this version
        of the app, as there was no safe way to bypass the vpn and not publish
        the credentials. Instead, you're getting a snapshot of data to play with for a
        limited number of brands.")
    ))
  })
  
  observeEvent(input$refresh_report, {
    validate(
      need(input$date_range[2] > input$date_range[1], "End date cannot be earlier than start date"),
      need(input$brand_select != "", "Please select a brand (or more)")
      
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

    brand_array <- paste("(", paste(input$brand_select, collapse = ","), ")")

    sql <- "WITH sales_info AS (
      SELECT
      nsi.name as item_name,
      nsi.brand_id,
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
      AND (nsi.brand_id in ?brand_id)
      AND (nstl.subsidiary_id = ?sub_ids)
    )
    
    SELECT
    sales_info.item_name,
    sales_info.brand_id,
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
      brand_id = SQL(brand_array),
      sub_ids = input$sub_select
    )



    item_sales_raw <- dbGetQuery(pool, query)

    item_sales <- item_sales_raw %>% filter(!is.na(amount))

    # join the brands and subsidiaries
    item_sales <- item_sales %>%
      inner_join(subsidiaries, by = "subsidiary_id") %>%
      inner_join(brands, by = "brand_id")
    
    # ditch the brand id, subsidiary id columns
    item_sales <- select (item_sales,-c("brand_id", "subsidiary_id"))
    
    # appropriately summarize

    summary_text <- "by week"
    if (input$sum_by == "m") {
      summary_text <- "by month"
    } else if (input$sum_by == "y") {
      summary_text <- "by year"
    }

    if (input$sum_by == "w") {
      sales_summary <- item_sales %>%
        group_by(day = floor_date(trandate, "week"), subsidiary_name, brand_name) %>%
        summarize(amount = sum(amount))
      item_sales_summary <- item_sales %>%
        group_by(subsidiary_name, brand_name, item_name) %>%
        summarize(qty = sum(qty))
    } else if (input$sum_by == "m") {
      sales_summary <- item_sales %>%
        group_by(day = floor_date(trandate, "month"), subsidiary_name, brand_name) %>%
        summarize(amount = sum(amount))
      item_sales_summary <- item_sales %>%
        group_by(subsidiary_name, brand_name, item_name) %>%
        summarize(qty = sum(qty))
    } else if (input$sum_by == "y") {
      sales_summary <- item_sales %>%
        group_by(day = floor_date(trandate, "year"), subsidiary_name, brand_name) %>%
        summarize(amount = sum(amount))
      item_sales_summary <- item_sales %>%
        group_by(subsidiary_name, brand_name, item_name) %>%
        summarize(qty = sum(qty))
    }
    
    item_sales_summary <- item_sales_summary %>% arrange(desc(qty))
    
    top_items_summary <- head(item_sales_summary,20)
    
    # browser()
    
    library(formattable)

    # format the currency column
    sales_summary$amount <- currency(sales_summary$amount, digits = 0L)
    

    # output$raw_data <- renderTable(sales_summary,
    #   striped = TRUE,
    #   bordered = TRUE,
    #   colnames = TRUE,
    # )

    output$tbltbl <- renderDT(top_items_summary)

    sales_plot <- sales_summary %>%
      ggplot() +
      geom_line(data = sales_summary, aes(x = day, y = amount, group = brand_name, color = brand_name)) +
      labs(
        title = paste("Sales", summary_text),
        y = "$ (USD)",
        x = "Date"
      ) +
      theme(legend.position = "bottom") +
      theme(legend.title=element_blank())


    # r_values$sales_plot <- sales_plot

    sale_plot <- ggplotly(sales_plot)

    output$popPlot <- renderPlotly(sales_plot)

    # mark first run over at end of computation to avoid issue with doc button
    if (r_values$first_run) {
      r_values$first_run <- 0
    }

    # browser()

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
          sales_plot = sales_plot,
          start_date = input$date_range[1],
          end_date = input$date_range[2],
          brand_name = brands_reverse_select[input$brand_select],
          top_items = top_items_summary
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
