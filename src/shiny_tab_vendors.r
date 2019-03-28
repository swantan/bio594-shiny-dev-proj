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
            actionButton("refresh_report", "Refresh Report")
          ),
          column(
            6,
            actionButton("download_report", "Download .DOC")
          )
        )
      ),
      mainPanel(
        plotOutput("popPlot")
      )
    )
  )
  
)
