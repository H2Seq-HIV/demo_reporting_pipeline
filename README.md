# Demo H2Seq HIV Pipeline

This is a demo version of the H2Seq HIV pipeline. The dashboard includes only **simulated** notification data simulated atop 347 openly available sequences from [Di Giallonardo et al., 2021](https://doi.org/10.1002/jia2.25655). It is for demonstartion purposes only, and none of the vidualisations or results here have anything to do with reality.

## Demo dashboard 

[https://H2Seq-HIV.github.io/demo_reporting_pipeline/](https://H2Seq-HIV.github.io/demo_reporting_pipeline/)

Hosted on github pages, uses quarto publish gh-pages command locally, rather than an action. Docs [here](https://quarto.org/docs/publishing/github-pages.html).

## Directory structure

The pipeline follows the standard snakemake directory structure, with the addition of a few folders such as `simulate_data/`, `report/`, and `R` that contain data simulation scripts, Quarto dashboard files, and R functions respectively. 


- [`config/`](./config/) — Configuration files for running the demo pipeline, including paths and analysis settings for the simulated dataset.
- [`simulate_data/`](./simulate_data/) — Scripts and inputs used to generate simulated sequence and notification data for the public demo.
- [`resources/`](./resources/) — Reference files and static analysis resources, such as the HXB2 reference sequence and drug-resistance graphql queries.
- [`workflow/`](./workflow/) — Snakemake workflow definition, rules, and helper scripts that run the data-processing pipeline.
- [`R/`](./R/) — Reusable R functions for sequence processing, linkage, metrics, and parsing tool outputs.
- [`report/`](./report/) — Quarto dashboard source files, visual assets, and report components.
- [`tests/`](./tests/) — Automated tests and test fixtures for key `R` functions.
- [`results/`](./results/) — Generated pipeline outputs, including validated data, clustering results, resistance results, dashboard data, and rendered dashboard.
- [`logs/`](./logs/) — Logs produced by pipeline steps and report rendering.