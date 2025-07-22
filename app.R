#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggplot2)
library(gt)
library(plotly)
library(tidyverse)
library(lubridate)

# --- Helper Functions ---

# Function to create the plot
create_plot <- function(df, since_days) {
  if (is.null(df) || nrow(df) == 0) {
    return(plot_ly() %>% layout(title = paste("No data available for projects in the last", since_days, "days")))
  }
  df$name_label <- paste0(df$name, "\n", format(as.Date(df$created_at), "%Y-%m-%d"))
  
  df_long <- df %>%
    select(name, name_label, url, stars, forks) %>%
    pivot_longer(cols = c("stars", "forks"), names_to = "metric", values_to = "count") %>%
    left_join(df %>% select(name, stars_total = stars), by = "name")
  
  gg <- ggplot(df_long, aes(x = reorder(name_label, stars_total), y = count, fill = metric, customdata = url)) +
    geom_bar(stat = "identity", position = "dodge") +
    labs(
      title = paste0("Top 20 Fastest Growing GitHub Projects (last ", since_days, " days)"),
      x = "Repository",
      y = "Count",
      fill = "Metric"
    ) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    coord_flip()
  
  return(gg)
}

# Function to create the table
create_table <- function(df, since_days) {
  if (is.null(df) || nrow(df) == 0) {
    return(gt(data.frame(Message = character(0))) |> tab_header(title = md(paste0("**No data available for projects in the last ", since_days, " days**"))))
  }
  df |>
    mutate(name = paste0("[", name, "](", url, ")")) |>
    select(name, summary, stars, forks, created_at) |>
    gt() |>
    fmt_markdown(columns = "name") |>
    cols_label(
      name = "Project",
      summary = "Description",
      stars = "Stars",
      forks = "Forks",
      created_at = "Created At"
    ) |>
    tab_header(
      title = md(paste0("**Top 20 Fastest Growing GitHub Projects (last ", since_days, " days)**"))
    )
}

# --- Shiny App ---

# Define UI
ui <- fluidPage(
  titlePanel("GitHub Repository Trends"),
  sidebarLayout(
    sidebarPanel(
      selectInput("days_filter", "Select Time Range:",
                  choices = list("Last 7 Days" = 7,
                              "Last 30 Days" = 30,
                              "Last 90 Days" = 90,
                              "Last 180 Days" = 180,
                              "Last 365 Days" = 365),
                  selected = 7)
    ),
    mainPanel(
      plotOutput("trend_plot"),
      gt_output("trend_table")
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  # Load data
  all_data <- reactive({
    read.csv("github_trends.csv") %>%
      mutate(created_at = as.Date(created_at))
  })
  
  # Filter data based on dropdown
  filtered_data <- reactive({
    req(all_data())
    days <- as.numeric(input$days_filter)
    since_date <- Sys.Date() - days
    
    all_data() %>%
      filter(created_at >= since_date) %>%
      filter(forks > 0) %>%
      arrange(desc(stars)) %>%
      slice_head(n = 20)
  })
  
  # Render plot
  output$trend_plot <- renderPlot({
    create_plot(filtered_data(), input$days_filter)
  })
  
  # Render table
  output$trend_table <- render_gt({
    create_table(filtered_data(), input$days_filter)
  })
}

# Run the application
shinyApp(ui = ui, server = server)
