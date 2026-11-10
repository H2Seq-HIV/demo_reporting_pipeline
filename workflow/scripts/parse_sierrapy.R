# ==============================================================================
# Parse Stanford HIVdb JSON into long resistance and subtype tables
# ==============================================================================

suppressPackageStartupMessages({require(tidyverse, quietly = TRUE)})

source("R/parse_sierrapy.R")

main <- function(snakemake) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")
  
  metadata <- read_csv(snakemake@input$metadata, show_col_types = FALSE) |>
    select(id, date_onset)

  sierrapy_output <- parse_sierrapy_json(
    snakemake@input$json,
    snakemake@params$res_cutoff
  )

  write_csv(sierrapy_output$drugs, snakemake@output$drugs)
  write_csv(sierrapy_output$classes, snakemake@output$classes)
  write_csv(sierrapy_output$mutations, snakemake@output$mutations)
  write_csv(sierrapy_output$subtypes, snakemake@output$subtypes)
}

main(snakemake)