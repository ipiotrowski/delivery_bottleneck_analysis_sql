-- Product dimension. Grain: one row per product_id.
-- Joins stg_products with stg_product_category_translation to attach English category.
-- LEFT JOIN preserves all products; missing translations default to 'unclassified' (consistent with staging).

CREATE TABLE olist_marts.dim_product AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.product_id) AS product_sk,
    p.product_id,
    COALESCE(t.product_category_name_english, 'unclassified') AS product_category,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    CURRENT_TIMESTAMP AS dwh_loaded_at
FROM olist_staging.stg_products as p
LEFT JOIN olist_staging.stg_product_category_translation as t
    ON p.product_category_name = t.product_category_name;

ALTER TABLE olist_marts.dim_product
    MODIFY COLUMN product_category VARCHAR(64) NOT NULL,
    ADD PRIMARY KEY (product_sk);