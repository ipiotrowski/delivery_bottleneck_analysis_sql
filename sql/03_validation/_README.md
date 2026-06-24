# Validation queries

Post-build sanity checks for marts models. Run after rebuilding the warehouse to confirm models meet their grain, key uniqueness, and range expectations.

## How this works

Each file mirrors a marts model: `dim_date.sql` -> `dim_date_checks.sql`. Files contain SELECT queries with comments stating expected results. No pass/fail automation - I read the output and judge.

This is the manual equivalent of dbt's `tests:` block in schema.yml. Same intent, simpler tooling.

## What I check

- **Primary key uniqueness:** `COUNT(*) = COUNT(DISTINCT pk)`
- **Grain integrity:** row count matches expected entity count from staging
- **Range sanity:** min/max values within expected bounds
- **Null handling:** NOT NULL columns have no nulls, nullable columns have nulls where expected
- **Referential integrity:** facts join cleanly to dims, no orphan FKs

## When to run

After every rebuild of the corresponding marts model. If a check fails, fix the model before moving to the next layer.

## File naming

`<model_name>_checks.sql`. Underscore prefix reserved for non-model reference files (this readme).