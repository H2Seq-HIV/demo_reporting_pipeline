# ==============================================================================
# Validate input sequence data and separate accepted and rejected rows
# ==============================================================================

suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
suppressPackageStartupMessages(require(pointblank, quietly = TRUE))

source("R/seq_utils.R") # for is_seq() function
source("R/pipeline_metrics.R") # for metric_row() function

# TODO, abstract this to config later on
validate_sequences <- function(sequences) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")
  
  create_agent(tbl = sequences, label = "Sequences") |>
    col_exists(
      c(id, date_collection, sequence_prrtin, sequence_int),
      brief = "Essential columns"
    ) |>
    col_vals_not_null(
      c(id, date_collection),
      brief = "ID and date_collection must be defined"
    ) |>
    col_is_date(c(date_collection), brief = "Collection dates formatted") |>
    col_vals_expr(
      brief = "PRRTIN are defined sequences",
      expr = ~ purrr::map_lgl(sequence_prrtin, is_seq),
      na_pass = FALSE
    ) |>
    col_vals_expr(
      brief = "INT are sequences IF supplied",
      expr = ~ purrr::map_lgl(sequence_int, is_seq),
      na_pass = TRUE
    )|>
    interrogate()
}

main <- function(snakemake) {
  sequences <- read_csv(
    snakemake@input$sequences,
    show_col_types = FALSE
  )

  agent <- validate_sequences(sequences)
  passed <- get_sundered_data(agent, type = "pass")
  failed <- get_sundered_data(agent, type = "fail")

  metrics <- tibble(
    rule = "validate_sequences",
    stream = "sequences",
    n_input = nrow(sequences),
    n_output = nrow(passed),
    n_rejected = nrow(failed)
  )
  metrics <- metric_row(
      snakemake,
      input_name = "sequences",
      output_name = "sequences",
      n_input = nrow(sequences),
      n_output = nrow(passed),
      n_rejected = nrow(failed)
  )

  export_report(
    agent,
    filename = snakemake@log$report,
    quiet = TRUE
  )

  write_csv(passed, snakemake@output$sequences)
  write_csv(failed, snakemake@output$rejected)
  write_csv(metrics, snakemake@output$metrics)
}

main(snakemake)