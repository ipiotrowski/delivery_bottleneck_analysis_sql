-- Seller lead-time percentile distribution.
-- Lead time = order_purchase_timestamp -> order_delivered_carrier_date (the interval where the seller has operational control).
-- Grain: one row per (order, seller); a multi-seller order produces one observation per seller.
-- Percentiles computed via PERCENT_RANK + MIN(CASE WHEN ...) pattern (MySQL 8 has no PERCENTILE_CONT).
-- Filtered to sellers with >= 30 shipments for statistical sanity; raise to 100 for tighter P90/P99 reliability.
-- Output: one row per seller, columns p50/p75/p90/p99 in hours. Sorted by p90 desc to surface long-tail performers.

WITH lead_time_base AS (SELECT
					oi.order_sk,
					oi.seller_sk,
					timestampdiff(HOUR, MIN(o.order_purchase_timestamp), MIN(o.order_delivered_carrier_date)) as lead_time_hours
					FROM fact_order_items as oi
					INNER JOIN fact_orders as o ON
					oi.order_sk = o.order_sk
					WHERE o.order_delivered_carrier_date IS NOT NULL
					GROUP BY oi.order_sk, oi.seller_sk),
	percent_rank_base AS (SELECT
					seller_sk, lead_time_hours,
                    PERCENT_RANK() OVER(PARTITION BY seller_sk ORDER BY lead_time_hours) as percent_rank_value
                    FROM lead_time_base),                    
    percentile_base AS (SELECT
					seller_sk,
					COUNT(*) AS total_shipments,
					MIN(CASE WHEN percent_rank_value >= 0.50 THEN lead_time_hours END) as p50,
					MIN(CASE WHEN percent_rank_value >= 0.75 THEN lead_time_hours END) as p75,
					MIN(CASE WHEN percent_rank_value >= 0.90 THEN lead_time_hours END) as p90,
					MIN(CASE WHEN percent_rank_value >= 0.99 THEN lead_time_hours END) as p99
					FROM percent_rank_base
					GROUP BY seller_sk)

SELECT
s.seller_id,
pb.total_shipments,
pb.p50, pb.p75, pb.p90, pb.p99
FROM percentile_base as pb
INNER JOIN dim_seller as s ON
pb.seller_sk = s.seller_sk
WHERE pb.total_shipments >=30
ORDER BY pb.p90 DESC;