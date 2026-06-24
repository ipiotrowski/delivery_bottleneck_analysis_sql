-- Customer dimension. Grain: one row per customer_unique_id (the person, not the order instance).
-- Attributes (city, state, zip) taken from the customer's most recent order to reflect current state.
-- Resolution path: stg_orders.customer_id -> stg_customers.customer_id -> stg_customers.customer_unique_id.
-- Tiebreaker on order_id when timestamps are identical to keep ranking deterministic.

CREATE TABLE olist_marts.dim_customer AS
WITH customer_latest AS (
    SELECT
        c.customer_unique_id,
        c.customer_city,
        c.customer_state,
        c.customer_zip_code_prefix,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp DESC, o.order_id DESC
        ) AS rn
    FROM olist_staging.stg_customers c
    INNER JOIN olist_staging.stg_orders o
        ON c.customer_id = o.customer_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_unique_id) AS customer_sk,
    customer_unique_id,
    customer_city,
    customer_state,
    customer_zip_code_prefix,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM customer_latest
WHERE rn = 1;

ALTER TABLE olist_marts.dim_customer
    ADD PRIMARY KEY (customer_sk);