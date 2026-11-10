source(test_path("..", "..", "R", "parse_hivtrace.R"))

# TODO: I need an actual test json for this!


test_that("parse_hivtrace_json extracts sequence cluster assignments", {
  fixture <- withr::local_tempfile(fileext = ".json")

  writeLines(
    c(
      "{",
      '  "trace_results": {',
      '    "Nodes": {',
      '      "id": ["sequence_a", "sequence_b", "sequence_c"],',
      '      "cluster": {',
      '        "values": [1, 1, 2]',
      "      }",
      "    }",
      "  }",
      "}"
    ),
    fixture
  )

  clusters <- parse_hivtrace_json(fixture)

  expect_s3_class(clusters, "tbl_df")
  expect_named(clusters, c("id", "cluster_id"))
  expect_equal(
    clusters,
    tibble::tibble(
      id = c("sequence_a", "sequence_b", "sequence_c"),
      cluster_id = c(1, 1, 2)
    )
  )
})

test_that("name_clusters uses the first notification's annual index", {
  notifications <- tibble::tibble(
    id = c("a", "b", "c", "d", "e"),
    date_onset = as.Date(c(
      "2024-01-02",
      "2024-01-05",
      "2024-02-01",
      "2025-01-01",
      "2025-01-03"
    ))
  )

  clusters <- tibble::tibble(
    id = c("a", "b", "c", "d", "e"),
    cluster_id = c(11, 11, 22, 22, NA)
  )

  expect_equal(
    name_clusters(clusters, notifications),
    tibble::tibble(
      id = c("a", "b", "c", "d", "e"),
      cluster_id = c(
        "2024-0001",
        "2024-0001",
        "2024-0003",
        "2024-0003",
        NA_character_
      )
    )
  )
})