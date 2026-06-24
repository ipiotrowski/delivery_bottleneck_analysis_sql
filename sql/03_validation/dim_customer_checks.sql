-- Sanity checks for dim_customer.
-- Expected: row_count = distinct customer_sk = distinct customer_unique_id (grain).
--           row_count close to count(distinct customer_unique_id) in stg_customers (INNER JOIN drop should be near zero).
--           no NULLs in customer_unique_id, customer_state.

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT customer_sk) AS distinct_sk,
    COUNT(DISTINCT customer_unique_id) AS distinct_natural_key,
    SUM(customer_unique_id IS NULL) AS null_unique_id,
    SUM(customer_state IS NULL) AS null_state
FROM olist_marts.dim_customer;

-- Confirm INNER JOIN didn't drop customers.
-- Expected: dropped_customers = 0 (every customer in stg_customers has at least one order).
SELECT
    (SELECT COUNT(DISTINCT customer_unique_id) FROM olist_staging.stg_customers) AS source_customers,
    (SELECT COUNT(*) FROM olist_marts.dim_customer) AS marts_customers,
    (SELECT COUNT(DISTINCT customer_unique_id) FROM olist_staging.stg_customers) 
        - (SELECT COUNT(*) FROM olist_marts.dim_customer) AS dropped_customers;