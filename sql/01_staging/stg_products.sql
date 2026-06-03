-- Staging model for products: cast types, label unclassified, fix "lenght" typo, add load timestamp, set PK.
-- Note: MySQL CTAS materializes CHAR/VARCHAR casts as VARCHAR. ALTER TABLE enforces explicit VARCHAR sizing.

CREATE TABLE olist_staging.stg_products AS
SELECT
    CAST(product_id AS CHAR(32)) AS product_id,
    COALESCE(NULLIF(TRIM(product_category_name), ''), 'unclassified') AS product_category_name,
    CAST(NULLIF(TRIM(product_name_lenght), '') AS SIGNED) AS product_name_length,
    CAST(NULLIF(TRIM(product_description_lenght), '') AS SIGNED) AS product_description_length,
    CAST(NULLIF(TRIM(product_photos_qty), '') AS SIGNED) AS product_photos_qty,
    CAST(NULLIF(TRIM(product_weight_g), '') AS SIGNED) AS product_weight_g,
    CAST(NULLIF(TRIM(product_length_cm), '') AS SIGNED) AS product_length_cm,
    CAST(NULLIF(TRIM(product_height_cm), '') AS SIGNED) AS product_height_cm,
    CAST(NULLIF(TRIM(product_width_cm), '') AS SIGNED) AS product_width_cm,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_raw.products;

ALTER TABLE olist_staging.stg_products
    MODIFY COLUMN product_category_name VARCHAR(64) NOT NULL,
    ADD PRIMARY KEY (product_id);
    
    