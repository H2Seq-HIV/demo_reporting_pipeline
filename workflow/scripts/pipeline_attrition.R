# ==============================================================================
# Build pipeline attrition table from the Snakemake DAG and rule metrics
# ==============================================================================

suppressPackageStartupMessages({
  require(dplyr, quietly = TRUE)
  require(jsonlite, quietly = TRUE)
  require(purrr, quietly = TRUE)
  require(readr, quietly = TRUE)
  require(tibble, quietly = TRUE)
})

main <- function(snakemake) {
  dag <- read_json(
    snakemake@input$dag,
    simplifyVector = FALSE
  )

  dag_nodes <- map_dfr(dag$nodes, \(node) {
    tibble(
      job_id = as.character(node$id),
      rule = node$value$rule
    )
  })

  dag_edges <- map_dfr(dag$edges, \(edge) {
    tibble(
      parent_job_id = as.character(edge$u),
      child_job_id = as.character(edge$v)
    )
  }) |>
    left_join(
      dag_nodes |>
        rename(parent_job_id = job_id, prev_rule = rule),
      by = "parent_job_id"
    ) |>
    left_join(
      dag_nodes |>
        rename(child_job_id = job_id, rule = rule),
      by = "child_job_id"
    ) |>
    select(prev_rule, rule) |>
    distinct()

  metrics <- snakemake@input$metrics |>
    unlist() |>
    map_dfr(read_csv, show_col_types = FALSE)

  required_columns <- c(
    "rule",
    "stream",
    "input_file",
    "output_file",
    "n_input",
    "n_output",
    "n_rejected"
  )

  missing_columns <- setdiff(required_columns, names(metrics))

  if (length(missing_columns) > 0) {
    stop(
      "Metric files are missing required columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  metric_rules <- unique(metrics$rule)

  # Retain only DAG edges where both rules emit attrition metrics.
  attrition_edges <- dag_edges |>
    filter(
      prev_rule %in% metric_rules,
      rule %in% metric_rules
    )

  # Attach the child metric to each possible DAG edge, then retain the parent
  # whose output path exactly matches the child's input path.
  annotated_edges <- attrition_edges |>
    inner_join(
      metrics |>
        rename(
          input_file = input_file,
          output_file = output_file
        ),
      by = "rule"
    ) |>
    inner_join(
      metrics |>
        transmute(
          prev_rule = rule,
          prev_stream = stream,
          previous_output_file = output_file,
          prev_n_output = n_output
        ),
      by = "prev_rule"
    ) |>
    filter(
      input_file == previous_output_file,
      stream == prev_stream
    ) |>
    transmute(
      prev_rule,
      rule,
      stream,
      n_input,
      n_output,
      n_rejected,
      prev_n_output,
      input_file,
      output_file
    ) |>
    distinct()

  # Metrics without an upstream attrition rule are roots of a stream.
  root_metrics <- metrics |>
    anti_join(
      annotated_edges |>
        select(rule, stream, input_file),
      by = c("rule", "stream", "input_file")
    ) |>
    transmute(
      prev_rule = NA_character_,
      rule,
      stream,
      n_input,
      n_output,
      n_rejected,
      prev_n_output = NA_real_,
      input_file,
      output_file
    )

  pipeline_stats <- bind_rows(
    root_metrics,
    annotated_edges
  ) |>
    arrange(stream, rule)

  write_csv(
    pipeline_stats,
    snakemake@output$table
  )
}

main(snakemake)