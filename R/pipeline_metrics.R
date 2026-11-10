suppressPackageStartupMessages({
  require(dplyr, quietly = TRUE)
  require(stringr, quietly = TRUE)
  require(tibble, quietly = TRUE)
})

#' Determine Data Stream from File Path
#'
#' @param path A character string representing the file path.
#'
#' @return A character string identifying the data stream type based on the path.
#'   Returns one of: "notifications", "sequences_prrtin", "sequences_int",
#'   "sequences", or fallback to the basename of the path.
#'
#' @examples
#' stream_from_path("data/notifications_2023.csv")
#' stream_from_path("data/sequence_prrtin_001.fasta")
#' stream_from_path("data/sequence_int_001.fasta")
#'
#' @export
stream_from_path <- function(path) {
  dplyr::case_when(
    stringr::str_detect(path, "notifications") ~ "notifications",
    stringr::str_detect(path, "sequence_prrtin|prrtin") ~ "sequences_prrtin",
    stringr::str_detect(path, "sequence_int|/int\\.") ~ "sequences_int",
    stringr::str_detect(path, "sequences") ~ "sequences",
    TRUE ~ basename(path)
  )
}

#' Create a Metrics Row from Snakemake Rule Output
#'
#' @param snakemake An S4 object containing Snakemake workflow metadata
#'   (rule, input, output).
#' @param input_name A character string naming the input file key in
#'   snakemake@input.
#' @param output_name A character string naming the output file key in
#'   snakemake@output.
#' @param n_input An integer representing the number of input records/sequences.
#' @param n_output An integer representing the number of output records/sequences.
#' @param n_rejected An integer representing the number of rejected records/sequences.
#'
#' @return A tibble with one row containing metrics for the pipeline step:
#'   \itemize{
#'     \item rule: The Snakemake rule name
#'     \item stream: The data stream type (from stream_from_path)
#'     \item input_file: The input file path
#'     \item output_file: The output file path
#'     \item n_input: Number of input records
#'     \item n_output: Number of output records
#'     \item n_rejected: Number of rejected records
#'   }
#'
#' @examples
#' \dontrun{
#'   metric_row(snakemake, "fasta", "processed", 1000, 950, 50)
#' }
#'
#' @export
metric_row <- function(
  snakemake,
  input_name,
  output_name,
  n_input,
  n_output,
  n_rejected
) {
  output_file <- snakemake@output[[output_name]]

  tibble(
    rule = snakemake@rule,
    stream = stream_from_path(output_file),
    input_file = snakemake@input[[input_name]],
    output_file = output_file,
    n_input = n_input,
    n_output = n_output,
    n_rejected = n_rejected
  )
}