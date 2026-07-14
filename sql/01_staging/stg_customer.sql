-- Staging model for customers: cast types, trim whitespace, add load timestamp, set PK.
-- Note: MySQL CTAS materializes CHAR/VARCHAR casts as VARCHAR. The ALTER TABLE
-- enforces explicit VARCHAR sizing for variable-length text columns.

CREATE TABLE olist_staging.stg_customers AS
SELECT
    CAST(customer_id AS CHAR(32)) AS customer_id,
    CAST(customer_unique_id AS CHAR(32)) AS customer_unique_id,
    CAST(customer_zip_code_prefix AS CHAR(5)) AS customer_zip_code_prefix,
    TRIM(customer_city) AS customer_city,
    CAST(TRIM(customer_state) AS CHAR(2)) AS customer_state,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_raw.customers;

ALTER TABLE olist_staging.stg_customers
    MODIFY COLUMN customer_city VARCHAR(64),
    ADD PRIMARY KEY (customer_id);