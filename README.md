# GitHub Repository Trends Shiny App

This project is a Shiny web application that displays the top 20 most starred GitHub repositories created within a selected time frame (e.g., last 7, 30, 90, 180, or 365 days).

## Features

- **Dynamic Time Filters:** A dropdown menu allows users to select a time range to view the fastest-growing projects.
- **Interactive Visualizations:** The app displays a bar chart and a table of the top repositories, which update based on the selected time range.
- **Automated Data Updates:** A GitHub Actions workflow automatically updates the data daily at 7:00 AM Beijing time and on every push to the `main` branch.

## How to Run the App

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   ```

2. **Set up the R environment:**
   - Open your R console in the project directory.
   - Install the required packages by running:
     ```R
     install.packages(c("shiny", "ggplot2", "gt", "tidyverse", "lubridate", "httr", "jsonlite"))
     ```

3. **Run the data download script:**
   - In your R console, run the following command to download the initial dataset:
     ```R
     source("download_data.R")
     ```

4. **Run the Shiny app:**
   - In your R console, run the following command to launch the app:
     ```R
     shiny::runApp("app.R")
     ```

## Project Structure

- `app.R`: The main file for the Shiny application.
- `download_data.R`: A script to download the latest GitHub trends data.
- `github_trends.csv`: The CSV file where the downloaded data is stored.
- `.github/workflows/schedule-email.yml`: The GitHub Actions workflow for automated data updates.
- `README.md`: This file.

## Automated Data Updates

The project uses a GitHub Actions workflow to keep the data up-to-date. The workflow is triggered:

- **Daily at 7:00 AM Beijing time (23:00 UTC):** The `download_data.R` script is run automatically to fetch the latest data.
- **On every push to the `main` branch:** The data is updated whenever new code is pushed to the main branch.

The workflow commits the updated `github_trends.csv` file back to the repository, ensuring that the app always displays the latest trends.
