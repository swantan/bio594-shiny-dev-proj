library(shinyBS)
library(shinycssloaders)
library(DT)

tab_vendors <- tabItem(
  tabName = "tab_vendors",
  fluidPage(
    tags$head(tags$script(src = "message-handler.js")),
    
    titlePanel(h2(icon("dashboard"), "Sales Report")),
    
    sidebarLayout(
      position = "right",
      sidebarPanel(
        fluidRow(
          column(
            12,
            dateRangeInput(
              "date_range",
              h3("Report date range"),
              start = '2019-01-01',
              end = '2019-04-18',
              min = '2017-12-25',
              max = '2019-04-18',
            ),
            # bsTooltip("date_range", "Select the date range for this report",
            #           placement = "left", trigger= "hover")
            # ,
            # selectInput(
            #   "vendor_select",
            #   h3("Vendor"),
            #   choices = list(),
            # ),
            # bsTooltip("vendor_select", "Select the vendor to report on",
            #           placement = "left", trigger= "hover"),
            selectInput(
              "brand_select",
              h3("Brand"),
              choices = list(),
              multiple = TRUE
            ),
            bsTooltip("brand_select", "Select the brand to report on",
                      placement = "left", trigger= "hover"),
            selectInput(
              "sub_select",
              h3("Subsidiary"),
              choices = list(
                "Twisted Throttle, LLC" = "2",
                "Twisted Throttle Canada, Inc." = "3"
              ),
            ),
            # bsTooltip("sub_select", "Select the subsidiary to report",
            #           placement = "left", trigger= "hover"),
            radioButtons("sum_by", "Summarize By:",
                         c("Week" = "w",
                           "Month" = "m",
                           "Year" = "y"
                           ))
          )
        ),
        fluidRow(
          column(
            6,
            actionButton("refresh_report", "Refresh Report"),
            bsTooltip("refresh_report", "Click to refresh the vendor report with the above filters",
                      placement = "left", trigger= "hover")
          ),
          column(
            6,
            downloadButton("download_report", "Download .DOC"),
            bsTooltip("download_report", "Click to download a word document containing the contents of the report for sending to a vendor",
                      placement = "left", trigger= "hover")
          )
        )
      ),
      mainPanel(
        uiOutput("dataPlot"),
        DTOutput("tbltbl")
        # tableOutput("raw_data")
      )
    )
  )
  
)
