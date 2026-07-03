-- Sequence gap analysis: distribution of time spent in each order lifecycle stage.
-- Three stages measured: purchase -> approved (payment), approved -> carrier (seller packing), carrier -> delivered_customer (transit).
-- Grain: fact_orders. Only orders with all four timestamps present are included (2017-01-01 onwards).
-- Unpivot via UNION ALL, then PERCENT_RANK per stage for percentiles + straight AVG for mean.
-- Output: one row per stage in lifecycle order, with p50/p75/p90/p99/avg in hours.
-- Not the same as stage attribution (07): this describes the population, not late orders specifically.

WITH filtered_orders AS (SELECT
						   order_purchase_timestamp as purchase_date,
                           order_approved_at as approval_date,
                           order_delivered_carrier_date as delivered_carrier_date,
                           order_delivered_customer_date as delivered_customer_date
						 FROM fact_orders
                         WHERE order_purchase_timestamp IS NOT NULL
							   AND order_approved_at IS NOT NULL
                               AND order_delivered_carrier_date IS NOT NULL
                               AND order_delivered_customer_date IS NOT NULL
                               AND order_purchase_timestamp >= '2017-01-01'),
	 stage_intervals AS (SELECT
						   1 as stage_order,
                           'purchase_to_approved' as stage,
                           TIMESTAMPDIFF(HOUR, purchase_date, approval_date) as interval_hours
						 FROM filtered_orders
						 UNION ALL
						 SELECT
                           2 as stage_order,
                           'approved_to_carrier' as stage,
                           TIMESTAMPDIFF(HOUR, approval_date, delivered_carrier_date) as interval_hours
						 FROM filtered_orders
                         UNION ALL
                         SELECT
                           3 as stage_order,
                           'carrier_to_delivered_customer' as stage,
                           TIMESTAMPDIFF(HOUR, delivered_carrier_date, delivered_customer_date) as interval_hours
						 FROM  filtered_orders),
  stage_percent_rank AS (SELECT
						   stage_order,
                           stage,
                           interval_hours,
                           PERCENT_RANK() OVER(PARTITION BY stage_order ORDER BY interval_hours) as percent_rank_value
						 FROM stage_intervals),
   stage_percentiles AS (SELECT
						   stage_order,
						   stage,
                           MIN(CASE WHEN percent_rank_value >= 0.50 THEN interval_hours END) as p50,
                           MIN(CASE WHEN percent_rank_value >= 0.75 THEN interval_hours END) as p75,
                           MIN(CASE WHEN percent_rank_value >= 0.90 THEN interval_hours END) as p90,
                           MIN(CASE WHEN percent_rank_value >= 0.99 THEN interval_hours END) as p99,
                           ROUND(AVG(interval_hours),0) as stage_avg
						 FROM stage_percent_rank
                         GROUP BY stage_order, stage)
SELECT
  stage_order,
  stage,
  p50, p75, p90, p99,
  stage_avg
FROM stage_percentiles
ORDER BY stage_order;