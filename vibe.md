
# create a shiny app website using R 

## 1 learning from following R code 

```{r setup, include=FALSE,warning=FALSE,message=FALSE}
knitr::opts_chunk$set(echo = FALSE,warning=FALSE,message=FALSE)

# load package
library(httr)
library(jsonlite)
library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)
library(gt)
```

```{r include=FALSE,warning=FALSE,message=FALSE}
get_and_process_github_data <- function(since_date, top_n = 100,show_n=20) {
  # get data
  res <- GET(
    url = "https://api.github.com/search/repositories",
    query = list(
      q = paste0("created:>", since_date),
      sort = "stars",
      order = "desc",
      per_page = top_n
    ),
    add_headers(Accept = "application/vnd.github.v3+json")
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
    created_at  = top$created_at,
    summary     = top$description,
    url         = top$html_url,
    stringsAsFactors = FALSE
  )
  
  # filter forks>0
  df <- df %>%
  filter(forks > 0) %>%
  arrange(desc(stars)) %>%
  slice_head(n = show_n)
  
  return(df)
}

create_plot <- function(df, since_date) {
    if (is.null(df) || nrow(df) == 0) {
        return(ggplot() + labs(title=paste("No data available for projects since", since_date)) + theme_minimal())
    }
    df$name_label <- paste0(df$name, "\n", format(as.Date(df$created_at), "%Y-%m-%d"))

    # Reshape data to long format for plotting
    df_long <- df %>%
      select(name,name_label, url, stars, forks) %>%
      pivot_longer(cols = c("stars", "forks"),
                   names_to = "metric", values_to = "count") %>%
      left_join(df %>% select(name, stars_total = stars), by = "name")

    # Bar chart
    gg <- ggplot(df_long, aes(x = reorder(name_label, stars_total), y = count, fill = metric, customdata = url)) +
      geom_bar(stat = "identity", position = "dodge") +
      geom_text(aes(label = scales::label_number(accuracy = 0.1, scale_cut = scales::cut_short_scale())(count)), position = position_dodge(width = 0.9), hjust = -0.1, size = 3) +
      labs(
        title = paste0("Top 20 Fastest Growing GitHub Projects since ", since_date),
        x = "Repository",
        y = "Count",
        fill = "Metric"
      ) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      coord_flip()

    return(gg)
}

create_table <- function(df, since_date) {
    if (is.null(df) || nrow(df) == 0) {
        return(gt(data.frame(Message = character(0))) |> tab_header(title = md(paste0("**No data available for projects since ", since_date, "**"))))
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
        title = md(paste0("**Top 20 Fastest Growing GitHub Projects since ", since_date, "**"))
      )
}
```

Today is `r format(Sys.Date(), "%Y-%m-%d")`

# Since past 7 days (`r format(Sys.Date() - 7, "%Y-%m-%d")`)

```{r}
since_30_days <- format(Sys.Date() - 7, "%Y-%m-%d")
df_30_days <- get_and_process_github_data(since_30_days)
```

```{r}
#| column: page
#| fig-width: 12
#| fig-height: 8
create_plot(df_30_days, since_30_days)
```

```{r}
create_table(df_30_days, since_30_days)
```


## 2. create download_data.R file

### using renv to set up virtual environments and install needed package

### download data from github include past 365 day data and save to csv


## 3. create shinyapp app.R file

### load csv

### display the bar chart and Great table 

### it include a dropdown list to select past 7 days, 30 days, 90 days, 180 days, 365 days


## 4. create .github/workflows/schedule-email.yml

it will run download_data.R every day at 7:00 AM Beijing time or every time there is a push to main branch


## 5. create a readme.md file to introduce this project






