suppressPackageStartupMessages(require(dplyr, quietly = TRUE))

#' Link sequences to notifications by id. Mocks SecureEpiLinkprocedure.
#' That is, many sequences to one notification. If a notification's id
#' is duplicated, it is barred from linking.
#'
#' Notifications and sequences receive a `linked` flag. When `max_lag_days`
#' is supplied, sequences must be collected on or after notification onset
#' and within the specified number of days to be linked.
#'
#' @param notifications A data frame with a unique `id` column.
#' @param sequences A data frame with an `id` column.
#' @param id_col The shared identifier column.
#' @param notification_date_col Notification onset-date column. Required when
#'   `max_lag_days` is set.
#' @param sequence_date_col Sequence collection-date column. Required when
#'   `max_lag_days` is set.
#' @param max_lag_days Maximum non-negative number of days from onset to
#'   collection. Set to `NULL` to disable lag filtering.
#' @return A list with notifications and sequences, each with a boolean
#'   `linked` column.
link_sequences <- function(
  notifications,
  sequences,
  id_col,
  notification_date_col = "date_onset",
  sequence_date_col = "date_collection",
  max_lag_days = NULL
) {
  if (!id_col %in% colnames(notifications)) {
    stop(paste("Column", id_col, "not found in notifications data frame"))
  }
  if (!id_col %in% colnames(sequences)) {
    stop(paste("Column", id_col, "not found in sequences data frame"))
  }

  if (!is.null(max_lag_days)) {
    if (
      !is.numeric(max_lag_days) ||
      length(max_lag_days) != 1 ||
      is.na(max_lag_days) ||
      max_lag_days < 0
    ) {
      stop("max_lag_days must be a single non-negative number")
    }

    if (!notification_date_col %in% colnames(notifications)) {
      stop(
        paste(
          "Column",
          notification_date_col,
          "not found in notifications data frame"
        )
      )
    }
    if (!sequence_date_col %in% colnames(sequences)) {
      stop(
        paste(
          "Column",
          sequence_date_col,
          "not found in sequences data frame"
        )
      )
    }
  }

  linkable_notif <- notifications |>
    group_by(!!sym(id_col)) |>
    filter(n() == 1) |>
    ungroup()

  sequences_with_row_id <- sequences |>
    mutate(.sequence_row_id = row_number())

  linkable_records <- linkable_notif |>
    select(!!sym(id_col))

  if (!is.null(max_lag_days)) {
    linkable_records <- linkable_notif |>
      transmute(
        !!sym(id_col),
        .notification_date = .data[[notification_date_col]]
      )
  }

  eligible_sequences <- sequences_with_row_id |>
    inner_join(
      linkable_records,
      by = id_col,
      relationship = "many-to-one"
    )

  if (!is.null(max_lag_days)) {
    eligible_sequences <- eligible_sequences |>
      mutate(
        lag_days = as.numeric(
          .data[[sequence_date_col]] - .data$.notification_date
        )
      ) |>
      filter(!is.na(lag_days), lag_days >= 0, lag_days <= max_lag_days)
  }

  linked_ids <- eligible_sequences |>
    pull(!!sym(id_col)) |>
    unique()

  linked_sequence_row_ids <- eligible_sequences |>
    pull(.sequence_row_id) |>
    unique()

  notifications_with_linkage <- notifications |>
    mutate(linked = !!sym(id_col) %in% linked_ids)

  sequences_with_linkage <- sequences_with_row_id |>
    mutate(linked = .sequence_row_id %in% linked_sequence_row_ids) |>
    select(-.sequence_row_id)

  list(
    notifications = notifications_with_linkage,
    sequences = sequences_with_linkage
  )
}