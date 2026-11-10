# ==============================================================================
# Validate input notification data and separate accepted and rejected rows
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(pointblank)
})
source("R/pipeline_metrics.R") # for metric_row() function

VALID_EXPOSURE <- c("MSM", "HET", "IDU", "Unknown/Other")
VALID_ACQUISITION <- c("Australia", "Overseas", "Unknown/Other")
VALID_STAGE <- c("Early", "Late", "Unknown/Other")
VALID_AGE <- c("0-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60+")
VALID_BIRTH <- c("Australia", "Overseas", "Unknown/Other")

validate_notifications <- function(notifications) {

  # Log stdout and std error to file, following snakemake docs
  log <- file(snakemake@log[[1]], open="wt")
  sink(log)
  sink(log, type="message")
  
  create_agent(tbl = notifications, label = "Notifications") |>
    col_exists(c(
        id, date_onset, recent_arrival, exposure_category,
        acquisition_location, infection_stage, age_at_diagnosis,
        location, gender, birth_location
      ),
      brief = "All required notification columns are present"
    ) |>
    col_vals_not_null(c(
        id, date_onset, recent_arrival, exposure_category,
        acquisition_location, infection_stage, age_at_diagnosis,
        location, gender, birth_location
      ),
      brief = "Required notification fields are not missing"
    ) |>
    col_is_character(c(
        id, exposure_category, acquisition_location,
        infection_stage, age_at_diagnosis, location, gender, birth_location
      ),
      brief = "Categorical notification fields are character values"
    ) |>
    col_is_logical(recent_arrival, brief = "Recent arrival is a logical value") |>
    col_is_date(date_onset, brief = "Date of onset is a date") |>
    col_vals_in_set(
      exposure_category,
      set = VALID_EXPOSURE,
      brief = "Exposure category uses an allowed value"
    ) |>
    col_vals_in_set(
      acquisition_location,
      set = VALID_ACQUISITION,
      brief = "Acquisition location uses an allowed value"
    ) |>
    col_vals_in_set(
      infection_stage,
      set = VALID_STAGE,
      brief = "Infection stage uses an allowed value"
    ) |>
    col_vals_in_set(
      age_at_diagnosis,
      set = VALID_AGE,
      brief = "Age at diagnosis uses an allowed value"
    ) |>
    col_vals_in_set(
      birth_location,
      set = VALID_BIRTH,
      brief = "Birth location uses an allowed value"
    ) |>
    interrogate()
}

main <- function(snakemake) {
  notifications <- read_csv(snakemake@input$notifications, show_col_types = FALSE)

  agent <- validate_notifications(notifications)
  passed <- get_sundered_data(agent, type = "pass")
  failed <- get_sundered_data(agent, type = "fail")

  metrics <- metric_row(
      snakemake,
      input_name = "notifications",
      output_name = "notifications",
      n_input = nrow(notifications),
      n_output = nrow(passed),
      n_rejected = nrow(failed)
  )

  export_report(
    agent,
    filename = snakemake@log$report,
    quiet = TRUE
  )

  write_csv(passed, snakemake@output$notifications)
  write_csv(failed, snakemake@output$rejected)
  write_csv(metrics, snakemake@output$metrics)
}

main(snakemake)