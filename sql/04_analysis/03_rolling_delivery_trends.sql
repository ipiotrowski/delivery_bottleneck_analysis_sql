-- Rolling 7-day and 30-day delivery performance trends.
-- Anchored on order_purchase_timestamp (predictive: reacts on order intake, not order fulfillment).
-- Metric: total delivery time = purchase -> delivered_customer, weighted by order volume within each rolling window.
-- Weighted average avoids the "average of averages" trap where low-volume days would carry equal weight to high-volume ones.
-- overall_avg is the marketplace-wide weighted mean, broadcast to every row for comparison.
-- Filter: orders from 2017-01-01 onwards; earlier volumes were too low for meaningful trends (same rationale as 02_).

WITH daily_orders_base AS (
			SELECT
				DATE(order_purchase_timestamp) as purchase_date,
                COUNT(order_id) as orders_count,
                ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)), 1) as avg_delivery_days
			FROM fact_orders
            WHERE order_delivered_customer_date IS NOT NULL
            AND order_purchase_timestamp >= '2017-01-01'
            GROUP BY
				DATE(order_purchase_timestamp)),
  rolling_metrics_base AS (
			SELECT
				purchase_date,
                orders_count,
                avg_delivery_days,
                ROUND(SUM(orders_count * avg_delivery_days) OVER(ORDER BY purchase_date RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW)
						/ SUM(orders_count) OVER(ORDER BY purchase_date RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW), 1) as rolling_7d_avg,
                ROUND(SUM(orders_count * avg_delivery_days) OVER(ORDER BY purchase_date RANGE BETWEEN INTERVAL 29 DAY PRECEDING AND CURRENT ROW)
						/ SUM(orders_count) OVER(ORDER BY purchase_date RANGE BETWEEN INTERVAL 29 DAY PRECEDING AND CURRENT ROW), 1) as rolling_30d_avg
			FROM daily_orders_base)
            
SELECT
	purchase_date,
	orders_count,
	avg_delivery_days,
	rolling_7d_avg,
	rolling_30d_avg,
	ROUND(SUM(orders_count * avg_delivery_days) OVER()
			/ SUM(orders_count) OVER(),1) as overall_avg
FROM rolling_metrics_base;