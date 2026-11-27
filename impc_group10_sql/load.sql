-- load.sql
-- loads the 16 csv files in db_tables/ into impc_group10
-- run after schema.sql
-- csv files need unix line endings (\n)
-- NULLIF turns the text 'NA' into NULL
-- TRUE/FALSE columns are changed to 1/0

SET GLOBAL local_infile = 1;   -- needs root
USE impc_group10;
SET FOREIGN_KEY_CHECKS = 1;

-- species: species.csv
LOAD DATA LOCAL INFILE 'db_tables/species.csv'
  INTO TABLE species
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@species_id, @common_name, @scientific_name, @ensembl_prefix)
  SET
    species_id = NULLIF(TRIM(TRAILING '\r' FROM @species_id), 'NA'),
    common_name = NULLIF(TRIM(TRAILING '\r' FROM @common_name), 'NA'),
    scientific_name = NULLIF(TRIM(TRAILING '\r' FROM @scientific_name), 'NA'),
    ensembl_prefix = NULLIF(TRIM(TRAILING '\r' FROM @ensembl_prefix), 'NA');

-- impc_procedure: procedure.csv
LOAD DATA LOCAL INFILE 'db_tables/procedure.csv'
  INTO TABLE impc_procedure
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@procedure_id, @procedure_name, @description, @is_mandatory)
  SET
    procedure_id = NULLIF(TRIM(TRAILING '\r' FROM @procedure_id), 'NA'),
    procedure_name = NULLIF(TRIM(TRAILING '\r' FROM @procedure_name), 'NA'),
    description = NULLIF(TRIM(TRAILING '\r' FROM @description), 'NA'),
    is_mandatory = (TRIM(TRAILING '\r' FROM @is_mandatory) = 'TRUE');

-- gene: gene.csv
LOAD DATA LOCAL INFILE 'db_tables/gene.csv'
  INTO TABLE gene
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@mgi_id, @gene_symbol, @in_impc_data)
  SET
    mgi_id = NULLIF(TRIM(TRAILING '\r' FROM @mgi_id), 'NA'),
    gene_symbol = NULLIF(TRIM(TRAILING '\r' FROM @gene_symbol), 'NA'),
    in_impc_data = (TRIM(TRAILING '\r' FROM @in_impc_data) = 'TRUE');

-- disease: disease.csv
LOAD DATA LOCAL INFILE 'db_tables/disease.csv'
  INTO TABLE disease
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@doid, @disease_name)
  SET
    doid = NULLIF(TRIM(TRAILING '\r' FROM @doid), 'NA'),
    disease_name = NULLIF(TRIM(TRAILING '\r' FROM @disease_name), 'NA');

-- human_gene: human_gene.csv
LOAD DATA LOCAL INFILE 'db_tables/human_gene.csv'
  INTO TABLE human_gene
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@hgnc_id, @human_symbol, @human_name, @mgi_id)
  SET
    hgnc_id = NULLIF(TRIM(TRAILING '\r' FROM @hgnc_id), 'NA'),
    human_symbol = NULLIF(TRIM(TRAILING '\r' FROM @human_symbol), 'NA'),
    human_name = NULLIF(TRIM(TRAILING '\r' FROM @human_name), 'NA'),
    mgi_id = NULLIF(TRIM(TRAILING '\r' FROM @mgi_id), 'NA');

-- ensembl_gene: ensembl_gene.csv
LOAD DATA LOCAL INFILE 'db_tables/ensembl_gene.csv'
  INTO TABLE ensembl_gene
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@ensembl_gene_id, @species_id, @gene_name, @mgi_id)
  SET
    ensembl_gene_id = NULLIF(TRIM(TRAILING '\r' FROM @ensembl_gene_id), 'NA'),
    species_id = NULLIF(TRIM(TRAILING '\r' FROM @species_id), 'NA'),
    gene_name = NULLIF(TRIM(TRAILING '\r' FROM @gene_name), 'NA'),
    mgi_id = NULLIF(TRIM(TRAILING '\r' FROM @mgi_id), 'NA');

-- parameter_group: parameter_group.csv
LOAD DATA LOCAL INFILE 'db_tables/parameter_group.csv'
  INTO TABLE parameter_group
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@group_id, @group_name, @rule, @n_parameters)
  SET
    group_id = NULLIF(TRIM(TRAILING '\r' FROM @group_id), 'NA'),
    group_name = NULLIF(TRIM(TRAILING '\r' FROM @group_name), 'NA'),
    rule = NULLIF(TRIM(TRAILING '\r' FROM @rule), 'NA');

-- parameter: parameter.csv
LOAD DATA LOCAL INFILE 'db_tables/parameter.csv'
  INTO TABLE parameter
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@parameter_id, @parameter_name, @procedure_id, @procedure_source, @in_impc_catalogue)
  SET
    parameter_id = NULLIF(TRIM(TRAILING '\r' FROM @parameter_id), 'NA'),
    parameter_name = NULLIF(TRIM(TRAILING '\r' FROM @parameter_name), 'NA'),
    procedure_id = NULLIF(TRIM(TRAILING '\r' FROM @procedure_id), 'NA'),
    procedure_source = NULLIF(TRIM(TRAILING '\r' FROM @procedure_source), 'NA'),
    in_impc_catalogue = (TRIM(TRAILING '\r' FROM @in_impc_catalogue) = 'TRUE');

-- analysis: analysis.csv
LOAD DATA LOCAL INFILE 'db_tables/analysis.csv'
  INTO TABLE analysis
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@analysis_id, @mgi_id, @parameter_id, @parameter_name_unlinked, @mouse_strain, @mouse_life_stage, @pvalue, @allele_symbol, @source_file)
  SET
    analysis_id = NULLIF(TRIM(TRAILING '\r' FROM @analysis_id), 'NA'),
    mgi_id = NULLIF(TRIM(TRAILING '\r' FROM @mgi_id), 'NA'),
    parameter_id = NULLIF(TRIM(TRAILING '\r' FROM @parameter_id), 'NA'),
    parameter_name_unlinked = NULLIF(TRIM(TRAILING '\r' FROM @parameter_name_unlinked), 'NA'),
    mouse_strain = NULLIF(TRIM(TRAILING '\r' FROM @mouse_strain), 'NA'),
    mouse_life_stage = NULLIF(TRIM(TRAILING '\r' FROM @mouse_life_stage), 'NA'),
    pvalue = NULLIF(TRIM(TRAILING '\r' FROM @pvalue), 'NA'),
    allele_symbol = NULLIF(TRIM(TRAILING '\r' FROM @allele_symbol), 'NA'),
    source_file = NULLIF(TRIM(TRAILING '\r' FROM @source_file), 'NA');

-- lacz_expression: lacz_expression.csv
LOAD DATA LOCAL INFILE 'db_tables/lacz_expression.csv'
  INTO TABLE lacz_expression
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@analysis_id, @tissue, @expression)
  SET
    analysis_id = NULLIF(TRIM(TRAILING '\r' FROM @analysis_id), 'NA'),
    tissue = NULLIF(TRIM(TRAILING '\r' FROM @tissue), 'NA'),
    expression = NULLIF(TRIM(TRAILING '\r' FROM @expression), 'NA');

-- parameter_variant: parameter_variant.csv
LOAD DATA LOCAL INFILE 'db_tables/parameter_variant.csv'
  INTO TABLE parameter_variant
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@impc_parameter_orig_id, @parameter_id, @name, @description)
  SET
    impc_parameter_orig_id = NULLIF(TRIM(TRAILING '\r' FROM @impc_parameter_orig_id), 'NA'),
    parameter_id = NULLIF(TRIM(TRAILING '\r' FROM @parameter_id), 'NA'),
    name = NULLIF(TRIM(TRAILING '\r' FROM @name), 'NA'),
    description = NULLIF(TRIM(TRAILING '\r' FROM @description), 'NA');

-- parameter_group_map: parameter_group_map.csv
LOAD DATA LOCAL INFILE 'db_tables/parameter_group_map.csv'
  INTO TABLE parameter_group_map
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@parameter_id, @group_id)
  SET
    parameter_id = NULLIF(TRIM(TRAILING '\r' FROM @parameter_id), 'NA'),
    group_id = NULLIF(TRIM(TRAILING '\r' FROM @group_id), 'NA');

-- gene_disease: gene_disease.csv
LOAD DATA LOCAL INFILE 'db_tables/gene_disease.csv'
  INTO TABLE gene_disease
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@gene_disease_id, @mgi_id, @doid)
  SET
    gene_disease_id = NULLIF(TRIM(TRAILING '\r' FROM @gene_disease_id), 'NA'),
    mgi_id = NULLIF(TRIM(TRAILING '\r' FROM @mgi_id), 'NA'),
    doid = NULLIF(TRIM(TRAILING '\r' FROM @doid), 'NA');

-- disease_model_genotype: disease_model_genotype.csv
LOAD DATA LOCAL INFILE 'db_tables/disease_model_genotype.csv'
  INTO TABLE disease_model_genotype
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@gene_disease_id, @genotype_id)
  SET
    gene_disease_id = NULLIF(TRIM(TRAILING '\r' FROM @gene_disease_id), 'NA'),
    genotype_id = NULLIF(TRIM(TRAILING '\r' FROM @genotype_id), 'NA');

-- homology:  homology.csv
LOAD DATA LOCAL INFILE 'db_tables/homology.csv'
  INTO TABLE homology
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@mouse_ensembl_id, @homolog_ensembl_id, @homology_type, @percent_identity, @last_common_ancestor)
  SET
    mouse_ensembl_id = NULLIF(TRIM(TRAILING '\r' FROM @mouse_ensembl_id), 'NA'),
    homolog_ensembl_id = NULLIF(TRIM(TRAILING '\r' FROM @homolog_ensembl_id), 'NA'),
    homology_type = NULLIF(TRIM(TRAILING '\r' FROM @homology_type), 'NA'),
    percent_identity = NULLIF(TRIM(TRAILING '\r' FROM @percent_identity), 'NA'),
    last_common_ancestor = NULLIF(TRIM(TRAILING '\r' FROM @last_common_ancestor), 'NA');

-- query_gene: query_gene.csv
LOAD DATA LOCAL INFILE 'db_tables/query_gene.csv'
  INTO TABLE query_gene
  CHARACTER SET utf8mb4
  FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
  IGNORE 1 LINES
  (@gene_symbol, @mgi_id, @n_analyses)
  SET
    gene_symbol = NULLIF(TRIM(TRAILING '\r' FROM @gene_symbol), 'NA'),
    mgi_id = NULLIF(TRIM(TRAILING '\r' FROM @mgi_id), 'NA');

-- check row counts (n_rows should match expected)
SELECT 'species' AS tbl, COUNT(*) AS n_rows, 3 AS expected FROM species
UNION ALL SELECT 'impc_procedure',         COUNT(*), 51     FROM impc_procedure
UNION ALL SELECT 'gene',                   COUNT(*), 6923   FROM gene
UNION ALL SELECT 'disease',                COUNT(*), 5727   FROM disease
UNION ALL SELECT 'human_gene',             COUNT(*), 4992   FROM human_gene
UNION ALL SELECT 'ensembl_gene',           COUNT(*), 58472  FROM ensembl_gene
UNION ALL SELECT 'parameter_group',        COUNT(*), 12     FROM parameter_group
UNION ALL SELECT 'parameter',              COUNT(*), 4632   FROM parameter
UNION ALL SELECT 'analysis',               COUNT(*), 28424  FROM analysis
UNION ALL SELECT 'lacz_expression',        COUNT(*), 309504 FROM lacz_expression
UNION ALL SELECT 'parameter_variant',      COUNT(*), 5311   FROM parameter_variant
UNION ALL SELECT 'parameter_group_map',    COUNT(*), 3432   FROM parameter_group_map
UNION ALL SELECT 'gene_disease',           COUNT(*), 13912  FROM gene_disease
UNION ALL SELECT 'disease_model_genotype', COUNT(*), 138055 FROM disease_model_genotype
UNION ALL SELECT 'homology',               COUNT(*), 48760  FROM homology
UNION ALL SELECT 'query_gene',             COUNT(*), 5      FROM query_gene;

-- check NA was loaded as NULL (should be 0 and 169)
SELECT SUM(parameter_id = 'NA') AS text_NA_left, SUM(parameter_id IS NULL) AS real_nulls_169 FROM analysis;
