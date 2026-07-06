-- Geographic analysis: delivery time by customer state and cross-state routing.
-- Grain: (order, seller). Multi-seller orders produce one row per seller (consistent with 01).
-- route_type: "same_state" when customer and seller share a state, "cross_state" when they differ.
-- Filtered to customer_state groups with >= 30 shipments for statistical sanity.
-- Metric: delivery hours from order_purchase_timestamp to order_delivered_customer_date.
-- Output (long): one row per (customer_state, is_inter_state) with count, avg, median, p90.
-- Northern states typically appear as inter-state only, as few sellers operate outside SP/RJ region.

WITH orders_with_geo AS (SELECT
						   oi.order_sk,
                           o.customer_sk,
                           c.customer_state,
                           oi.seller_sk,
                           s.seller_state,
                           CASE WHEN c.customer_state = s.seller_state THEN "same_state" ELSE "cross_state" END as route_type,
                           MIN(TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp, o.order_delivered_customer_date)) as delivery_hours
						 FROM fact_order_items as oi
                         INNER JOIN fact_orders as o ON
                          oi.order_sk = o.order_sk
						 INNER JOIN dim_seller as s ON
                          oi.seller_sk = s.seller_sk
						 INNER JOIN dim_customer as c ON
                          o.customer_sk = c.customer_sk
						 WHERE o.order_delivered_customer_date IS NOT NULL
							AND o.order_purchase_timestamp >= '2017-01-01'
                         GROUP BY
						   oi.order_sk,
                           o.customer_sk,
                           c.customer_state,
                           oi.seller_sk,
                           s.seller_state,
                           CASE WHEN c.customer_state = s.seller_state THEN "same_state" ELSE "cross_state" END),
   percent_rank_base AS (SELECT
						   order_sk,
                           customer_sk,
                           customer_state,
                           seller_sk,
                           seller_state,
                           route_type,
						   delivery_hours,
                           PERCENT_RANK() OVER (PARTITION BY customer_state, route_type ORDER BY delivery_hours) as percent_rank_value
						FROM orders_with_geo)
                        
SELECT
  customer_state,
  route_type,
  COUNT(order_sk) as order_count,
  ROUND(AVG(delivery_hours),0) as avg_delivery_hours,
  MIN(CASE WHEN percent_rank_value >= 0.50 THEN delivery_hours END) as median_delivery_hours,
  MIN(CASE WHEN percent_rank_value >= 0.90 THEN delivery_hours END) as p90_delivery_hours
FROM percent_rank_base
GROUP BY
  customer_state,
  route_type
HAVING COUNT(order_sk) >= 30
ORDER BY
  customer_state,
  route_type;