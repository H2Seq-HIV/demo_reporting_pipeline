suppressPackageStartupMessages({
  require(readr, quietly = TRUE)
})

source("R/parse_hivtrace.R")

main <- function(snakemake) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")

  notifications <- read_csv(snakemake@input$notifications)
  clusters <- parse_hivtrace_json(snakemake@input$json)

  linelist <- notifications |>
    left_join(clusters, by = "id")

  write_csv(linelist, snakemake@output$linelist)

}

main(snakemake)
