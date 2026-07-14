-- Order items fact. Grain: one row per order_id + order_item_id (composite natural key).
-- Header/lines pattern: FK to fact_orders (order_sk) connects each item to its parent order.
-- shipping_limit_date kept as both FK to dim_date and raw DATETIME (hybrid, consistent with fact_orders).
-- INNER JOIN to fact_orders enforces referential integrity at build time.

CREATE TABLE olist_marts.fact_order_items AS
SELECT
    ROW_NUMBER() OVER (ORDER BY oi.order_id, oi.order_item_id) AS order_item_sk,

    -- FK to other marts tables
    fo.order_sk,
    ds.seller_sk,
    dp.product_sk,
    CAST(DATE_FORMAT(oi.shipping_limit_date, '%Y%m%d') AS UNSIGNED) AS shipping_limit_date_sk,

    -- Degenerate dimensions
    oi.order_id,
    oi.order_item_id,

    -- Raw timestamp (hourly precision)
    oi.shipping_limit_date,

    -- Measures
    oi.price,
    oi.freight_value,

    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_staging.stg_order_items as oi
INNER JOIN olist_marts.fact_orders as fo
    ON oi.order_id = fo.order_id
INNER JOIN olist_marts.dim_seller as ds
    ON oi.seller_id = ds.seller_id
INNER JOIN olist_marts.dim_product as dp
    ON oi.product_id = dp.product_id;

ALTER TABLE olist_marts.fact_order_items
    ADD PRIMARY KEY (order_item_sk);