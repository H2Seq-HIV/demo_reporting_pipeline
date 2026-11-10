source(test_path("..", "..", "R", "parse_sierrapy.R"))

suppressPackageStartupMessages(require(dplyr, quietly = TRUE))

test_that("parse_sierrapy_json returns expected long tables", {
  parsed <- parse_sierrapy_json(
    test_path("..", "fixtures", "test_sierrapy.json"),
    resistance_cutoff = 5
  )

  first_id <- "first_sequence"

  expect_equal(nrow(parsed$subtypes), 3)
  expect_equal(
    parsed$subtypes |>
      filter(id == first_id) |>
      pull(subtype),
    "C"
  )

  expect_equal(
    parsed$mutations |>
      filter(id == first_id) |>
      pull(mutation),
    c("D30N", "K98Z") # K98Z is made up
  )

  expect_equal(
    parsed$drugs |>
      filter(id == first_id, drug == "NFV") |>
      pull(resistant),
    1L
  )

  expect_equal(
    parsed$classes |>
      filter(id == first_id, class == "PI") |>
      pull(resistant),
    1L
  )
})

test_that("parse_sierrapy_json retains non-resistant drug scores", {
  parsed <- parse_sierrapy_json(
    test_path("..", "fixtures", "test_sierrapy.json"),
    resistance_cutoff = 5
  )

  expect_equal(
    parsed$drugs |>
      filter(drug == "ATV/r") |>
      pull(resistant),
    0L
  )
})

test_that("parse_sierrapy_json returns expected tibbles", {
  parsed <- parse_sierrapy_json(
    test_path("..", "fixtures", "test_sierrapy.json"),
    resistance_cutoff = 5
  )

  expect_named(parsed, c("mutations", "drugs", "classes", "subtypes"))
  expect_s3_class(parsed$subtypes, "tbl_df")
  expect_s3_class(parsed$mutations, "tbl_df")
  expect_s3_class(parsed$drugs, "tbl_df")
  expect_s3_class(parsed$classes, "tbl_df")
})