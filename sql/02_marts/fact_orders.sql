-- Order fact. Grain: one row per order_id.
-- Five role-playing date FKs to dim_date (purchase, approved, carrier, customer, estimated).
-- Raw DATETIME columns kept alongside FKs for hourly precision when calculating lifecycle intervals.
-- Customer identity resolved via stg_customers bridge: customer_id -> customer_unique_id -> customer_sk.
-- Degenerate dimensions (order_id, customer_id, order_status) live in the fact rather than separate dims.

CREATE TABLE olist_marts.fact_orders AS
SELECT
    ROW_NUMBER() OVER (ORDER BY o.order_purchase_timestamp, o.order_id) AS order_sk,

    -- FK to dim_customer (via bridge)
    dc.customer_sk,

    -- FK to dim_date (5 role-playing)
    CAST(DATE_FORMAT(o.order_purchase_timestamp, '%Y%m%d') AS UNSIGNED) AS purchase_date_sk,
    CASE WHEN o.order_approved_at IS NULL THEN NULL
         ELSE CAST(DATE_FORMAT(o.order_approved_at, '%Y%m%d') AS UNSIGNED) END AS approved_date_sk,
    CASE WHEN o.order_delivered_carrier_date IS NULL THEN NULL
         ELSE CAST(DATE_FORMAT(o.order_delivered_carrier_date, '%Y%m%d') AS UNSIGNED) END AS delivered_carrier_date_sk,
    CASE WHEN o.order_delivered_customer_date IS NULL THEN NULL
         ELSE CAST(DATE_FORMAT(o.order_delivered_customer_date, '%Y%m%d') AS UNSIGNED) END AS delivered_customer_date_sk,
    CAST(DATE_FORMAT(o.order_estimated_delivery_date, '%Y%m%d') AS UNSIGNED) AS estimated_delivery_date_sk,

    -- Degenerate dimensions
    o.order_id,
    o.customer_id,
    o.order_status,

    -- Raw timestamps (hourly precision for interval calculations)
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_staging.stg_orders as o
INNER JOIN olist_staging.stg_customers as c
    ON o.customer_id = c.customer_id
INNER JOIN olist_marts.dim_customer as dc
    ON c.customer_unique_id = dc.customer_unique_id;

ALTER TABLE olist_marts.fact_orders
    ADD PRIMARY KEY (order_sk);