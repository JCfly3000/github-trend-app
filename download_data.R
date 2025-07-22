# This script downloads the top 100 most starred GitHub repositories
# created in the last 365 days and saves them to a CSV file.

# To set up the environment, run the following in your R console:
# if (!require("renv")) {
#   install.packages("renv")
# }
# renv::init()
#renv::install(c("httr", "jsonlite", "tidyverse", "lubridate","rsconnect"))


#renv::init()

#renv::status()

#renv::snapshot()


# Load necessary packages
library(httr)
library(jsonlite)
library(tidyverse)
library(lubridate)
library(rsconnect)

# Function to get data from GitHub API
get_github_data <- function(since_date, top_n = 100) {
  # get data
  res <- httr::GET(
    url = "https://api.github.com/search/repositories",
    query = list(
      q = paste0("created:>", since_date),
      sort = "stars",
      order = "desc",
      per_page = top_n
    ),
    httr::add_headers(Accept = "application/vnd.github.v3+json")
  )

  if (httr::http_error(res)) {
    warning(paste("GitHub API request failed for since_date:", since_date, "Status:", httr::http_status(res)$message))
    return(data.frame()) # Return empty dataframe on error
  }
  
  data <- content(res, as = "parsed", simplifyVector = TRUE)

  if (length(data$items) == 0) {
    return(data.frame())
  }

  # Extract details
  top <- data$items
  df <- data.frame(
    name        = top$full_name,
    stars       = top$stargazers_count,
    forks       = top$forks_count,
    created_at  = as.Date(top$created_at), # Using as.Date for simplicity
    summary     = ifelse(is.na(top$description), "", top$description), # Replace NA with empty string
    url         = top$html_url,
    stringsAsFactors = FALSE
  )
  
  return(df)
}

# --- Main script ---
cat("Downloading latest GitHub trend data...\n")

# Get data for the past 365 days
all_data=tibble()

cut_date  <- Sys.Date() - 7
github_data <- get_github_data(format(cut_date, "%Y-%m-%d"), top_n = 100)
all_data=rbind(all_data,github_data)

cut_date  <- Sys.Date() - 180
github_data <- get_github_data(format(cut_date, "%Y-%m-%d"), top_n = 100)
all_data=rbind(all_data,github_data)

cut_date <- Sys.Date() - 365
github_data <- get_github_data(format(cut_date, "%Y-%m-%d"), top_n = 100)
all_data=rbind(all_data,github_data)


all_date_unique=unique(all_data)

# Save to CSV
if (nrow(all_date_unique) > 0) {
  write.csv(all_date_unique, "github_trends.csv", row.names = FALSE)
  cat("Data successfully downloaded and saved to github_trends.csv\n")
} else {
  cat("No data retrieved from GitHub. A new github_trends.csv file was not created.\n")
}