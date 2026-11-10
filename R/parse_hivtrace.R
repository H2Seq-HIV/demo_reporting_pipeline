suppressPackageStartupMessages({
  require(jsonlite, quietly = TRUE)
  require(tidyverse, quietly = TRUE)
})

#' Parse HIV-TRACE JSON into sequence cluster assignments.
#'
#' @param json_path Path to an HIV-TRACE JSON result.
#' @return A tibble with character `id` and raw `cluster_id`.
parse_hivtrace_json <- function(json_path) {
  json <- fromJSON(json_path, simplifyVector = FALSE)
  nodes <- json$trace_results$Nodes

  tibble(
    # Schema if not using curate or filter
    id = unlist(nodes$id, use.names = FALSE),
    # cluster_id = unlist(nodes$cluster$values, use.names = FALSE)
    cluster_id = unlist(nodes$cluster, use.names = FALSE)
  )
}

#' Name HIV-TRACE clusters from the first notification in each cluster.
#'
#' Labels use the first cluster notification's within-year position:
#' YYYY-NNN. Unclustered notifications retain missing cluster IDs.
#'
#' @param clusters Tibble with `id` and raw `cluster_id`.
#' @param notifications Tibble with `id` and `date_onset`.
#' @return Tibble with `id` and named `cluster_id`.
name_clusters <- function(clusters, notifications) {

  # Determine would-be names of cluster starting with each notification
  notification_order <- notifications |>
    select(id, date_onset) |>
    arrange(date_onset, id) |>
    mutate(
      year = format(date_onset, "%Y")
    ) |>
    group_by(year) |>
    mutate(
      notification_index = row_number(),
      cluster_label = paste0(year, "-", sprintf("%04d", notification_index))
    ) |>
    ungroup()

  # Link clustered sequences to the new label
  cluster_labels <- clusters |>
    filter(!is.na(cluster_id)) |>
    select(id, raw_cluster_id = cluster_id) |>
    left_join(
      notification_order |> select(id, date_onset, cluster_label),
      by = "id",
      relationship = "many-to-one"
    ) |>
    arrange(raw_cluster_id, date_onset, id) |>
    group_by(raw_cluster_id) |>
    summarise(
      cluster_label = first(cluster_label),
      .groups = "drop"
    )

  # Join back to cluster data, preserving NA cluster ids
  clusters |>
    left_join(
      cluster_labels,
      by = c("cluster_id" = "raw_cluster_id"),
      relationship = "many-to-one"
    ) |>
    transmute(
      id,
      cluster_id = if_else(is.na(cluster_id), NA_character_, cluster_label)
    )
}