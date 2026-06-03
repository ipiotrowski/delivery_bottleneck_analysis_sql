-- Staging model for sellers: cast types, trim whitespace, add load timestamp, set PK.
-- Note: MySQL CTAS materializes CHAR/VARCHAR casts as VARCHAR. The ALTER TABLE
-- enforces explicit VARCHAR sizing for variable-length text columns.

CREATE TABLE olist_staging.stg_sellers AS
SELECT
    CAST(seller_id AS CHAR(32)) AS seller_id,
    CAST(seller_zip_code_prefix AS CHAR(5)) AS seller_zip_code_prefix,
    TRIM(seller_city) AS seller_city,
    CAST(TRIM(seller_state) AS CHAR(2)) AS seller_state,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_raw.sellers;

ALTER TABLE olist_staging.stg_sellers
    MODIFY COLUMN seller_city VARCHAR(64),
    ADD PRIMARY KEY (seller_id);