-- Customer cohort retention by first-purchase month.
-- Customer = customer_sk (person, not order instance). Cohort = month of customer's first non-canceled purchase.
-- months_since_first measured as TIMESTAMPDIFF(MONTH, first_purchase, order_month); 0 for the cohort entry month.
-- Excludes canceled and unavailable orders from both cohort assignment and retention measurement.
-- Output (long format): one row per (cohort_month, months_since_first) with absolute and percentage retention.
-- Cohort filter: 2017-01 onwards. Earlier months had too few customers to be analytically meaningful.
-- Note: Olist is dominated by one-time buyers, so retention beyond M+0 is very low. This is a finding, not a bug.

WITH first_purchase_base AS (
						SELECT
						   customer_sk,
						   DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m-01') as first_purchase_month
						FROM fact_orders
                        WHERE order_status NOT IN ('canceled', 'unavailable')
						GROUP BY customer_sk
						),
   customer_order_months AS (
						SELECT DISTINCT
						   customer_sk,
						   DATE_FORMAT(order_purchase_timestamp, '%Y-%m-01') AS order_month
						FROM fact_orders
						WHERE order_status NOT IN ('canceled', 'unavailable')),
			cohort_base AS (
						SELECT
                           fp.first_purchase_month as cohort_month,
                           TIMESTAMPDIFF(MONTH, fp.first_purchase_month, com.order_month) as months_since_first,
                           COUNT(DISTINCT fp.customer_sk) as active_customers
						FROM first_purchase_base as fp
                        INNER JOIN customer_order_months as com
                           ON fp.customer_sk = com.customer_sk
						GROUP BY fp.first_purchase_month, TIMESTAMPDIFF(MONTH, fp.first_purchase_month, com.order_month))

SELECT
    cohort_month,
    months_since_first,
    active_customers,
    MAX(CASE WHEN months_since_first = 0 THEN active_customers END) 
        OVER (PARTITION BY cohort_month) AS cohort_size,
    ROUND(
        100.0 * active_customers / 
        MAX(CASE WHEN months_since_first = 0 THEN active_customers END) 
            OVER (PARTITION BY cohort_month),
    2) AS retention_percentage
FROM cohort_base
WHERE cohort_month >= '2017-01-01'
ORDER BY cohort_month, months_since_first;