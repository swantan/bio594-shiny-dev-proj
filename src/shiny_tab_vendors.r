tab_vendors <- tabItem(
  tabName = "tab_vendors",
  fluidPage(
    titlePanel(h2(icon("dashboard"), "Vendor Status Report")),
    
    sidebarLayout(
      position = "right",
      sidebarPanel(
        fluidRow(
          column(
            12,
            dateRangeInput("dates", h3("Date range")),
            selectInput(
              "select",
              h3("Vendor"),
              choices = list(
                "Choice 1" = 1,
                "Choice 2" = 2,
                "Choice 3" = 3
              ),
              selected = 1
            ),
            selectInput(
              "select",
              h3("Brand"),
              choices = list(
                "Choice 1" = 1,
                "Choice 2" = 2,
                "Choice 3" = 3
              ),
              selected = 1
            )
          )
        ),
        fluidRow(
          column(
            6,
            actionButton("action", "Refresh Report")
          ),
          column(
            6,
            submitButton("Download .DOC")
          )
        )
      ),
      mainPanel("main panel")
    )
  )
  
)
