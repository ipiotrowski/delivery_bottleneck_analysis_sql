-- Sanity checks for fact_order_items.
-- Expected: row_count = distinct order_item_sk (PK uniqueness).
--           row_count matches stg_order_items (INNER JOINs should not drop any items).
--           distinct order_id in fact_order_items <= distinct order_id in fact_orders (subset).
--           no NULLs anywhere (all FK and degenerate dims required).
--           FK integrity to fact_orders, dim_seller, dim_product, dim_date all clean.

-- PK uniqueness.
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_item_sk) AS distinct_sk
FROM olist_marts.fact_order_items;

-- Row count match with source.
-- Expected: source_items = marts_items, diff = 0.
SELECT
    (SELECT COUNT(*) FROM olist_staging.stg_order_items) AS source_items,
    (SELECT COUNT(*) FROM olist_marts.fact_order_items) AS marts_items,
    (SELECT COUNT(*) FROM olist_staging.stg_order_items)
        - (SELECT COUNT(*) FROM olist_marts.fact_order_items) AS diff;

-- Composite grain uniqueness: order_id + order_item_id should be unique.
-- Expected: composite_count = row_count.
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS composite_count
FROM olist_marts.fact_order_items;

-- Null checks on all NOT NULL columns.
-- Expected: all zeros.
SELECT
    SUM(order_item_sk IS NULL) AS null_sk,
    SUM(order_sk IS NULL) AS null_order_sk,
    SUM(seller_sk IS NULL) AS null_seller_sk,
    SUM(product_sk IS NULL) AS null_product_sk,
    SUM(shipping_limit_date_sk IS NULL) AS null_ship_date_sk,
    SUM(order_id IS NULL) AS null_order_id,
    SUM(order_item_id IS NULL) AS null_order_item_id,
    SUM(shipping_limit_date IS NULL) AS null_ship_date_ts,
    SUM(price IS NULL) AS null_price,
    SUM(freight_value IS NULL) AS null_freight
FROM olist_marts.fact_order_items;

-- FK integrity: every order_sk must exist in fact_orders.
-- Expected: orphan_count = 0.
SELECT COUNT(*) AS orphan_order_sk
FROM olist_marts.fact_order_items foi
LEFT JOIN olist_marts.fact_orders fo ON foi.order_sk = fo.order_sk
WHERE fo.order_sk IS NULL;

-- FK integrity: every seller_sk must exist in dim_seller.
-- Expected: orphan_count = 0.
SELECT COUNT(*) AS orphan_seller_sk
FROM olist_marts.fact_order_items foi
LEFT JOIN olist_marts.dim_seller ds ON foi.seller_sk = ds.seller_sk
WHERE ds.seller_sk IS NULL;

-- FK integrity: every product_sk must exist in dim_product.
-- Expected: orphan_count = 0.
SELECT COUNT(*) AS orphan_product_sk
FROM olist_marts.fact_order_items foi
LEFT JOIN olist_marts.dim_product dp ON foi.product_sk = dp.product_sk
WHERE dp.product_sk IS NULL;

-- FK integrity: every shipping_limit_date_sk must exist in dim_date.
-- Expected: orphan_count = 0.
SELECT COUNT(*) AS orphan_ship_date
FROM olist_marts.fact_order_items foi
LEFT JOIN olist_marts.dim_date d ON foi.shipping_limit_date_sk = d.date_sk
WHERE d.date_sk IS NULL;

-- Deep down
SELECT 
    foi.order_id,
    foi.order_item_id,
    foi.shipping_limit_date,
    foi.shipping_limit_date_sk
FROM olist_marts.fact_order_items foi
LEFT JOIN olist_marts.dim_date d ON foi.shipping_limit_date_sk = d.date_sk
WHERE d.date_sk IS NULL;

-- Reasonableness check on measures.
-- Expected: min >= 0 for both, max within sane range.
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight,
    AVG(freight_value) AS avg_freight
FROM olist_marts.fact_order_items;