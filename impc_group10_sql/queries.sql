-- =============================================================================
-- queries.sql  -  the collaborator's questions for the Group 10 genes of interest
--   Cep83, Rimoc1, Aqp11, Itga8, Ppm1m   (stored in the query_gene table)
--
-- Database: impc_group10 (run schema.sql and load.sql first)
-- Run in DBeaver: attach to the connection, Execute SQL Script (Alt/Option+X).
--
-- Part A creates one named VIEW per question. Part B reads each view.
-- Each query in Part B has a '-- title:' comment, which DBeaver uses as the
-- name of its result tab (Q1 gene overview, Q2 all results, ...).
-- The views can be re-used by the collaborator and by the RShiny app.
--
-- Significance threshold: set once in @alpha (Part B). The views hold every
-- p-value, so changing @alpha changes all answers except q8 (fixed at 0.05,
-- because MySQL views cannot use variables).
-- =============================================================================
USE impc_group10;

-- =============================================================================
-- PART A - one view per collaborator question
-- =============================================================================

-- Q1 base: every analysis of every gene of interest
CREATE OR REPLACE VIEW q1_gene_overview AS
SELECT q.gene_symbol, q.mgi_id, a.analysis_id, a.parameter_id, a.pvalue
FROM query_gene q
LEFT JOIN analysis a ON a.mgi_id = q.mgi_id;

-- Q2: ALL information per analysis - parameter, parameter group(s), procedure,
--     p-value, allele, strain, life stage, and whether the gene has a disease link
CREATE OR REPLACE VIEW q2_all_results AS
SELECT v.gene_symbol,
       v.allele_symbol,
       v.mouse_strain,
       v.mouse_life_stage,
       v.parameter_id,
       v.parameter_name,
       pg.parameter_groups,
       v.procedure_name,
       v.pvalue,
       EXISTS (SELECT 1 FROM gene_disease gd WHERE gd.mgi_id = v.mgi_id) AS linked_to_disease
FROM v_analysis_detail v
JOIN query_gene q               ON q.mgi_id = v.mgi_id
LEFT JOIN v_parameter_groups pg ON pg.parameter_id = v.parameter_id;

-- Q3: same information, used for the significant phenotypes only (filtered in Part B)
CREATE OR REPLACE VIEW q3_significant_phenotypes AS
SELECT gene_symbol, parameter_name, parameter_groups, procedure_name,
       mouse_life_stage, pvalue
FROM q2_all_results;

-- Q4 base: each analysis of a gene of interest with each group its parameter belongs to
CREATE OR REPLACE VIEW q4_affected_body_systems AS
SELECT q.gene_symbol, g.group_name, a.pvalue
FROM query_gene q
JOIN analysis a             ON a.mgi_id = q.mgi_id
JOIN parameter_group_map m  ON m.parameter_id = a.parameter_id
JOIN parameter_group g      ON g.group_id = m.group_id;

-- Q5: human disease associations (Disease Ontology) + number of MGI mouse models
CREATE OR REPLACE VIEW q5_disease_links AS
SELECT q.gene_symbol, d.human_symbol, d.hgnc_id, d.doid, d.disease_name,
       d.n_mouse_model_genotypes
FROM query_gene q
LEFT JOIN v_gene_disease d ON d.mgi_id = q.mgi_id;

-- Q6: bespoke task - homologs in human and macaque
CREATE OR REPLACE VIEW q6_homologs AS
SELECT q.gene_symbol, h.mouse_ensembl_id, h.species, h.homolog_ensembl_id,
       h.homolog_symbol, h.homology_type, h.percent_identity, h.last_common_ancestor
FROM query_gene q
LEFT JOIN v_gene_homology h ON h.mgi_id = q.mgi_id;

-- Q7 base: LacZ reporter result of every analysis, per tissue
CREATE OR REPLACE VIEW q7_lacz_expression AS
SELECT q.gene_symbol, l.tissue, l.expression
FROM query_gene q
JOIN analysis a         ON a.mgi_id = q.mgi_id
JOIN lacz_expression l  ON l.analysis_id = a.analysis_id;

-- Q8: one-line summary per gene (significance fixed at p < 0.05)
CREATE OR REPLACE VIEW q8_gene_summary AS
SELECT q.gene_symbol,
       (SELECT COUNT(*) FROM analysis a
         WHERE a.mgi_id = q.mgi_id AND a.pvalue < 0.05)                AS n_significant,
       (SELECT GROUP_CONCAT(DISTINCT g.group_name ORDER BY g.group_name SEPARATOR ', ')
          FROM analysis a
          JOIN parameter_group_map m ON m.parameter_id = a.parameter_id
          JOIN parameter_group g     ON g.group_id = m.group_id
         WHERE a.mgi_id = q.mgi_id AND a.pvalue < 0.05)                AS affected_body_systems,
       (SELECT GROUP_CONCAT(d.disease_name ORDER BY d.disease_name SEPARATOR '; ')
          FROM gene_disease gd JOIN disease d ON d.doid = gd.doid
         WHERE gd.mgi_id = q.mgi_id)                                   AS diseases,
       (SELECT GROUP_CONCAT(CONCAT(h.species, ' ', h.homolog_symbol, ' (',
                                   ROUND(h.percent_identity, 1), '%)')
                            ORDER BY h.species SEPARATOR ', ')
          FROM v_gene_homology h WHERE h.mgi_id = q.mgi_id)            AS homologs
FROM query_gene q;

-- =============================================================================
-- PART B - the answers (one result tab each, named after the view)
-- =============================================================================
SET @alpha = 0.05;

-- Q1. How many analyses per gene, and how many reach significance?
-- title: Q1 gene overview
SELECT gene_symbol,
       mgi_id,
       COUNT(analysis_id)            AS n_analyses,
       COUNT(DISTINCT parameter_id)  AS n_parameters_tested,
       SUM(pvalue < @alpha)          AS n_significant,
       MIN(pvalue)                   AS best_pvalue
FROM q1_gene_overview
GROUP BY gene_symbol, mgi_id
ORDER BY gene_symbol;

-- Q2. All information for every analysis of the genes of interest
-- title: Q2 all results
SELECT q2_all_results.*, (pvalue < @alpha) AS is_significant
FROM q2_all_results
ORDER BY gene_symbol, pvalue;

-- Q3. Significant phenotypes only, strongest first
-- title: Q3 significant phenotypes
SELECT *
FROM q3_significant_phenotypes
WHERE pvalue < @alpha
ORDER BY gene_symbol, pvalue;

-- Q4. Which parameter groups (body systems) are affected for each gene?
-- title: Q4 affected body systems
SELECT gene_symbol,
       group_name,
       COUNT(*)     AS n_significant,
       MIN(pvalue)  AS best_pvalue
FROM q4_affected_body_systems
WHERE pvalue < @alpha
GROUP BY gene_symbol, group_name
ORDER BY gene_symbol, n_significant DESC, best_pvalue;

-- Q5. Which human diseases is each gene linked to?
-- title: Q5 disease links
SELECT *
FROM q5_disease_links
ORDER BY gene_symbol, disease_name;

-- Q6. Bespoke task: what are each gene's human and macaque homologs?
-- title: Q6 homologs (bespoke)
SELECT *
FROM q6_homologs
ORDER BY gene_symbol, species;

-- Q7. LacZ: in which tissues is each gene expressed?
--     ('No data' and 'tissue not available' are left out)
-- title: Q7 LacZ expression
SELECT gene_symbol,
       tissue,
       expression,
       COUNT(*) AS n_analyses
FROM q7_lacz_expression
WHERE expression IN ('expression', 'no expression', 'ambiguous')
GROUP BY gene_symbol, tissue, expression
ORDER BY gene_symbol, tissue, n_analyses DESC;

-- Q8. One-line summary per gene (for the report)
-- title: Q8 gene summary
SELECT *
FROM q8_gene_summary
ORDER BY gene_symbol;
