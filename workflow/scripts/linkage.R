# ==============================================================================
# Link validated sequences to validated notifications
# ==============================================================================

suppressPackageStartupMessages(require(tidyverse, quietly = TRUE))

source("R/linkage.R")
source("R/pipeline_metrics.R")

main <- function(snakemake) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")

  notifications <- read_csv(snakemake@input$notifications, show_col_types = FALSE)
  sequences <- read_csv(snakemake@input$sequences, show_col_types = FALSE)

  # link_sequences() adds a boolean column called linked
  linked <- link_sequences(
    notifications,
    sequences,
    id_col = "id",
    max_lag_days = snakemake@params$max_lag_days
  )

  # Lookup to overwrite hash-ids from output
  lookup <- tibble(
      key = c(linked$sequences$id, linked$notifications$id) |> unique() |> sort()
    ) |>
    mutate(value = paste0("id-", row_number()))

  linked <- lapply(
    linked,
    function(x) { x |> mutate(id = lookup$value[match(id, lookup$key)]) }
  )
  
  sequences_linked <- linked$sequences |>
    filter(linked == TRUE)
  notifications_linked <- linked$notifications |>
    filter(linked == TRUE)
  sequences_rejected <- linked$sequences |>
    filter(linked == FALSE)
  notifications_rejected <- linked$notifications |>
    filter(linked == FALSE)

  metrics <- bind_rows(
    metric_row(
      snakemake,
      input_name  = "sequences",
      output_name = "sequences",
      n_input     = nrow(sequences),
      n_output    = nrow(sequences_linked),
      n_rejected  = nrow(sequences_rejected)
    ),
    metric_row(
      snakemake,
      input_name  = "notifications",
      output_name = "notifications",
      n_input     = nrow(notifications),
      n_output    = nrow(notifications_linked),
      n_rejected  = nrow(notifications_rejected)
    )
  )

  # Halt the pipeline if there was not linkage
  error_msg <- "No linked sequences or notifications. Check ids and input data."
  if (nrow(notifications_linked) == 0 || nrow(sequences_linked) == 0) {
    cat(error_msg, "\n")          # stdout
    cat(error_msg, "\n", file = stderr())  # stderr
    stop(error_msg, call. = FALSE)
  }

  write_csv(notifications_linked, snakemake@output$notifications)
  write_csv(sequences_linked, snakemake@output$sequences)
  write_csv(sequences_rejected, snakemake@output$sequences_rejected)
  write_csv(notifications_rejected, snakemake@output$notifications_rejected)
  write_csv(metrics, snakemake@output$metrics)

}

main(snakemake)