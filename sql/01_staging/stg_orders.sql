-- Staging model for orders: cast types, parse 5 lifecycle timestamps, add load timestamp, set PK.
-- Note: approved, carrier, and delivered timestamps contain empty strings for orders that didn't reach that lifecycle stage. CASE WHEN normalizes empty to NULL before CAST (NULLIF triggers MySQL CTAS quirks).

CREATE TABLE olist_staging.stg_orders AS
SELECT
    CAST(order_id AS CHAR(32)) AS order_id,
    CAST(customer_id AS CHAR(32)) AS customer_id,
    TRIM(order_status) AS order_status,
    CAST(order_purchase_timestamp AS DATETIME) AS order_purchase_timestamp,
    CAST(CASE WHEN order_approved_at = '' THEN NULL ELSE order_approved_at END AS DATETIME) AS order_approved_at,
    CAST(CASE WHEN order_delivered_carrier_date = '' THEN NULL ELSE order_delivered_carrier_date END AS DATETIME) AS order_delivered_carrier_date,
    CAST(CASE WHEN order_delivered_customer_date = '' THEN NULL ELSE order_delivered_customer_date END AS DATETIME) AS order_delivered_customer_date,
    CAST(order_estimated_delivery_date AS DATETIME) AS order_estimated_delivery_date,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_raw.orders;

ALTER TABLE olist_staging.stg_orders
    MODIFY COLUMN order_status VARCHAR(16) NOT NULL,
    ADD PRIMARY KEY (order_id);