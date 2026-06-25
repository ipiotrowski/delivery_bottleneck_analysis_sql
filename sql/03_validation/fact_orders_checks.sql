-- Sanity checks for fact_orders.
-- Expected: row_count = distinct order_sk = distinct order_id (grain).
--           row_count matches stg_orders (no rows dropped by bridge joins).
--           customer_sk never null (INNER JOIN to dim_customer).
--           purchase_date_sk and estimated_delivery_date_sk never null.
--           approved/carrier/customer date FKs nullable, counts should match raw timestamp nulls.

-- Grain and PK uniqueness.
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_sk) AS distinct_sk,
    COUNT(DISTINCT order_id) AS distinct_natural_key
FROM olist_marts.fact_orders;

-- Row count match with source (bridge INNER JOIN should not drop).
-- Expected: source_orders = marts_orders, diff = 0.
SELECT
    (SELECT COUNT(*) FROM olist_staging.stg_orders) AS source_orders,
    (SELECT COUNT(*) FROM olist_marts.fact_orders) AS marts_orders,
    (SELECT COUNT(*) FROM olist_staging.stg_orders)
        - (SELECT COUNT(*) FROM olist_marts.fact_orders) AS diff;

-- Null checks on NOT NULL columns.
-- Expected: all zeros.
SELECT
    SUM(order_sk IS NULL) AS null_order_sk,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(customer_sk IS NULL) AS null_customer_sk,
    SUM(order_status IS NULL) AS null_order_status,
    SUM(purchase_date_sk IS NULL) AS null_purchase_date_sk,
    SUM(estimated_delivery_date_sk IS NULL) AS null_estimated_date_sk,
    SUM(order_purchase_timestamp IS NULL) AS null_purchase_ts,
    SUM(order_estimated_delivery_date IS NULL) AS null_estimated_ts
FROM olist_marts.fact_orders;

-- Null consistency between date_sk and raw timestamp (should match for nullable lifecycle stages).
-- Expected: each pair returns equal counts.
SELECT
    SUM(approved_date_sk IS NULL) AS null_approved_sk,
    SUM(order_approved_at IS NULL) AS null_approved_ts,
    SUM(delivered_carrier_date_sk IS NULL) AS null_carrier_sk,
    SUM(order_delivered_carrier_date IS NULL) AS null_carrier_ts,
    SUM(delivered_customer_date_sk IS NULL) AS null_customer_sk_date,
    SUM(order_delivered_customer_date IS NULL) AS null_customer_ts
FROM olist_marts.fact_orders;

-- FK integrity: every customer_sk must exist in dim_customer.
-- Expected: orphan_count = 0.
SELECT COUNT(*) AS orphan_count
FROM olist_marts.fact_orders as f
LEFT JOIN olist_marts.dim_customer as dc ON f.customer_sk = dc.customer_sk
WHERE dc.customer_sk IS NULL;

-- FK integrity: every non-null date_sk must exist in dim_date.
-- Expected: all five queries return 0.
SELECT COUNT(*) AS orphan_purchase_date
FROM olist_marts.fact_orders as f
LEFT JOIN olist_marts.dim_date as d ON f.purchase_date_sk = d.date_sk
WHERE d.date_sk IS NULL;

SELECT COUNT(*) AS orphan_estimated_date
FROM olist_marts.fact_orders as f
LEFT JOIN olist_marts.dim_date as d ON f.estimated_delivery_date_sk = d.date_sk
WHERE d.date_sk IS NULL;

SELECT COUNT(*) AS orphan_approved_date
FROM olist_marts.fact_orders as f
LEFT JOIN olist_marts.dim_date as d ON f.approved_date_sk = d.date_sk
WHERE f.approved_date_sk IS NOT NULL AND d.date_sk IS NULL;

SELECT COUNT(*) AS orphan_carrier_date
FROM olist_marts.fact_orders as f
LEFT JOIN olist_marts.dim_date as d ON f.delivered_carrier_date_sk = d.date_sk
WHERE f.delivered_carrier_date_sk IS NOT NULL AND d.date_sk IS NULL;

SELECT COUNT(*) AS orphan_customer_date
FROM olist_marts.fact_orders as f
LEFT JOIN olist_marts.dim_date as d ON f.delivered_customer_date_sk = d.date_sk
WHERE f.delivered_customer_date_sk IS NOT NULL AND d.date_sk IS NULL;