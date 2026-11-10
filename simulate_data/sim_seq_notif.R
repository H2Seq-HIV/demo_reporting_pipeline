library(ape)
library(tidyverse)
library(digest)
library(simulist)
library(epiparameter)

# --- Helpers

bin_age <- function(n) {
  lower <- floor(n / 10) * 10
  upper <- lower + 10
  return(paste0(lower, "-", upper - 1))
}

random_date <- function(start, end, n) {
  start <- as.Date(start)
  end <- as.Date(end)
  as.Date(
    runif(n, min = as.numeric(start), max = as.numeric(end)),
    origin = "1970-01-01"
  )
}

# --- Seed for simulation (also used for digest)
SEED <- 5768

# --- Prepare sequences
start_seq <- read.dna(
  "simulate_data/starting_seqs/sequences.fasta",
  format = "fasta",
  as.character = TRUE
)

set.seed(SEED)
names(start_seq) <- sapply(
  seq_along(start_seq), function(x) digest(x, seed = SEED)
)

# --- Prepare notifications with simulist
contact_distribution <- epiparameter(
  disease = "HIV",
  epi_name = "contact distribution",
  prob_distribution = create_prob_distribution(
    prob_distribution = "pois",
    prob_distribution_params = c(mean = 3)
  )
)

# create HIV infectious period
infectious_period <- epiparameter(
  disease = "HIV",
  epi_name = "infectious period",
  prob_distribution = create_prob_distribution(
    prob_distribution = "gamma",
    prob_distribution_params = c(shape = 365, scale = 1)
  )
)

# linelist
set.seed(SEED)
notifications <- sim_linelist(
  anonymise = TRUE,
  contact_distribution = contact_distribution,
  infectious_period = infectious_period,
  population_age = c(20, 59),
  outbreak_start = as.Date("2010-01-01"),
)

locations <- c(
  "New South Wales",
  "Victoria",
  "Queensland",
  "Western Australia",
  "South Australia",
  "Tasmania",
  "Australian Capital Territory",
  "Northern Territory"
)

linelist <- notifications |>
  slice_sample(n = length(start_seq)) |>
  mutate(
    date_onset = ifelse(
      date_onset > as.Date("2019-12-31"),
      random_date("2019-01-01", "2019-12-31", n()),
      date_onset
    )
  ) |>
  transmute(
    # cap at 2019-12-31
    date_onset = as.Date(date_onset),
    age_at_diagnosis = bin_age(age),
    recent_arrival = sample(c(TRUE, FALSE), size = n(), replace = TRUE, prob = c(0.3, 0.7)),
    acquisition_location = sample(c("Australia", "Overseas"), size = n(), replace = TRUE, prob = c(0.6, 0.4)),
    exposure_category = sample(c("MSM", "IDU", "HET"), size = n(), replace = TRUE, prob = c(0.7, 0.2, 0.1)),
    infection_stage = sample(c("Early", "Late"), size = n(), replace = TRUE, prob = c(0.8, 0.2)),
    gender = sample(c("Cis man", "Cis woman", "Trans woman", "Transgender"), size = n(), replace = TRUE, prob = c(0.7, 0.2, 0.05, 0.05)),
    birth_location = sample(c("Australia", "Overseas"), size = n(), replace = TRUE, prob = c(0.6, 0.4)),
    location = sample(
      locations,
      prob = c(rep(1 / 8, 8)),
      size = n(),
      replace = TRUE
    )
  )

# for sequences later
date_collection <- as.Date(
    # shift ~3 months
    as.numeric(linelist$date_onset) + sample(x = 80:110, size = length(start_seq), replace = TRUE)
  )

linelist$id <- sapply(
  seq_len(nrow(linelist)), function(x) digest(x, seed = SEED)
)

# duplicate a couple of sequences to test the pipeline filtering
linelist <- linelist |>
  add_row(linelist[8, ]) |>
  add_row(linelist[9, ])

# --- Sanity check
sane <- all(
    linelist$id %in% names(start_seq)
  ) &
  all(names(start_seq) %in% linelist$id)

if (!sane) {
  stop("Sanity check failed: linelist IDs and start_seq names do not match.")
}

# --- Save outputs
write_csv(linelist, "simulate_data/output/notifications.csv")

seq_linelist <- tibble(
  id = names(start_seq),
  site = sample(
    c("Site-1", "Site-2", "Site-3"),
    size = length(start_seq),
    replace = TRUE
  ),
  date_collection = date_collection,
  gene_prrtin = "PRRTIN",
  sequence_prrtin = sapply(start_seq, function(x) {
    paste0(x, collapse = "")
  }),
  gene_int = "INT",
  sequence_int = sapply(start_seq, function(x) {
    paste0(x, collapse = "")
  }), # Just copy prrtin for demo purpose (pipeline will filter out duplicates)
  transmitted = TRUE
)

# Duplicate a couple (modifying site) to test filtering
seq_linelist <- seq_linelist |>
  add_row(seq_linelist[8, ] |> mutate(site = "Site-1")) |>
  add_row(seq_linelist[9, ] |> mutate(site = "Site-1"))

write_csv(
  seq_linelist,
  "simulate_data/output/sequences.csv"
)
