-- Stage attribution: which fulfillment stage tips an order into "late".
-- Late = DATE(delivered_customer_date) > estimated_delivery_date (customer received order at least one day past promise).
-- Attribution method: for each late order, compute delay_hours = interval - median for each of 3 stages.
-- The stage with the largest delay_hours wins the attribution. One winner per late order (ROW_NUMBER, not RANK).
-- Grain: 3 rows in output, one per stage, with attribution count, percentage share, and average delay.
-- Different from analysis 04: 04 describes population-wide stage duration, 07 asks who's responsible when orders fail.
-- Median baseline computed from ALL orders (filtered by data availability, not lateness) via PERCENT_RANK + MIN(CASE WHEN).

WITH filtered_orders AS (SELECT
						   order_sk,
                           order_purchase_timestamp as purchase_date,
                           order_approved_at as approval_date,
                           order_delivered_carrier_date as delivered_carrier_date,
                           order_delivered_customer_date as delivered_customer_date,
                           order_estimated_delivery_date AS estimated_delivery_date
						 FROM fact_orders
                         WHERE order_purchase_timestamp IS NOT NULL
                           AND order_approved_at IS NOT NULL
                           AND order_delivered_carrier_date IS NOT NULL
                           AND order_delivered_customer_date IS NOT NULL
						   AND order_purchase_timestamp >= '2017-01-01'),
	 stage_intervals AS (SELECT
                           order_sk,
						   1 as stage_order,
                           'purchase_to_approved' as stage,
                           TIMESTAMPDIFF(HOUR, purchase_date, approval_date) as interval_hours
						 FROM filtered_orders
						 UNION ALL
						 SELECT
                           order_sk,
                           2 as stage_order,
                           'approved_to_carrier' as stage,
                           TIMESTAMPDIFF(HOUR, approval_date, delivered_carrier_date) as interval_hours
						 FROM filtered_orders
                         UNION ALL
                         SELECT
                           order_sk,
                           3 as stage_order,
                           'carrier_to_delivered_customer' as stage,
                           TIMESTAMPDIFF(HOUR, delivered_carrier_date, delivered_customer_date) as interval_hours
						 FROM  filtered_orders),
  stage_percent_rank AS (SELECT
                           order_sk,
						   stage_order,
                           stage,
                           interval_hours,
                           PERCENT_RANK() OVER(PARTITION BY stage_order ORDER BY interval_hours) as percent_rank_value
						 FROM stage_intervals),
       stage_medians AS (SELECT
                           stage,
                           MIN(CASE WHEN percent_rank_value >= 0.50 THEN interval_hours END) as median_hours
						 FROM stage_percent_rank
                         GROUP BY stage),
   late_stage_delays AS (SELECT
                           spr.order_sk,
                           spr.stage_order,
                           spr.stage,
                           spr.interval_hours - sm.median_hours AS delay_hours
						 FROM stage_percent_rank as spr
                         INNER JOIN stage_medians as sm ON
                         spr.stage = sm.stage
                         INNER JOIN filtered_orders as fo ON
                         spr.order_sk = fo.order_sk
                         WHERE DATE(fo.delivered_customer_date) > fo.estimated_delivery_date),
   late_stage_ranked AS (SELECT
						   order_sk,
                           stage_order,
                           stage,
                           delay_hours,
                           ROW_NUMBER() OVER (PARTITION BY order_sk ORDER BY delay_hours DESC) AS delay_rank
						 FROM late_stage_delays)
                         
                           
SELECT
  stage_order,
  stage,
  COUNT(order_sk) as late_orders_attributed,
  ROUND((COUNT(order_sk) / SUM(COUNT(order_sk)) OVER()) * 100, 2) as pct_of_late_orders,
  ROUND(AVG(delay_hours), 0) as avg_delay_hours
FROM late_stage_ranked
WHERE delay_rank = 1
GROUP BY stage_order, stage
ORDER BY stage_order;
                           