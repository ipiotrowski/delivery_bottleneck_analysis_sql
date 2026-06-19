-- Staging model for order items: cast types, parse dates, add load timestamp, set composite PK.
-- Note: no NULLIF guards because profiling confirmed zero NULLs and empty strings.

CREATE TABLE olist_staging.stg_order_items AS
SELECT
    CAST(order_id AS CHAR(32)) AS order_id,
    CAST(order_item_id AS SIGNED) AS order_item_id,
    CAST(product_id AS CHAR(32)) AS product_id,
    CAST(seller_id AS CHAR(32)) AS seller_id,
    CAST(shipping_limit_date AS DATETIME) AS shipping_limit_date,
    CAST(price AS DECIMAL(10,2)) AS price,
    CAST(freight_value AS DECIMAL(10,2)) AS freight_value,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_raw.order_items;

ALTER TABLE olist_staging.stg_order_items
    ADD PRIMARY KEY (order_id, order_item_id);