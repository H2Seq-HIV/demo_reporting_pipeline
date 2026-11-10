# ==============================================================================
# Get earliest sequence per individual (proxy for transmitted virus)
# ==============================================================================

suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
source("R/pipeline_metrics.R") # for metric_row()

# Main -------------------------------------------------------------------------
main <- function(snakemake) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")

  sequences <- read_csv(snakemake@input$sequences, show_col_types = FALSE)

  sequences <- sequences |>
    group_by(id) |>
    mutate(transmitted = date_collection == min(date_collection)) |>
    ungroup() |>
    # Make transmitted TRUE only if there is one sequence
    # for each combination of id and date_collection.
    group_by(id, date_collection) |>
    mutate(transmitted = ifelse(transmitted, n() == 1, transmitted)) |>
    ungroup()

  transmitted_sequences <- sequences |>
    filter(transmitted) |>
    select(-transmitted)

  followup_sequences <- sequences |>
    filter(!transmitted) |>
    select(-transmitted)

  metrics <- metric_row(
      snakemake,
      input_name = "sequences",
      output_name = "sequences",
      n_input = nrow(sequences),
      n_output = nrow(transmitted_sequences),
      n_rejected = nrow(followup_sequences)
    )

  write_csv(transmitted_sequences, snakemake@output$sequences)
  write_csv(metrics, snakemake@output$metrics)
}

main(snakemake)
