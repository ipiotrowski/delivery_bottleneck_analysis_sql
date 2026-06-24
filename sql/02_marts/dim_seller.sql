-- Seller dimension. Grain: one row per seller_id.
-- Source stg_sellers already has one row per seller, no deduplication or resolution needed.

CREATE TABLE olist_marts.dim_seller AS
SELECT
    ROW_NUMBER() OVER (ORDER BY seller_id) AS seller_sk,
    seller_id,
    seller_city,
    seller_state,
    seller_zip_code_prefix,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_staging.stg_sellers;

ALTER TABLE olist_marts.dim_seller
    ADD PRIMARY KEY (seller_sk);