# DCDM Group 10: IMPC database and dashboard

Cleans 28,000+ International Mouse Phenotyping Consortium (IMPC) knockout-mouse analysis files, stores them in a MySQL database with procedure, disease and homology data, and displays them in an R Shiny dashboard.

Created: 2026-11-16 · Last updated: 2026-11-26

## Data

**Raw data:** 28,000+ analysis files (one per analysis), egressed from the King's Trusted Research Environment (TRE) with permission and included in `group10_data/`. Supporting files: the IMPC Standard Operating Procedure (SOP, in `reference_files/`), procedure and parameter descriptions, Disease Ontology (DO) disease associations, a BioMart homology export and the collaborator's query genes.

**Outputs:** cleaned tables in `db_tables/`, cleaning logs, and a MySQL dump in `impc_group10_sql/`.

## Running the pipeline

The raw files and supporting files are already in this repository. Clone it, open `IMPC_Group10.Rproj` in RStudio, then render steps 0–4 in order (in RStudio, or `quarto render <file>`):

| Step | File | Input | Purpose | Output |
|---|---|---|---|---|
| 0 | `00_data_exploration.qmd` | `group10_data/` + SOP | Explores the raw files against the SOP and identifies the structural problems fixed in Step 1 | Report only (no data changed) |
| 1 | `01_merge.qmd` | `group10_data/` | Fixes structural problems (field names, broken lines) and merges the raw files into one table | `merged_raw_data.csv`, `merged_raw_data_log.txt` |
| 2 | `02_data_cleaning.qmd` | `merged_raw_data.csv` | Cleans values against the SOP | `cleaned_data.csv`, `cleaned_data_log.csv` |
| 3 | `03_metadata_cleaning.qmd` | `cleaned_data.csv` + supporting files | Cleans supporting files, builds parameter groups | `db_tables/`, `metadata_cleaning_log.csv` |
| 4 | `04_split.qmd` | `cleaned_data.csv` + `db_tables/` | Builds analysis and lacz_expression tables | `db_tables/`, `split_log.csv` |
| 5 | `impc_group10_sql/` | `db_tables/` | Creates and loads the database | dump file |
| 6 | `rshiny/` | MySQL database | Dashboard | `shiny::runApp("rshiny/DCDM_RShiny.R")` |

Then load the database and start the dashboard (replace `your_user` with your MySQL username):

```bash
mysql -u your_user -p -e "CREATE DATABASE impc_group10;"
mysql -u your_user -p impc_group10 < impc_group10_sql/impc_group10_dump.sql
```

Before starting the dashboard, type your MySQL password into `rshiny/db_config.R`.
```r
shiny::runApp("rshiny/DCDM_RShiny.R")
```

## Data management approach

- Raw files in `group10_data/` are never edited; all fixes are made in code.
- Every step logs what it changed and how many rows were affected.
- Values are only corrected when the correction is supported by the source or reference data; otherwise they are stored as `NA` in R and imported as `NULL` in MySQL.
- Where the SOP maximum lengths are shorter than its own allowed values (eg. `mouse_strain` 25 vs 26 characters, LacZ 19 vs 20), column sizes were set from the real data so no records are lost.
- Analysis keys are checked in R before loading; MySQL enforces the rest.
- Steps 0–4 use base R only and record `sessionInfo()` and output checksums, so re-runs can be compared.

## FAIR principles

Standard identifiers (MGI for mouse genes, DOID for diseases, HGNC for human genes, Ensembl for homologs), open formats, logged provenance (`source_file`), and a public repository. The raw data was obtained through the King's TRE and is included so the pipeline can be re-run from the repository.

## Limitations

- Some values could not be recovered and are stored as `NULL` (counts are in the logs).
- Parameter groups are assigned by name and procedure patterns and were not manually checked in full.

## Software requirements

R 4.6.1, Quarto 1.10.18, MySQL 9.7.2; Shiny packages: shiny 1.15.0, ggplot2 4.0.4, DBI 1.3.0, RMySQL 0.11.3. Operating system: macOS 15 / Windows 11 (WSL Ubuntu).

## Data sources and documentation

Each group member's individual report describes the methods and results in full. Data sources: IMPC (https://www.mousephenotype.org), Disease Ontology (https://disease-ontology.org), Ensembl BioMart (https://sep2025.archive.ensembl.org).
