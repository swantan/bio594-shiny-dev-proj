tab_brands <- tabItem(
  tabName = "tab_brands",
  fluidPage(
    titlePanel("title panel"),

    sidebarLayout(
      position = "right",
      sidebarPanel(
        fluidRow(
          column(
            12,
            dateRangeInput("dates", h3("Date range")),
            selectInput(
              "select",
              h3("Select box"),
              choices = list(
                "Choice 1" = 1,
                "Choice 2" = 2,
                "Choice 3" = 3
              ),
              selected = 1
            )
          )
        )
      ),
      mainPanel("main panel")
    )
  )
)