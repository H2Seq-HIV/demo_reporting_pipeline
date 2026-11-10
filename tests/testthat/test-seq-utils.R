source(testthat::test_path("..", "..", "R", "seq_utils.R"))

test_that("as_base_vector normalises character inputs", {
  expect_equal(as_base_vector("acgtn-"), c("A", "C", "G", "T", "N", "-"))
  expect_equal(as_base_vector(c("a", "c", "g")), c("A", "C", "G"))
})

test_that("as_base_vector accepts a one-row matrix", {
  sequence <- matrix(c("a", "c", "g", "t"), nrow = 1)

  expect_equal(as_base_vector(sequence), c("A", "C", "G", "T"))
})

test_that("as_base_vector rejects multi-sequence and malformed inputs", {
  expect_error(
    as_base_vector(matrix(c("A", "C", "G", "T"), nrow = 2)),
    "exactly one row"
  )
  expect_error(as_base_vector(c("AC", "G")), "single bases")
  expect_error(as_base_vector(42), "character string")
})

test_that("is_seq recognises IUPAC bases and rejects invalid symbols", {
  expect_true(is_seq("ACGTNRYSWKMBDHV-"))
  expect_true(is_seq("acgtn"))
  expect_false(is_seq("ACGTX"))
  expect_false(is_seq("ACGT?"))
})

test_that("calc_ambiguity counts ambiguity codes and ignores gaps", {
  expect_equal(calc_ambiguity("ACGT"), 0)
  expect_equal(calc_ambiguity("ACGN"), 0.25)
  expect_equal(calc_ambiguity("A-RN"), 2 / 3)
  expect_equal(calc_ambiguity("---"), 1)
})

test_that("seq_length counts bases and gaps consistently", {
  expect_equal(seq_length("ACGTN-"), 6L)
  expect_equal(seq_length(c("A", "C", "G")), 3L)
})

test_that("utilities accept a single DNAbin sequence", {
  sequence <- ape::as.DNAbin(c("a", "c", "g", "n"))

  expect_equal(as_base_vector(sequence), c("A", "C", "G", "N"))
  expect_true(is_seq(sequence))
  expect_equal(calc_ambiguity(sequence), 0.25)
  expect_equal(seq_length(sequence), 4L)
})