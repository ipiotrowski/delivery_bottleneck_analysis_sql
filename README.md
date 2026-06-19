# delivery_bottleneck_analysis_sql

A SQL-based rebuild of the [delivery_bottleneck_analysis](https://github.com/ipiotrowski/delivery_bottleneck_analysis) project, originally built in Power BI. Same dataset, different stack.

## What this project does

Breaks the Olist e-commerce delivery process into fulfillment stages and identifies where delays come from: seller-driven, product-related, or systemic logistics.

The Power BI version answered these questions inside DAX measures and Power Query steps. This version moves that logic into SQL, where it belongs in an analytics engineering setup.

## Stack

MySQL Workbench 8.0 CE. Dataset: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

## Architecture

```
olist_raw      -> direct CSV ingestion. Everything as VARCHAR.
olist_staging  -> typed, deduplicated, cleaned.
olist_marts    -> star schema. Ready for analytical queries.
```

## Analytical questions

1. Seller lead-time percentile distribution (P50/P75/P90/P99)
2. Customer cohort retention by first-purchase month
3. Rolling 7-day and 30-day delivery performance trends
4. Sequence gap analysis: where in the order lifecycle do delays accumulate
5. Seller ramp-up: first 90 days vs mature performance
6. Top-N sellers by category using RANK vs DENSE_RANK vs ROW_NUMBER
7. Stage attribution: which fulfillment stage tips an order into "late"

## Status

- [x] Phase 0: Setup
- [x] Phase 1: Staging
- [ ] Phase 2: Marts
- [ ] Phase 3: Analytical queries
- [ ] Phase 4: Documentation

## Design decisions

### Why 6 staging tables out of 9 raw tables

Raw loads all 9 CSVs to mirror the source. Staging includes only the 6 tables required by the analytical questions: `orders`, `order_items`, `sellers`, `customers`, `products`, `product_category_translation`. Skipped: `geolocation`, `order_payments`, `order_reviews`.

Raw is a fidelity layer (cheap to keep, hard to rebuild). Staging pays the cost of typing and cleaning, so we don't pay it for data we won't use.

### Layered architecture (raw → staging → marts)

Same logical layers as the Power BI version, materialized in the database instead of Power Query. Each layer has one job:
- raw: faithful ingestion, no business logic
- staging: types, cleaning, deduplication
- marts: star schema, surrogate keys, business logic

### CTAS instead of explicit DDL

Used `CREATE TABLE ... AS SELECT` instead of `CREATE TABLE` followed by `INSERT`. CTAS is the analytics engineering convention and mirrors how dbt models work: SELECT-first, types inferred from the casts in the SELECT.

### Three schemas instead of prefixed table names

`olist_raw.customers` rather than `raw_customers` in a single schema. Cleaner separation, easier permission grants per layer, closer to how production data warehouses are organized.

### NULL handling

NULL means "we don't know." Zero or empty string would create false measurements (e.g. AVG of weights skewed by zero-fill). NULL is preserved everywhere except where it would break a downstream join. Categories get `'unclassified'` because the marts layer needs to join on category name.

Empty-string normalization (via `CASE WHEN`) is applied only where profiling confirmed empty strings in the source. dbt convention is defensive-by-default with safe_cast macros; raw MySQL CTAS under STRICT mode makes blanket defensive coding risky (see quirks below), so we narrowed the rule to "guard where profile says you need to."

### NOT NULL constraints

Applied only where `COALESCE` guarantees a non-null value (e.g. `product_category_name` after `'unclassified'` labeling). Documents the invariant and turns the constraint into a runtime assertion: if it ever fails, MySQL throws.

### dwh_loaded_at column on every staging table

Records when each staging table was built. Standard lineage column for tracking refresh times.

### Surrogate keys live in marts, not staging

Staging keeps original Olist hash IDs so any row reconciles back to source with no lookups. Surrogate keys (sequential or hashed) get added in marts where they support star schema joins and slowly-changing dimensions. Kimball convention.

## MySQL quirks we learned

1. **`CAST AS VARCHAR` doesn't exist.** MySQL accepts only `CHAR`, `SIGNED`, `UNSIGNED`, `DATETIME`, `DECIMAL`, `BINARY`, `JSON` as CAST targets. Workaround: CAST as CHAR in the SELECT, then `ALTER TABLE MODIFY COLUMN col VARCHAR(N)` afterward.

2. **`CAST AS INT` doesn't exist either.** Use `SIGNED` or `UNSIGNED` for integers. MySQL materializes these as BIGINT.

3. **CTAS materializes CHAR casts as VARCHAR.** Even `CAST(x AS CHAR(32))` ends up as `VARCHAR(32)` in the resulting table. Functionally identical for fixed-length strings; an idiom to be aware of.

4. **`NULLIF` inside `CAST` inside `CTAS` errors out under STRICT mode.** Triggers spurious errors like "Truncated incorrect INTEGER value: '2017-09-19 09:45:35'" that have nothing to do with the actual problem. Workaround: use `CASE WHEN x = '' THEN NULL ELSE x END`. This is why our defensive NULL handling is conditional rather than blanket.

5. **Profiling must separate NULLs from empty strings.** They're different values with different handling. `IS NULL OR = ''` checks treat them as one and hide the empty-string problem until a CAST fails downstream.