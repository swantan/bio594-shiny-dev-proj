sliderTextUI <- function(id) {
  ns <- NS(id)
  tagList(
    sliderInput(ns("slider"), "Slide me", 0, 100, 5),
    textOutput(ns("number"))
  )
}

tab_supply_chain <- tabItem(
  tabName = "tab_supply_chain",
  h2("Supply Chain"),
  fluidRow(
    checkboxInput("display", "Show Value"),
    sliderTextUI("module"),
    h2(textOutput("value")),
    downloadButton("report")
  )
)
