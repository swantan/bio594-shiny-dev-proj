library(shinyBS)
library(shinycssloaders)
library(DT)

tab_vendors <- tabItem(
  tabName = "tab_vendors",
  fluidPage(
    tags$head(tags$script(src = "message-handler.js")),
    
    titlePanel(h2(icon("dashboard"), "Vendor Status Report")),
    
    sidebarLayout(
      position = "right",
      sidebarPanel(
        fluidRow(
          column(
            12,
            dateRangeInput("dates", h3("Date range")),
            selectInput(
              "vendor_select",
              h3("Vendor"),
              choices = list()
            ),
            selectInput(
              "brand_select",
              h3("Brand"),
              choices = list(),
            )
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
            actionButton("download_report", "Download .DOC"),
            bsTooltip("download_report", "Click to download a word document containing the contents of the report for sending to a vendor",
                      placement = "left", trigger= "hover")
          )
        )
      ),
      mainPanel(
        withSpinner(plotOutput("popPlot")),
        DTOutput("tbltbl")
        # tableOutput("raw_data")
      )
    )
  )
  
)
