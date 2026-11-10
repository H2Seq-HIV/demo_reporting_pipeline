# ==============================================================================
# Combine PRRTIN and INT Stanford tables and associate notification metadata
# ==============================================================================

suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))
options(readr.show_col_types = FALSE)

# Convenience combine tables for prrtin and int.
combine_sierapy <- function(paths, metadata) {
  paths |>
    map_dfr(read_csv) |>
    distinct() |>
    left_join(metadata, by = "id", relationship = "many-to-one")
}

main <- function(snakemake) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")
  
  metadata <- read_csv(snakemake@input$notifications) |>
    select(id, date_onset)

  mutations <- combine_sierapy(snakemake@input$mutations, metadata)
  drugs <- combine_sierapy(snakemake@input$drug_resistance, metadata)
  classes <- combine_sierapy(snakemake@input$class_resistance, metadata)

  subtype_prrtin <- read_csv(snakemake@input$subtypes[1]) |>
    transmute(id, subtype_prrtin = subtype)

  subtype_int <- read_csv(snakemake@input$subtypes[2]) |>
    transmute(id, subtype_int = subtype)
  
  # TODO: Assumes prrtint and int are the inputs.
  # Need to make this dynamic with wildcards in future.
  subtype_prrtin <- read_csv(
    snakemake@input$subtypes[1]) |>
    transmute(id, subtype_prrtin = subtype)

  subtype_int <- read_csv(
    snakemake@input$subtypes[2]) |>
    transmute(id, subtype_int = subtype)

  subtypes <- subtype_prrtin |>
    full_join(subtype_int, by = "id", relationship = "one-to-one") |>
    left_join(metadata, by = "id", relationship = "one-to-one")
  # ^ one-to-one expected. Deliberately fails if we have duplicates
  #   that somehow get through the extract_transmitted step!

  write_csv(mutations, snakemake@output$mutation)
  write_csv(drugs, snakemake@output$drug)
  write_csv(classes, snakemake@output$classes)
  write_csv(subtypes, snakemake@output$subtype)
}

main(snakemake)