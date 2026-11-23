# impc_group10 – MySQL database (Group 10, 7BBG1003)

Builds the normalised MySQL database from the cleaned CSVs in `db_tables/`
(output of the cleaning scripts and `CW2_impc_split.qmd`).

## Files

| File | What it does |
|---|---|
| `schema.sql` | Creates the database `impc_group10`: 16 tables (primary keys, foreign keys, CHECK constraints, indexes) and 4 helper views |
| `load.sql` | Loads the 16 CSVs from `db_tables/` into the tables, parents first, with foreign-key checks on |
| `queries.sql` | Answers the collaborator's questions for the 5 genes of interest (Cep83, Rimoc1, Aqp11, Itga8, Ppm1m); creates 8 named views `q1_…` to `q8_…` |
| `impc_group10_schema.png` / `.svg` | Database schema diagram (ER diagram) for the report |

## How to run (in this order)

Requirements: MySQL 8.0.16+, and the `db_tables/` folder (16 CSVs) next to these files.

**Terminal**
```bash
cd <folder containing db_tables/ and these .sql files>
mysql -u root -p < schema.sql
mysql --local-infile=1 -u root -p < load.sql
mysql -u root -p < queries.sql
```

**DBeaver**
1. Connection → Edit Connection → Driver properties → set `allowLoadLocalInfile` = **true**.
2. In `load.sql`, replace `'db_tables/` with the full path to your folder,
   e.g. `'/Users/<you>/Documents/Group10.1/db_tables/` (DBeaver needs absolute paths).
3. Open each script, attach it to your connection, and run it as a script (Alt/Option+X):
   `schema.sql` → `load.sql` → `queries.sql`.

## Checks built in

- `load.sql` ends with a row-count table: `n_rows` must equal `expected` for all 16 tables
  (e.g. analysis 28,424; lacz_expression 309,504), and a NULL check (0 text "NA", 169 real NULLs).
- Foreign key checks stay on during loading, so MySQL rejects any row that does not link up.

## Notes

- The procedures table is called **`impc_procedure`** (`procedure` is a reserved word in MySQL) – use this name in RShiny queries.
- `load.sql` starts with `SET GLOBAL local_infile = 1;` – this resets whenever MySQL restarts.
- `NA` in the CSVs is loaded as real `NULL`; `TRUE`/`FALSE` become 1/0.
- Significance threshold for the queries is `@alpha = 0.05` (set once in `queries.sql`; `q8_gene_summary` is fixed at 0.05).
- Each query in `queries.sql` has a `-- title:` comment, so DBeaver names its result tab (Q1 gene overview, Q2 all results, …).
- Still to add to the repo: the dump file `impc_group10_dump.sql` (DBeaver: right-click `impc_group10` → Tools → Dump database).
- Do not commit any file containing a MySQL password.
