-- Reference example of profiling queries run before building a staging table.
-- Same checks applied to every source table; only this one is kept in the repo.

USE olist_raw;

-- 1. Total row count. Expect 3,095.
SELECT COUNT(*) AS row_count FROM sellers;

-- 2. seller_id uniqueness. If distinct = total, seller_id is a clean PK.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    COUNT(*) - COUNT(DISTINCT seller_id) AS duplicate_count
FROM sellers;

-- 3. NULL or empty checks per column.
SELECT
    SUM(CASE WHEN seller_id IS NULL OR seller_id = '' THEN 1 ELSE 0 END) AS null_seller_id,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL OR seller_zip_code_prefix = '' THEN 1 ELSE 0 END) AS null_zip,
    SUM(CASE WHEN seller_city IS NULL OR seller_city = '' THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN seller_state IS NULL OR seller_state = '' THEN 1 ELSE 0 END) AS null_state
FROM sellers;

-- 4. State values. Brazil has 27 federative units. Expect <= 27 distinct, all 2 chars.
SELECT
    seller_state,
    COUNT(*) AS seller_count
FROM sellers
GROUP BY seller_state
ORDER BY seller_count DESC;

-- 5. ZIP code length distribution. Brazilian prefixes are 5 digits with leading zeros.
SELECT
    CHAR_LENGTH(seller_zip_code_prefix) AS zip_length,
    COUNT(*) AS row_count
FROM sellers
GROUP BY CHAR_LENGTH(seller_zip_code_prefix)
ORDER BY zip_length;

-- 6. Casing check on city names. Find cities that exist in multiple casings.
SELECT
    LOWER(seller_city) AS city_lower,
    COUNT(DISTINCT seller_city) AS casing_variants,
    GROUP_CONCAT(DISTINCT seller_city ORDER BY seller_city SEPARATOR ' | ') AS variants
FROM sellers
GROUP BY LOWER(seller_city)
HAVING COUNT(DISTINCT seller_city) > 1;