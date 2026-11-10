# ==============================================================================
# Combine notifications, HIV-TRACE clusters, and Stanford subtype calls
# ==============================================================================

suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
options(readr.show_col_types = FALSE)

source("R/parse_hivtrace.R") # for name_clusters()

main <- function(snakemake) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")
  
  notifications_linked <- read_csv(snakemake@input$notifications_linked)
  notifications_rejected <- read_csv(snakemake@input$notifications_rejected)

  notifications <- bind_rows(notifications_linked, notifications_rejected)

  clusters <- read_csv(snakemake@input$clusters) |>
    select(id, cluster_id) |>
    name_clusters(notifications) |> # Adds cluster_label column
    mutate(cluster_analysis = TRUE)

  subtypes <- read_csv(snakemake@input$subtypes) |>
    select(-date_onset)
  
  sequence_info <- read_csv(snakemake@input$sequence_info) |>
    select(id, date_collection)

  linelist <- notifications_linked |>
    left_join(subtypes, by = "id", relationship = "one-to-one") |>
    left_join(clusters, by = "id", relationship = "one-to-one") |>
    left_join(sequence_info, by = "id", relationship = "one-to-one") |>
    mutate(cluster_analysis = coalesce(cluster_analysis, FALSE)) |>
    ungroup() |>
    bind_rows(notifications_rejected)
    

  write_csv(linelist, snakemake@output$linelist)
}

main(snakemake)