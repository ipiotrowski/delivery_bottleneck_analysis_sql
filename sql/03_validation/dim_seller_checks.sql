-- Sanity checks for dim_seller.
-- Expected: row_count = distinct seller_sk = distinct seller_id (grain).
--           row_count matches source stg_sellers count exactly (no joins, no filters).
--           no NULLs in seller_id, seller_state.

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT seller_sk) AS distinct_sk,
    COUNT(DISTINCT seller_id) AS distinct_natural_key,
    SUM(seller_id IS NULL) AS null_seller_id,
    SUM(seller_state IS NULL) AS null_state
FROM olist_marts.dim_seller;

-- Confirm marts matches source 1:1.
-- Expected: source_sellers = marts_sellers, diff = 0.
SELECT
    (SELECT COUNT(*) FROM olist_staging.stg_sellers) AS source_sellers,
    (SELECT COUNT(*) FROM olist_marts.dim_seller) AS marts_sellers,
    (SELECT COUNT(*) FROM olist_staging.stg_sellers)
        - (SELECT COUNT(*) FROM olist_marts.dim_seller) AS diff;