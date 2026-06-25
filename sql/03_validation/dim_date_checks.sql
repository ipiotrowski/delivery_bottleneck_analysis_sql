-- Sanity checks for dim_date.
-- Expected: row_count = distinct_sk (PK uniqueness), 
--           first_date around 2016-08-05, last_date around 2020+ (shipping_limit_date outliers extend range beyond order lifecycle),
--           weekend_days ~ row_count * 2/7.

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT date_sk) AS distinct_sk,
    MIN(date_value) AS first_date,
    MAX(date_value) AS last_date,
    SUM(is_weekend) AS weekend_days
FROM olist_marts.dim_date;