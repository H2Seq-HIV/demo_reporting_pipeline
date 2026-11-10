
suppressPackageStartupMessages({
  require(jsonlite, quietly = TRUE)
  require(tidyverse, quietly = TRUE)
})

#' Parse Stanford HIVdb JSON output into long tables.
#' Tailored to the gql query: resources/stanford_query.gql
#'
#' @param json_path Path to the JSON file.
#' @param resistance_cutoff The level at which a drug is considered resistant.
#' @return A list containing data frames for drugs, classes, mutations, and subtypes.
parse_sierrapy_json <- function(json_path, resistance_cutoff) {
  json <- fromJSON(json_path, simplifyVector = FALSE)

  records <- tibble(sequence = json) |>
    unnest_wider(sequence) |>
    hoist(inputSequence, id = "header")

  # One row per input sequence and drug score.
  drug_scores <- records |>
    select(id, drugResistance) |>
    unnest_longer(drugResistance) |>
    unnest_wider(drugResistance) |>
    unnest_longer(drugScores) |>
    hoist(
      drugScores,
      class = c("drugClass", "name"),
      drug = c("drug", "displayAbbr"),
      level = "level"
    ) |>
    select(id, class, drug, level)

  drug_resistance <- drug_scores |>
    group_by(id, drug) |>
    summarise(
      resistant = as.integer(max(level) >= resistance_cutoff),
      .groups = "drop"
    )

  class_resistance <- drug_scores |>
    group_by(id, class) |>
    summarise(
      resistant = as.integer(max(level) >= resistance_cutoff),
      .groups = "drop"
    )

  # SDRMs are directly available per aligned gene sequence.
  mutations <- records |>
    select(id, alignedGeneSequences) |>
    unnest_longer(alignedGeneSequences) |>
    unnest_wider(alignedGeneSequences) |>
    unnest_longer(SDRM) |>
    hoist(SDRM, mutation = "text") |>
    select(id, mutation) |>
    distinct()

  subtypes <- records |>
    hoist(bestMatchingSubtype, subtype = "display") |>
    select(id, subtype) |>
    mutate(subtype = str_remove(subtype, " \\(.+$"))
  
  # TODO: Handle top X subtypes

  list(
    mutations = mutations,
    drugs = drug_resistance,
    classes = class_resistance,
    subtypes = subtypes
  )
}