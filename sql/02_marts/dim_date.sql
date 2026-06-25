-- Date dimension. Grain: one row per day.
-- Range: 30 days padding around MIN/MAX of all timestamps in warehouse (order lifecycle + shipping limits).
-- Initial version used only order timestamps; extended to cover shipping_limit_date outliers reaching 2020.
-- day_of_week follows ISO 8601 (1=Monday, 7=Sunday). Weekend = Saturday + Sunday.
-- date_sk format: YYYYMMDD as INT, sortable and human-readable without joins.

SET SESSION cte_max_recursion_depth = 10000;

CREATE TABLE olist_marts.dim_date AS
WITH RECURSIVE base AS (
    SELECT DATE_SUB(
        (SELECT MIN(min_date) FROM (
            SELECT MIN(order_purchase_timestamp) AS min_date FROM olist_staging.stg_orders
            UNION ALL
            SELECT MIN(shipping_limit_date) FROM olist_staging.stg_order_items
        ) AS mins),
        INTERVAL 30 DAY
    ) AS date_value
    UNION ALL
    SELECT date_value + INTERVAL 1 DAY
    FROM base
    WHERE date_value < DATE_ADD(
        (SELECT MAX(max_date) FROM (
            SELECT MAX(order_estimated_delivery_date) AS max_date FROM olist_staging.stg_orders
            UNION ALL
            SELECT MAX(order_delivered_customer_date) FROM olist_staging.stg_orders
            UNION ALL
            SELECT MAX(shipping_limit_date) FROM olist_staging.stg_order_items
        ) AS maxes),
        INTERVAL 30 DAY
    )
)
SELECT
    CAST(DATE_FORMAT(date_value, '%Y%m%d') AS UNSIGNED) AS date_sk,
    date_value,
    YEAR(date_value) AS year,
    QUARTER(date_value) AS quarter,
    MONTH(date_value) AS month,
    MONTHNAME(date_value) AS month_name,
    CAST(DATE_FORMAT(date_value, '%Y%m') AS UNSIGNED) AS date_year_month,
    DAY(date_value) AS day_of_month,
    WEEKDAY(date_value) + 1 AS day_of_week,
    DAYNAME(date_value) AS day_name,
    (WEEKDAY(date_value) + 1) IN (6, 7) AS is_weekend,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM base;

ALTER TABLE olist_marts.dim_date
    ADD PRIMARY KEY (date_sk);