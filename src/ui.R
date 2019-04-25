library(shinydashboard)
library(shinyBS)
library(DT)


source("shiny_tab_supply_chain.R", local = TRUE)
source("shiny_tab_brands.R", local = TRUE)
source("shiny_tab_vendors.R", local = TRUE)

dashboard_header <- dashboardHeader(
  title = "Twisted Reports"
)

dashboard_body <- dashboardBody(
  tabItems(
    tab_supply_chain,
    tab_brands,
    tab_vendors
  )
)

dashboard_sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Sales Report", tabName = "tab_vendors", icon = icon("dashboard"))
    #    menuItem("Brand Dashboard", tabName = "tab_brands", icon = icon("dashboard"))
    #    menuItem("Supply Chain Dashboard", tabName = "tab_supply_chain", icon = icon("file-medical"))
  ),
  fluidRow(
    column(
      12, class="text-center",
      br(),
      br(),
      br(),
      br(),
      actionButton(
        inputId = "about_app", label = "About App",
        icon = icon("info-circle")
      ),
      actionButton(
        inputId = "ab1", label = "Get the code!",
        icon = icon("github"),
        onclick = "window.open('https://github.com/joshpsawyer/bio594-shiny-dev-proj', '_blank')"
      ),
      tags$style(type='text/css', "#about_app { margin: 5px auto;} #ab1 { margin: 5px auto;}")
    )
  )
)
# Collect and stash the elements of the UI for render in the app.
shine_ui <- dashboardPage(
  dashboard_header,
  dashboard_sidebar,
  dashboard_body
)