-- Date dimension. Grain: one row per day.
-- Range: 30 days before earliest order_purchase_timestamp to 30 days after latest order_estimated_delivery_date.
-- day_of_week follows ISO 8601 (1=Monday, 7=Sunday). Weekend = Saturday + Sunday.
-- date_sk format: YYYYMMDD as INT, sortable and human-readable without joins.

SET SESSION cte_max_recursion_depth = 10000;

CREATE TABLE olist_marts.dim_date AS
WITH RECURSIVE base AS (
    SELECT DATE_SUB(
        DATE((SELECT MIN(order_purchase_timestamp) FROM olist_staging.stg_orders)),
        INTERVAL 30 DAY
    ) AS date_value
    UNION ALL
    SELECT date_value + INTERVAL 1 DAY
    FROM base
    WHERE date_value < DATE_ADD(
        DATE((SELECT MAX(order_estimated_delivery_date) FROM olist_staging.stg_orders)),
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