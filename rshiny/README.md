# DCDM Coursework RShiny Dashboard (Group 10)

RShiny dashboard for the DCDM Project

## Key Tabs
- **Gene**: pick a knockout gene, shows -log10(p) of all phenotypes tested. points past the dashed line are significant
- **Phenotype**: pick a phenotype (can filter by parameter group), shows -log10(p) of all genes tested
- **Clusters**: genes clustered on their parameter group scores (ward hierarchical clustering), shown as a pca plot and heatmap

## How to run
1. Build the database (see `sql/README.md`)
2. Open `db_config.R` and type in your mysql login
3. Install the packages
   ```r
   install.packages(c("shiny", "DBI", "RMySQL", "ggplot2"))
   ```
4. Open `DCDM_RShiny.R` in RStudio and click Run App
