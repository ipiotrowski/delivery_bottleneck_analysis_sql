# delivery_bottleneck_analysis_sql

Analytics engineering project on the Brazilian e-commerce dataset. Star schema, seven analytical questions, business narrative for each finding.

## What this shows

- **Dimensional modeling (Kimball):** four dimensions, two facts, degenerate dimensions, bridge resolution for customer identity
- **Advanced window functions:** PERCENT_RANK, ROW_NUMBER, RANK, DENSE_RANK, rolling frames with RANGE INTERVAL
- **Layered warehouse architecture:** raw → staging → marts, each with a distinct responsibility
- **Post-build validation:** per-model sanity checks (dbt tests equivalent in raw SQL)
- **Real performance debugging:** index strategy, EXPLAIN analysis, timeout recovery
- **Business narrative:** each analysis paired with a written interpretation of what the numbers mean

## Domain and scale

Breaks the Olist e-commerce delivery process into fulfillment stages and identifies where delays come from: seller-driven, product-related, or systemic logistics.

Dataset scale:

- ~99,000 orders across ~112,000 order items
- ~96,000 unique customers, ~3,000 sellers
- 73 product categories
- Delivery window: September 2016 to August 2018

## Stack

MySQL Workbench 8.0 CE. Dataset: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).

Chose MySQL to build the warehouse patterns from scratch without hiding them behind a framework. The same architecture is meant to migrate to dbt + BigQuery next (see "What's next" at the end).

## Repository structure
sql/
├── 00_setup/           schemas, raw tables, CSV loading

├── 01_staging/         staging models + _indexes.sql

├── 02_marts/           4 dims + 2 facts + _indexes.sql

├── 03_validation/      per-model sanity checks

└── 04_analysis/        seven analytical questions + findings narrative

Execution order: setup → staging models → staging indexes → dims → marts indexes → facts → validation → analysis.

Indexes live in separate files because they span tables and must exist before downstream CTAS joins run. Underscore prefix marks non-model utilities.

## Analytical questions

1. **Seller lead-time percentile distribution (P50/P75/P90/P99)** — averages hide long tails; percentiles show which sellers are consistent and which have unreliable outliers.
2. **Customer cohort retention by first-purchase month** — separates real growth (returning customers) from churn masked by new acquisition.
3. **Rolling 7-day and 30-day delivery performance trends** — surfaces operational shocks and structural trends that calendar-month aggregates would smooth away.
4. **Sequence gap analysis: where in the order lifecycle do delays accumulate** — structural diagnosis of which stage drives variance across all orders.
5. **Geographic analysis: delivery time impact of customer-seller distance and inter-state routes** — identifies underserved regions where a new warehouse or partner could cut average delivery time.
6. **Top-N sellers by category using RANK vs DENSE_RANK vs ROW_NUMBER** — exposes category concentration and demonstrates window function tradeoffs for ranking.
7. **Stage attribution: which fulfillment stage tips an order into "late"** — assigns responsibility for individual late deliveries, the basis for SLA enforcement and partner accountability.

## Key findings

Every analysis is documented with a written interpretation in [04_analysis/_findings.md](sql/04_analysis/_findings.md). Short teasers below.

1. **Seller lead-time percentiles** — a 22x median lead-time gap between sellers hides two different patterns: structurally slow vs fast with rare disasters. Each needs a different operational response.
2. **Customer cohort retention** — every cohort behaves the same way: under 1% return in the following month. Olist grew 10x in 2017 through acquisition alone, not retention.
3. **Rolling delivery trends** — delivery time isn't flat. It swings from 12 days in 2017 to a 17-day slump in Q1 2018, then recovers to 8 days by summer.
4. **Sequence gap analysis** — 80% of delivery time happens between carrier pickup and customer delivery. Seller and payment stages are noise by comparison.
5. **Geographic analysis** — cross-state orders take 1.5x to 3x longer than same-state ones, with SP absorbing a third of all shipments. Northern states like Amazonas wait 25 days on average but represent a tiny volume slice.
6. **Top sellers by category** — ROW_NUMBER, RANK, and DENSE_RANK produce three different "top 5" lists on the same data. The one you pick depends on how you handle ties.
7. **Stage attribution** — 83% of late orders trace back to the carrier stage, adding 25 days on average. Seller performance matters, but it's not the main lever.

## Architecture decisions

### Two facts: header and lines

`fct_orders` is one row per order, `fct_order_items` is one row per line. Two grains, two tables, reconcilable through `order_sk`. Single-fact approach blurs grain in analytical queries — a customer with 3 items in one order would count 3 times in cohort analysis.

### Customer dimension at customer_unique_id grain

Olist has two customer identifiers: `customer_id` (per-order instance) and `customer_unique_id` (the person). `dim_customer` is built at `customer_unique_id` grain so it represents people, not order instances.

Resolution path runs through `stg_customer` as a bridge: `stg_orders.customer_id → stg_customer → dim_customer.customer_sk`. Resolved once during fact build, never again in analytical queries.

### Hybrid timestamps in facts

Facts carry both `*_date_sk` (FK to `dim_date`) and raw DATETIME for every lifecycle stage. FK for date-based grouping and filtering, raw timestamp for `TIMESTAMPDIFF` on hourly intervals. No `dim_time` because daily grain covers all analytical questions; hourly precision is preserved in raw columns when needed.

### Sequential surrogate keys

`ROW_NUMBER() OVER (ORDER BY natural_key)` gives sequential BIGINT for each dimension. Sequential over hashed because this is a batch-rebuilt portfolio project with one environment. Hashed keys are the right pattern for production warehouses with incremental loads across environments.

### date_sk as YYYYMMDD integer

Format `20170919` for 2017-09-19. Sortable, human-readable, lets analytical queries filter ranges without joining `dim_date`:

```sql
WHERE purchase_date_sk BETWEEN 20170101 AND 20171231
```

## Conventions

**Layered architecture (raw → staging → marts):**
- raw: faithful ingestion, no business logic
- staging: types, cleaning, deduplication
- marts: star schema, surrogate keys, business logic

**CTAS instead of explicit DDL.** `CREATE TABLE ... AS SELECT` mirrors how dbt models work.

**Three schemas, not prefixed tables.** `olist_raw.customers` rather than `raw_customers` in one schema. Closer to how production warehouses organize permissions.

**NULL means "unknown."** Preserved everywhere except where it would break a downstream join. Categories get `'unclassified'` because the marts layer needs to join on category name.

**NOT NULL constraints as runtime assertions.** Applied only where `COALESCE` guarantees a non-null value. If the assumption breaks, MySQL throws.

**`dwh_loaded_at` column on every marts and staging table.** Standard lineage column for tracking refresh times.

**Surrogate keys live in marts, not staging.** Staging keeps Olist hash IDs so any row reconciles back to source. Surrogate keys get added in marts. Kimball convention.

## Data validation

`03_validation/` holds per-model `*_checks.sql` files with SELECT queries and expected results in comments. No pass/fail automation — read the output, judge.

This is the manual equivalent of dbt's `tests:` block in schema.yml. Same intent, simpler tooling.

Each check covers:
- Grain integrity and primary key uniqueness
- Row count reconciliation with source
- Null patterns on NOT NULL columns
- Foreign key integrity across marts tables

## Olist data quirks

**`shipping_limit_date` outliers reach 2020** even though the latest order is from 2018. `dim_date` range is generated from MIN/MAX across all warehouse timestamps (order lifecycle plus shipping limits) to prevent FK orphans in `fact_order_items`.

**`customer_id` is per-order, not per-person.** A returning customer gets a new `customer_id` for every order. The real identity is `customer_unique_id`. Easy to miss; affects any analysis grouping by "customer."

## MySQL lessons learned

Real problems I hit and how I worked around them.

1. **`CAST AS VARCHAR` doesn't exist.** MySQL accepts only `CHAR`, `SIGNED`, `UNSIGNED`, `DATETIME`, `DECIMAL`, `BINARY`, `JSON` as CAST targets. Workaround: CAST as CHAR in the SELECT, then `ALTER TABLE MODIFY COLUMN col VARCHAR(N)` afterward.

2. **`CAST AS INT` doesn't exist either.** Use `SIGNED` or `UNSIGNED`. MySQL materializes these as BIGINT.

3. **CTAS materializes CHAR casts as VARCHAR.** Even `CAST(x AS CHAR(32))` ends up as `VARCHAR(32)` in the resulting table. Functionally identical for fixed-length strings; an idiom to know.

4. **`NULLIF` inside `CAST` inside `CTAS` errors out under STRICT mode.** Triggers spurious errors like "Truncated incorrect INTEGER value" that have nothing to do with the actual problem. Workaround: `CASE WHEN x = '' THEN NULL ELSE x END`.

5. **Profiling must separate NULLs from empty strings.** They're different values with different handling. `IS NULL OR = ''` treats them as one and hides the empty-string problem until a CAST fails downstream.

6. **Recursive CTEs need `cte_max_recursion_depth` raised.** Default is 1000, which fails on date dimensions covering more than 1000 days. Run `SET SESSION cte_max_recursion_depth = 10000;` first.

7. **Workbench timeouts don't kill server-side queries.** Timed-out queries keep running on the server, pile up as zombie processes, and lock tables. Always `SHOW PROCESSLIST` and `KILL` before retrying.

8. **Joins on unindexed VARCHAR columns degrade to full table scans.** PRIMARY KEY on natural ID doesn't help when joining on a different column. CTAS in marts hangs on ~100k × 100k joins without indexes. `EXPLAIN` shows `type: ALL` when this happens.

## What's next

- Migrate the warehouse to **dbt + BigQuery**. Same models, same tests, running on modern stack. This project is deliberately built with dbt patterns in mind (CTAS models, ref-style dependencies, tests as separate files) to make the port straightforward.
- Add **incremental load logic** for facts, replacing full rebuilds. Requires shifting from sequential to hashed surrogate keys.
- Explore **semantic layer** representation (dbt Semantic Layer or LookML) on top of the marts.
