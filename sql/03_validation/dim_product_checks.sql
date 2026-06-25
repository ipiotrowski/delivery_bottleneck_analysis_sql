-- Sanity checks for dim_product.
-- Expected: row_count = distinct product_sk = distinct product_id (grain).
--           row_count matches stg_products count exactly (LEFT JOIN doesn't drop).
--           no NULLs in product_category (COALESCE fallback enforced by NOT NULL).
--           unclassified count = sum of (NULL in source category + missing in translation).

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT product_sk) AS distinct_sk,
    COUNT(DISTINCT product_id) AS distinct_natural_key,
    SUM(product_category IS NULL) AS null_category,
    SUM(product_category = 'unclassified') AS unclassified_count
FROM olist_marts.dim_product;

-- Confirm marts matches source 1:1 (LEFT JOIN preserved all rows).
-- Expected: diff = 0.
SELECT
    (SELECT COUNT(*) FROM olist_staging.stg_products) AS source_products,
    (SELECT COUNT(*) FROM olist_marts.dim_product) AS marts_products,
    (SELECT COUNT(*) FROM olist_staging.stg_products)
        - (SELECT COUNT(*) FROM olist_marts.dim_product) AS diff;

-- Verify unclassified count reconciles with staging.
-- Expected: marts_unclassified = staging_unclassified + missing_translations.
SELECT
    (SELECT COUNT(*) FROM olist_staging.stg_products 
        WHERE product_category_name = 'unclassified') AS staging_unclassified,
    (SELECT COUNT(*) FROM olist_staging.stg_products as p
        LEFT JOIN olist_staging.stg_product_category_translation as t
            ON p.product_category_name = t.product_category_name
        WHERE t.product_category_name IS NULL 
            AND p.product_category_name <> 'unclassified') AS missing_translations,
    (SELECT COUNT(*) FROM olist_marts.dim_product 
        WHERE product_category = 'unclassified') AS marts_unclassified;