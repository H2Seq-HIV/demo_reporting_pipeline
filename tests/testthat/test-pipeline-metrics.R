source(testthat::test_path("..", "..", "R", "pipeline_metrics.R"))

# Mock Snakemake class for testing
if (!methods::isClass("MockSnakemake")) {
  methods::setClass(
    "MockSnakemake",
    slots = c(
      rule = "character",
      input = "list",
      output = "list"
    )
  )
}

test_that("stream_from_path identifies known pipeline streams", {
  expect_equal(
    stream_from_path("results/data_validated/notifications.csv"),
    "notifications"
  )
  expect_equal(
    stream_from_path("results/linked/sequences.csv"),
    "sequences"
  )
  expect_equal(
    stream_from_path("results/linked/prrtin.fasta"),
    "sequences_prrtin"
  )
  expect_equal(
    stream_from_path("results/linked/int.fasta"),
    "sequences_int"
  )
})

test_that("stream_from_path prioritises notifications over other path terms", {
  expect_equal(
    stream_from_path("results/notifications_with_sequences.csv"),
    "notifications"
  )
})

test_that("stream_from_path falls back to the file name for unknown paths", {
  expect_equal(
    stream_from_path("results/other/custom_records.csv"),
    "custom_records.csv"
  )
})

test_that("metric_row returns provenance and counts for a sequence stream", {
  snakemake <- methods::new(
    "MockSnakemake",
    rule = "extract_transmitted",
    input = list(sequences = "results/data_validated/sequences.csv"),
    output = list(sequences = "results/extract_transmitted/sequences.csv")
  )

  result <- metric_row(
    snakemake = snakemake,
    input_name = "sequences",
    output_name = "sequences",
    n_input = 11880,
    n_output = 8790,
    n_rejected = 3090
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(
    names(result),
    c(
      "rule",
      "stream",
      "input_file",
      "output_file",
      "n_input",
      "n_output",
      "n_rejected"
    )
  )
  expect_equal(result$rule, "extract_transmitted")
  expect_equal(result$stream, "sequences")
  expect_equal(
    result$input_file,
    "results/data_validated/sequences.csv"
  )
  expect_equal(
    result$output_file,
    "results/extract_transmitted/sequences.csv"
  )
  expect_equal(result$n_input, 11880)
  expect_equal(result$n_output, 8790)
  expect_equal(result$n_rejected, 3090)
})

test_that("metric_row derives the stream from its output file", {
  snakemake <- methods::new(
    "MockSnakemake",
    rule = "convert_fasta",
    input = list(sequences = "results/linked/sequences.csv"),
    output = list(fasta = "results/linked/prrtin.fasta")
  )

  result <- metric_row(
    snakemake = snakemake,
    input_name = "sequences",
    output_name = "fasta",
    n_input = 3758,
    n_output = 3758,
    n_rejected = 0
  )

  expect_equal(result$stream, "sequences_prrtin")
})