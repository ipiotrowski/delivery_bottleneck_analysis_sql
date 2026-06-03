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
- [ ] Phase 1: Staging (in progress, 4 of 6 tables built)
- [ ] Phase 2: Marts
- [ ] Phase 3: Analytical queries
- [ ] Phase 4: Documentation
