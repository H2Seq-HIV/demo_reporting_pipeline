source(testthat::test_path("..", "..", "R", "linkage.R"))

test_that("link_sequences links sequences to notifications by id", {
  notifications <- tibble(id = c("A", "B", "C"), metadata = 1:3)
  sequences <- tibble(id = c("A", "B", "D"), seq_col = c("seq1", "seq2", "seq3"))

  result <- link_sequences(notifications, sequences, id_col = "id")

  expect_true(
    all(result$notifications$linked == c(TRUE, TRUE, FALSE))
  )
  expect_true(
    all(result$sequences$linked == c(TRUE, TRUE, FALSE))
  )
})

test_that("link_sequences does not link duplicated notification ids", {
  notifications <- tibble(id = c("A", "A", "B"), metadata = 1:3)
  sequences <- tibble(id = c("A", "B", "C"), seq_col = c("seq1", "seq2", "seq3"))

  result <- link_sequences(notifications, sequences, id_col = "id")

  expect_true(
    all(result$notifications$linked == c(FALSE, FALSE, TRUE))
  )
  expect_true(
    all(result$sequences$linked == c(FALSE, TRUE, FALSE))
  )
})

test_that("link_sequences preserves num rows in notifications and sequences", {
  notifications <- tibble(id = c("A", "B", "C"), metadata = 1:3)
  sequences <- tibble(id = c("A", "B", "D"), seq_col = c("atgc", "gtac", "caag"))

  result <- link_sequences(notifications, sequences, id_col = "id")

  expect_equal(nrow(result$notifications), nrow(notifications))
  expect_equal(nrow(result$sequences), nrow(sequences))
})

test_that("link_sequences preserves columns", {
  notifications <- tibble(id = c("A", "B", "C"), metadata = 1:3)
  sequences <- tibble(id = c("A", "B", "D"), seq_col = c("atgc", "gtac", "caag"))

  result <- link_sequences(notifications, sequences, id_col = "id")

  expect_equal(colnames(result$notifications), c(colnames(notifications), "linked"))
  expect_equal(colnames(result$sequences), c(colnames(sequences), "linked"))
})

test_that("link_sequences handles no matches gracefully", {
  notifications <- tibble(id = c("A", "B"), metadata = 1:2)
  sequences <- tibble(id = c("C", "D"), seq_col = c("seq1", "seq2"))

  result <- link_sequences(notifications, sequences, id_col = "id")

  expect_equal(result$notifications$linked, rep(FALSE, nrow(result$notifications)))
  expect_equal(result$sequences$linked, rep(FALSE, nrow(result$sequences)))
  expect_equal(class(result$notifications), class(notifications))
  expect_equal(class(result$sequences), class(sequences))
})

test_that("link_sequences handles empty inputs gracefully", {
  notifications <- tibble(id = character(), metadata = integer())
  sequences <- tibble(id = character(), seq_col = character())

  result <- link_sequences(notifications, sequences, id_col = "id")

  expect_equal(nrow(result$notifications), 0)
  expect_equal(nrow(result$sequences), 0)

  expect_equal(ncol(result$notifications), ncol(notifications) + 1)
  expect_equal(ncol(result$sequences), ncol(sequences) + 1)
})

test_that("link_sequences throws error for missing id_col", {
  notifications <- tibble(id = c("A", "B"), metadata = 1:2)
  sequences <- tibble(id = c("A", "B"), seq_col = c("seq1", "seq2"))

  expect_error(
    link_sequences(notifications, sequences, id_col = "missing_col"),
    "Column missing_col not found in notifications data frame"
  )

  notifications_with_seq_col <- notifications |>
    mutate(seq_col = c("x", "y"))

  expect_error(
    link_sequences(notifications_with_seq_col, sequences, id_col = "metadata"),
    "Column metadata not found in sequences data frame"
  )
})

test_that("link_sequences excludes sequences outside the lag window", {
  notifications <- tibble(
    id = c("A", "B"),
    date_onset = as.Date(c("2024-01-01", "2024-01-01"))
  )
  sequences <- tibble(
    id = c("A", "B", "B"),
    date_collection = as.Date(c("2025-12-31", "2026-01-01", "2023-12-31"))
  )

  result <- link_sequences(
    notifications,
    sequences,
    id_col = "id",
    max_lag_days = 730
  )

  expect_equal(result$notifications$linked, c(TRUE, FALSE))
  expect_equal(result$sequences$linked, c(TRUE, FALSE, FALSE))
})

test_that("link_sequences links valid sequences but rejects invalid sequences for the same id", {
  notifications <- tibble(
    id = "A",
    date_onset = as.Date("2024-01-01")
  )
  sequences <- tibble(
    id = c("A", "A"),
    date_collection = as.Date(c("2024-06-01", "2026-01-02"))
  )

  result <- link_sequences(
    notifications,
    sequences,
    id_col = "id",
    max_lag_days = 730
  )

  expect_true(result$notifications$linked)
  expect_equal(result$sequences$linked, c(TRUE, FALSE))
})