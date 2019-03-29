library(shinydashboard)
library(shinyBS)
library(DT)


source("shiny_tab_supply_chain.R", local = TRUE)
source("shiny_tab_brands.R", local = TRUE)
source("shiny_tab_vendors.R", local = TRUE)

dashboard_header <- dashboardHeader(
  title = "Basic Dashboard"
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
    menuItem("Vendor Status Report", tabName = "tab_vendors", icon = icon("dashboard"))
#    menuItem("Brand Dashboard", tabName = "tab_brands", icon = icon("dashboard"))
#    menuItem("Supply Chain Dashboard", tabName = "tab_supply_chain", icon = icon("file-medical"))
  )
)

# Collect and stash the elements of the UI for render in the app.
shine_ui <- dashboardPage(
  dashboard_header,
  dashboard_sidebar,
  dashboard_body
)