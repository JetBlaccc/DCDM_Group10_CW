-- =============================================================================
-- schema.sql  -  IMPC Group 10 database (MySQL 8.0.16+)
-- Builds the empty database for the CSVs in db_tables/ (16 tables).
-- Follows the group plan "Loading into MySQL":
--   * types sized from the real maximum lengths (not the SOP limits)
--   * parents before children, composite PKs on the 4 link tables
--   * nullable FKs: analysis.parameter_id, parameter.procedure_id, ensembl_gene.mgi_id
--   * utf8mb4 (so "Naive" with the diaeresis survives) + InnoDB (FKs enforced)
--   * extras: indexes for Shiny, CHECK constraints for SOP values, views
--
-- Run in DBeaver: open, attach to the connection, Execute SQL Script (Alt/Option+X)
-- or terminal:    mysql -u root -p < schema.sql
-- =============================================================================

DROP DATABASE IF EXISTS impc_group10;
CREATE DATABASE impc_group10 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE impc_group10;

-- -----------------------------------------------------------------------------
-- PARENT TABLES
-- -----------------------------------------------------------------------------
CREATE TABLE species (
  species_id       INT          NOT NULL,
  common_name      VARCHAR(20)  NOT NULL,
  scientific_name  VARCHAR(50)  NOT NULL,
  ensembl_prefix   VARCHAR(10)  NOT NULL,
  PRIMARY KEY (species_id),
  UNIQUE KEY uq_species_name (common_name)
) ENGINE = InnoDB COMMENT = 'Species in the homology data; add a row per new species';

-- `procedure` is a reserved word in MySQL, so the table is impc_procedure
CREATE TABLE impc_procedure (
  procedure_id    INT           NOT NULL,
  procedure_name  VARCHAR(100)  NOT NULL,
  description     TEXT          NULL,
  is_mandatory    BOOLEAN       NOT NULL,
  PRIMARY KEY (procedure_id),
  UNIQUE KEY uq_procedure_name (procedure_name)
) ENGINE = InnoDB COMMENT = 'The 51 IMPC phenotyping procedures';

CREATE TABLE gene (
  mgi_id        VARCHAR(15)  NOT NULL,
  gene_symbol   VARCHAR(30)  NOT NULL,
  in_impc_data  BOOLEAN      NOT NULL,
  PRIMARY KEY (mgi_id),
  INDEX idx_gene_symbol (gene_symbol),
  CONSTRAINT chk_gene_mgi CHECK (mgi_id REGEXP '^MGI:[0-9]+$')
) ENGINE = InnoDB COMMENT = 'Mouse genes keyed by MGI accession';

CREATE TABLE disease (
  doid          VARCHAR(20)   NOT NULL,
  disease_name  VARCHAR(200)  NOT NULL,
  PRIMARY KEY (doid),
  CONSTRAINT chk_doid CHECK (doid REGEXP '^DOID:[0-9]+$')
) ENGINE = InnoDB COMMENT = 'Disease Ontology terms';

CREATE TABLE human_gene (
  hgnc_id       VARCHAR(15)   NOT NULL,
  human_symbol  VARCHAR(30)   NOT NULL,
  human_name    VARCHAR(150)  NULL,
  mgi_id        VARCHAR(15)   NOT NULL,
  PRIMARY KEY (hgnc_id),
  UNIQUE KEY uq_human_gene_mgi (mgi_id),
  CONSTRAINT fk_human_gene_mouse FOREIGN KEY (mgi_id) REFERENCES gene (mgi_id)
) ENGINE = InnoDB COMMENT = 'Human genes with a one-to-one mouse ortholog';

CREATE TABLE ensembl_gene (
  ensembl_gene_id  VARCHAR(20)  NOT NULL,
  species_id       INT          NOT NULL,
  gene_name        VARCHAR(30)  NULL,
  mgi_id           VARCHAR(15)  NULL,
  PRIMARY KEY (ensembl_gene_id),
  INDEX idx_ensembl_mgi (mgi_id),
  INDEX idx_ensembl_name (gene_name),
  CONSTRAINT fk_ensembl_species FOREIGN KEY (species_id) REFERENCES species (species_id),
  CONSTRAINT fk_ensembl_mgi     FOREIGN KEY (mgi_id)     REFERENCES gene (mgi_id)
) ENGINE = InnoDB COMMENT = 'Ensembl genes of all species (bespoke homology task)';

CREATE TABLE parameter_group (
  group_id    INT           NOT NULL,
  group_name  VARCHAR(30)   NOT NULL,
  rule        VARCHAR(150)  NOT NULL,
  PRIMARY KEY (group_id),
  UNIQUE KEY uq_group_name (group_name)
) ENGINE = InnoDB COMMENT = 'Parameter groupings: weight, images, brain + 9 more';

CREATE TABLE parameter (
  parameter_id       VARCHAR(30)   NOT NULL,
  parameter_name     VARCHAR(150)  NOT NULL,
  procedure_id       INT           NULL,
  procedure_source   VARCHAR(30)   NULL,
  in_impc_catalogue  BOOLEAN       NOT NULL,
  PRIMARY KEY (parameter_id),
  INDEX idx_parameter_name (parameter_name),
  CONSTRAINT fk_parameter_procedure FOREIGN KEY (procedure_id) REFERENCES impc_procedure (procedure_id),
  CONSTRAINT chk_procedure_source CHECK (procedure_source IN ('catalogue', 'inferred_from_id_code'))
) ENGINE = InnoDB COMMENT = 'One row per parameter_id';

-- -----------------------------------------------------------------------------
-- CHILD TABLES
-- -----------------------------------------------------------------------------
CREATE TABLE analysis (
  analysis_id              VARCHAR(15)   NOT NULL,
  mgi_id                   VARCHAR(15)   NOT NULL,
  parameter_id             VARCHAR(30)   NULL,
  parameter_name_unlinked  VARCHAR(150)  NULL,
  mouse_strain             VARCHAR(30)   NOT NULL,
  mouse_life_stage         VARCHAR(20)   NULL,
  pvalue                   DOUBLE        NULL,
  allele_symbol            VARCHAR(50)   NULL,
  source_file              VARCHAR(30)   NOT NULL,
  PRIMARY KEY (analysis_id),
  INDEX idx_analysis_mgi (mgi_id),
  INDEX idx_analysis_parameter (parameter_id),
  INDEX idx_analysis_pvalue (pvalue),
  CONSTRAINT fk_analysis_gene      FOREIGN KEY (mgi_id)       REFERENCES gene (mgi_id),
  CONSTRAINT fk_analysis_parameter FOREIGN KEY (parameter_id) REFERENCES parameter (parameter_id),
  CONSTRAINT chk_analysis_id     CHECK (analysis_id REGEXP '^an[0-9]{10}$'),
  CONSTRAINT chk_analysis_pvalue CHECK (pvalue BETWEEN 0 AND 1),
  CONSTRAINT chk_analysis_strain CHECK (mouse_strain IN (
      'B6Brd;B6Dnk;B6N-Tyr<c-Brd>', 'C57BL/6Brd-Tyr<c-Brd>', 'C57BL/6Dnk',
      'C57BL/6JTyr;C57BL/6N', 'C57BL/6N', 'C57BL/6NCrl', 'C57BL/6NJ',
      'C57BL/6NTac', 'C57BL/6NTacDen')),
  CONSTRAINT chk_analysis_stage CHECK (mouse_life_stage IN (
      'E9.5', 'E12.5', 'E15.5', 'E18.5', 'Early adult', 'Middle aged adult', 'Late adult'))
) ENGINE = InnoDB COMMENT = 'One row per IMPC analysis (knockout gene x parameter)';

CREATE TABLE lacz_expression (
  analysis_id  VARCHAR(15)  NOT NULL,
  tissue       VARCHAR(20)  NOT NULL,
  expression   VARCHAR(25)  NOT NULL,
  PRIMARY KEY (analysis_id, tissue),
  INDEX idx_lacz_tissue_expr (tissue, expression),
  CONSTRAINT fk_lacz_analysis FOREIGN KEY (analysis_id) REFERENCES analysis (analysis_id),
  CONSTRAINT chk_lacz_tissue CHECK (tissue IN (
      'blood', 'brain', 'colon', 'eye', 'heart', 'kidney', 'liver', 'lung',
      'skeletal_muscle', 'skin', 'vascular_system')),
  CONSTRAINT chk_lacz_expression CHECK (expression IN (
      'expression', 'no expression', 'ambiguous', 'imageOnly', 'No data', 'tissue not available'))
) ENGINE = InnoDB COMMENT = 'LacZ reporter expression: one row per analysis per tissue';

CREATE TABLE parameter_variant (
  impc_parameter_orig_id  INT           NOT NULL,
  parameter_id            VARCHAR(30)   NOT NULL,
  name                    VARCHAR(150)  NOT NULL,
  description             TEXT          NULL,
  PRIMARY KEY (impc_parameter_orig_id),
  CONSTRAINT fk_variant_parameter FOREIGN KEY (parameter_id) REFERENCES parameter (parameter_id)
) ENGINE = InnoDB COMMENT = 'Every row of IMPC_parameter_description (versions of a parameter)';

CREATE TABLE parameter_group_map (
  parameter_id  VARCHAR(30)  NOT NULL,
  group_id      INT          NOT NULL,
  PRIMARY KEY (parameter_id, group_id),
  INDEX idx_pgm_group (group_id),
  CONSTRAINT fk_pgm_parameter FOREIGN KEY (parameter_id) REFERENCES parameter (parameter_id),
  CONSTRAINT fk_pgm_group     FOREIGN KEY (group_id)     REFERENCES parameter_group (group_id)
) ENGINE = InnoDB COMMENT = 'Many-to-many: a parameter can belong to several groups';

CREATE TABLE gene_disease (
  gene_disease_id  INT          NOT NULL,
  mgi_id           VARCHAR(15)  NOT NULL,
  doid             VARCHAR(20)  NOT NULL,
  PRIMARY KEY (gene_disease_id),
  UNIQUE KEY uq_gene_disease (mgi_id, doid),
  INDEX idx_gd_doid (doid),
  CONSTRAINT fk_gd_gene    FOREIGN KEY (mgi_id) REFERENCES gene (mgi_id),
  CONSTRAINT fk_gd_disease FOREIGN KEY (doid)   REFERENCES disease (doid)
) ENGINE = InnoDB COMMENT = 'Gene-disease associations';

CREATE TABLE disease_model_genotype (
  gene_disease_id  INT          NOT NULL,
  genotype_id      VARCHAR(15)  NOT NULL,
  PRIMARY KEY (gene_disease_id, genotype_id),
  CONSTRAINT fk_dmg_gene_disease FOREIGN KEY (gene_disease_id) REFERENCES gene_disease (gene_disease_id)
) ENGINE = InnoDB COMMENT = 'MGI mouse model genotypes per gene-disease pair';

CREATE TABLE homology (
  mouse_ensembl_id      VARCHAR(20)  NOT NULL,
  homolog_ensembl_id    VARCHAR(20)  NOT NULL,
  homology_type         ENUM('ortholog_one2one', 'ortholog_one2many', 'ortholog_many2many') NOT NULL,
  percent_identity      DOUBLE       NOT NULL,
  last_common_ancestor  VARCHAR(30)  NOT NULL,
  PRIMARY KEY (mouse_ensembl_id, homolog_ensembl_id),
  INDEX idx_homolog (homolog_ensembl_id),
  CONSTRAINT fk_hom_mouse   FOREIGN KEY (mouse_ensembl_id)   REFERENCES ensembl_gene (ensembl_gene_id),
  CONSTRAINT fk_hom_homolog FOREIGN KEY (homolog_ensembl_id) REFERENCES ensembl_gene (ensembl_gene_id),
  CONSTRAINT chk_hom_identity CHECK (percent_identity BETWEEN 0 AND 100)
) ENGINE = InnoDB COMMENT = 'Mouse gene -> homolog in another species';

CREATE TABLE query_gene (
  gene_symbol  VARCHAR(30)  NOT NULL,
  mgi_id       VARCHAR(15)  NOT NULL,
  PRIMARY KEY (gene_symbol),
  CONSTRAINT fk_query_gene FOREIGN KEY (mgi_id) REFERENCES gene (mgi_id)
) ENGINE = InnoDB COMMENT = 'The collaborator genes of interest';

-- =============================================================================
-- VIEWS (ready-made joins for the dashboard and the collaborator)
-- =============================================================================
CREATE VIEW v_analysis_detail AS
SELECT a.analysis_id, a.mgi_id, g.gene_symbol, a.allele_symbol,
       a.mouse_strain, a.mouse_life_stage,
       a.parameter_id, COALESCE(p.parameter_name, a.parameter_name_unlinked) AS parameter_name,
       pr.procedure_name, a.pvalue,
       -LOG10(GREATEST(a.pvalue, 1e-300)) AS neg_log10_p
FROM analysis a
JOIN gene g                 ON g.mgi_id = a.mgi_id
LEFT JOIN parameter p       ON p.parameter_id = a.parameter_id
LEFT JOIN impc_procedure pr ON pr.procedure_id = p.procedure_id;

CREATE VIEW v_parameter_groups AS
SELECT p.parameter_id, p.parameter_name,
       GROUP_CONCAT(pg.group_name ORDER BY pg.group_name SEPARATOR ', ') AS parameter_groups
FROM parameter p
JOIN parameter_group_map m ON m.parameter_id = p.parameter_id
JOIN parameter_group pg    ON pg.group_id = m.group_id
GROUP BY p.parameter_id, p.parameter_name;

CREATE VIEW v_gene_disease AS
SELECT g.mgi_id, g.gene_symbol, hg.hgnc_id, hg.human_symbol, d.doid, d.disease_name,
       COUNT(dmg.genotype_id) AS n_mouse_model_genotypes
FROM gene_disease gd
JOIN gene g                          ON g.mgi_id = gd.mgi_id
JOIN disease d                       ON d.doid = gd.doid
LEFT JOIN human_gene hg              ON hg.mgi_id = gd.mgi_id
LEFT JOIN disease_model_genotype dmg ON dmg.gene_disease_id = gd.gene_disease_id
GROUP BY g.mgi_id, g.gene_symbol, hg.hgnc_id, hg.human_symbol, d.doid, d.disease_name;

CREATE VIEW v_gene_homology AS
SELECT mg.mgi_id, mg.gene_name AS mouse_symbol, h.mouse_ensembl_id,
       sp.common_name AS species, h.homolog_ensembl_id, hg.gene_name AS homolog_symbol,
       h.homology_type, h.percent_identity, h.last_common_ancestor
FROM homology h
JOIN ensembl_gene mg ON mg.ensembl_gene_id = h.mouse_ensembl_id
JOIN ensembl_gene hg ON hg.ensembl_gene_id = h.homolog_ensembl_id
JOIN species sp      ON sp.species_id = hg.species_id;
