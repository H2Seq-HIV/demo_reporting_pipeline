#' Coerce a sequence to a character vector of single bases.
#' 
#' The sequence can originally a string, a row in an alignment matrix,
#' or a single sequence in an ape DNAbin object (i.e. (un)aligned `ape` sequences).
#'
#' Supports a single character string, a one-base character vector, a single-row
#' character matrix, or an ape DNAbin object containing exactly one sequence.
#'
#' @param sequence A single DNA sequence.
#' @return An uppercase character vector with one nucleotide or gap per element.
#' 
as_base_vector <- function(sequence) {
  # NA case
  if (length(sequence) == 1 && is.na(sequence)) {
  return(NA_character_)
}

  if (inherits(sequence, "DNAbin")) {
    sequence <- as.character(sequence)
  }

  if (is.matrix(sequence)) {
    if (nrow(sequence) != 1) {
      stop("A matrix sequence input must contain exactly one row.")
    }
    sequence <- sequence[1, ]
  }

  if (is.list(sequence)) {
    if (length(sequence) != 1) {
      stop("A list sequence input must contain exactly one sequence.")
    }
    sequence <- sequence[[1]]
  }

  if (!is.character(sequence)) {
    stop("Sequence must be a character string, one-base character vector, or DNAbin.")
  }

  if (length(sequence) == 1) {
    sequence <- strsplit(sequence, "", fixed = TRUE)[[1]]
  }

  if (any(nchar(sequence) != 1)) {
    stop("Sequence elements must be single bases.")
  }

  toupper(sequence)
}

#' Check whether a sequence contains only valid IUPAC DNA bases and gaps.
#'
#' @param sequence A single DNA sequence accepted by [as_base_vector()].
#' @return A single logical value.
#' 
is_seq <- function(sequence) {

  if (length(sequence) == 1 && is.na(sequence)) {
    return(NA)
  }
  
  bases <- as_base_vector(sequence)
  valid_bases <- c(
    "A", "C", "G", "T", "N", "R", "Y", "S", "W",
    "K", "M", "B", "D", "H", "V", "-"
  )

  all(bases %in% valid_bases)
}

#' Calculate the proportion of ambiguous bases in one sequence.
#'
#' Gaps are excluded from the denominator. N and all IUPAC ambiguity codes are
#' treated as ambiguous bases. A sequence containing only gaps has ambiguity 1.
#'
#' @param sequence A single DNA sequence accepted by [as_base_vector()].
#' @return A numeric scalar between 0 and 1.
calc_ambiguity <- function(sequence) {
  bases <- as_base_vector(sequence)
  defined <- bases != "-"

  if (!any(defined)) {
    return(1)
  }

  ambiguous_bases <- c("N", "R", "Y", "S", "W", "K", "M", "B", "D", "H", "V")
  mean(bases[defined] %in% ambiguous_bases)
}

#' Count bases and gaps in one sequence.
#'
#' @param sequence A single DNA sequence accepted by [as_base_vector()].
#' @return An integer scalar.
seq_length <- function(sequence) {
  length(as_base_vector(sequence))
}