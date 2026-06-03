-- Staging model for product category translation: cast types, trim whitespace, add load timestamp, set PK.
-- Note: MySQL CTAS materializes CHAR/VARCHAR casts as VARCHAR. The ALTER TABLE
-- enforces explicit VARCHAR sizing for variable-length text columns.
 
CREATE TABLE olist_staging.stg_product_category_translation AS
SELECT
    TRIM(product_category_name) AS product_category_name,
    TRIM(product_category_name_english) AS product_category_name_english,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_raw.product_category_translation;
 
ALTER TABLE olist_staging.stg_product_category_translation
    MODIFY COLUMN product_category_name VARCHAR(64),
    MODIFY COLUMN product_category_name_english VARCHAR(64),
    ADD PRIMARY KEY (product_category_name);
