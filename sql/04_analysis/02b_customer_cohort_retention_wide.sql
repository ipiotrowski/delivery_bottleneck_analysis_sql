-- Customer cohort retention by first-purchase month, wide format.
-- Same cohort logic as 02_customer_cohort_retention. Pivoted to fixed 12-month window (M+0 to M+11).
-- Output: one row per cohort_month, columns m0_pct..m11_pct showing retention percentage.
-- Cohort filter: 2017-01 onwards. Earlier months had too few customers to be analytically meaningful.
-- Note: MySQL has no PIVOT operator; pivot done manually via MAX(CASE WHEN ...) aggregation.

WITH first_purchase_base AS (
						SELECT
							customer_sk,
							DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m-01') AS first_purchase_month
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
							fp.first_purchase_month AS cohort_month,
							TIMESTAMPDIFF(MONTH, fp.first_purchase_month, com.order_month) AS months_since_first,
							COUNT(DISTINCT fp.customer_sk) AS active_customers
						FROM first_purchase_base AS fp
						INNER JOIN customer_order_months AS com
							ON fp.customer_sk = com.customer_sk
						GROUP BY fp.first_purchase_month, TIMESTAMPDIFF(MONTH, fp.first_purchase_month, com.order_month)),
		  retention_base AS (
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
						FROM cohort_base)

SELECT
    cohort_month,
    MAX(cohort_size) AS cohort_size,
    MAX(CASE WHEN months_since_first = 0  THEN retention_percentage END) AS m0_pct,
    MAX(CASE WHEN months_since_first = 1  THEN retention_percentage END) AS m1_pct,
    MAX(CASE WHEN months_since_first = 2  THEN retention_percentage END) AS m2_pct,
    MAX(CASE WHEN months_since_first = 3  THEN retention_percentage END) AS m3_pct,
    MAX(CASE WHEN months_since_first = 4  THEN retention_percentage END) AS m4_pct,
    MAX(CASE WHEN months_since_first = 5  THEN retention_percentage END) AS m5_pct,
    MAX(CASE WHEN months_since_first = 6  THEN retention_percentage END) AS m6_pct,
    MAX(CASE WHEN months_since_first = 7  THEN retention_percentage END) AS m7_pct,
    MAX(CASE WHEN months_since_first = 8  THEN retention_percentage END) AS m8_pct,
    MAX(CASE WHEN months_since_first = 9  THEN retention_percentage END) AS m9_pct,
    MAX(CASE WHEN months_since_first = 10 THEN retention_percentage END) AS m10_pct,
    MAX(CASE WHEN months_since_first = 11 THEN retention_percentage END) AS m11_pct
FROM retention_base
WHERE cohort_month >= '2017-01-01'
GROUP BY cohort_month
ORDER BY cohort_month;