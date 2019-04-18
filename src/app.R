#' Shiny app developed for BIO594.
#'
#' Using a snapshot of data from TT, creates an interactive shiny dashboard
#' that allows a user to readily check vendor health and produce a report with
#' `knitr` that can be sent to the vendor.
#'

library(shiny)
library(shinydashboard)

source("ui.R", local = TRUE)
source("server.R", local = TRUE)

#' shine_ui, shine_server in separate files
shinyApp(
  ui = shine_ui,
  server = shine_server
)


# --- data to add
# @TODO Top 5 categories
# @TODO Top 10 items
# @TODO add purchase by vendor
# @TODO add sales orders

# --- errors to correct
# @TODO error for reversed dates
# @TODO no data error
# @TODO Vendor currently does nothing

# --- ui enhancements
# @TODO remove table

