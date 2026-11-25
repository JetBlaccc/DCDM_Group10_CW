# DCDM Group 10: IMPC phenotype database and dashboard

Cleans 28,000+ International Mouse Phenotyping Consortium (IMPC) knockout-mouse analysis files, stores them in a MySQL database with procedure, disease and homology data, and displays them in an R Shiny dashboard.

|                       |                                                |
|-----------------------|------------------------------------------------|
| **Authors**           | DCDM Group 10, King's College London           |
| **Database**          | `impc_group10`                                 |
| **Repository**        | <https://github.com/JetBlaccc/DCDM_Group10_CW> |
| **Created / updated** | 2026-11-16 / 2026-11-24                        |

## Data

-   **Raw data:** 28,000+ analysis files (one per analysis) plus supporting files: the IMPC Standard Operating Procedure (SOP), procedure and parameter descriptions, Disease Ontology (DO) disease associations, a BioMart homology export and the collaborator's query genes. Held in the King's Trusted Research Environment (TRE) and not included here.
-   **Outputs:** cleaned tables in `db_tables/`, cleaning logs, and a MySQL dump in `impc_group10_sql/`.

## Running the pipeline

Put the raw files in `group10_data/` and the supporting files in this folder, then render steps 1–4 in order (in RStudio, or `quarto render <file>`):

| Step | File | Input | Purpose | Output |
|----|----|----|----|----|
| 1 | `01_merge.qmd` | `group10_data/` | Merges raw files into one table | `merged_raw_data.csv` |
| 2 | `02_data_cleaning.qmd` | `merged_raw_data.csv` | Cleans values against the SOP | `cleaned_data.csv` |
| 3 | `03_metadata_cleaning.qmd` | `cleaned_data.csv` + supporting files | Cleans supporting files, builds parameter groups | `db_tables/` |
| 4 | `04_split.qmd` | `cleaned_data.csv` + `db_tables/` | Builds `analysis` and `lacz_expression` tables | `db_tables/` |
| 5 | `impc_group10_sql/` | `db_tables/` | Creates and loads the database | dump file |
| 6 | `[⚠ TODO: Shiny folder]` | MySQL database | Dashboard | — |

Then load the database and start the dashboard (replace `your_user` with your MySQL username):

``` bash
mysql -u your_user -p -e "CREATE DATABASE impc_group10;"
mysql -u your_user -p impc_group10 < impc_group10_sql/[⚠ TODO: dump file name].sql
```

``` r
shiny::runApp("[⚠ TODO: Shiny folder]")
```

## Data management approach

-   Every step logs what it changed and how many rows were affected.
-   Values are only corrected when the correction is supported by the source or reference data; otherwise they are stored as `NA` in R and imported as `NULL` in MySQL.
-   Analysis keys are checked in R before loading; MySQL enforces the rest.
-   Steps 1–4 use base R only and record `sessionInfo()` and output checksums, so re-runs can be compared.

## FAIR principles

Standard identifiers (MGI for mouse genes, DOID for diseases, HGNC for human genes, Ensembl for homologs), open formats, logged provenance (`source_file`), and a public repository. Raw data access is controlled by the TRE.

## Limitations

-   The raw data cannot be shared, so only people with TRE access can re-run steps 1–4.
-   Some values could not be recovered and are stored as `NULL` (counts are in the logs).
-   Parameter groups are assigned by name and procedure patterns and were not manually checked in full.

## Software requirements

R `[⚠ TODO: version]`, Quarto `[⚠ TODO: version]`, MySQL `[⚠ TODO: version]`; Shiny packages: `[⚠ TODO: list with versions]`. Operating system: `[⚠ TODO: e.g. macOS 15 / CREATE HPC]`.

## Data sources and documentation

Each group member's individual report describes the methods and results in full. Data sources: IMPC (<https://www.mousephenotype.org>), Disease Ontology (<https://disease-ontology.org>), Ensembl BioMart (<https://sep2025.archive.ensembl.org>).
