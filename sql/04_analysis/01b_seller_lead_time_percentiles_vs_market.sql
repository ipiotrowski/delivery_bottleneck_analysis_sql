-- Seller lead-time percentiles compared to marketplace benchmark.
-- Extends 01_seller_lead_time_percentiles with market-wide P50/P75/P90/P99 and per-percentile delta vs market.
-- Lead time = order_purchase_timestamp -> order_delivered_carrier_date.
-- Grain: one row per (order, seller); market percentiles computed over the same population (no PARTITION BY).
-- Filtered to sellers with >= 30 shipments for statistical sanity.
-- Output sorted by p90_vs_market desc to surface sellers with the worst tail performance relative to market.
-- Positive delta = slower than market, negative delta = faster than market.

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
                    PERCENT_RANK() OVER(PARTITION BY seller_sk ORDER BY lead_time_hours) as percent_rank_value,
                    PERCENT_RANK() OVER(ORDER BY lead_time_hours) as market_percent_rank
                    FROM lead_time_base),                    
    percentile_base AS (SELECT
					seller_sk,
					COUNT(*) AS total_shipments,
					MIN(CASE WHEN percent_rank_value >= 0.50 THEN lead_time_hours END) as p50,
					MIN(CASE WHEN percent_rank_value >= 0.75 THEN lead_time_hours END) as p75,
					MIN(CASE WHEN percent_rank_value >= 0.90 THEN lead_time_hours END) as p90,
					MIN(CASE WHEN percent_rank_value >= 0.99 THEN lead_time_hours END) as p99
					FROM percent_rank_base
					GROUP BY seller_sk),
     market_percentile_base AS (SELECT
				   MIN(CASE WHEN market_percent_rank >= 0.50 THEN lead_time_hours END) as market_p50,
                   MIN(CASE WHEN market_percent_rank >= 0.75 THEN lead_time_hours END) as market_p75,
                   MIN(CASE WHEN market_percent_rank >= 0.90 THEN lead_time_hours END) as market_p90,
                   MIN(CASE WHEN market_percent_rank >= 0.99 THEN lead_time_hours END) as market_p99
                   FROM percent_rank_base)

SELECT
s.seller_id,
pb.total_shipments,
pb.p50, pb.p75, pb.p90, pb.p99,
mpb.market_p50, mpb.market_p75, mpb.market_p90, mpb.market_p99,
pb.p50 - mpb.market_p50 as p50_vs_market,
pb.p75 - mpb.market_p75 as p75_vs_market,
pb.p90 - mpb.market_p90 as p90_vs_market,
pb.p99 - mpb.market_p99 as p99_vs_market
FROM percentile_base as pb
INNER JOIN dim_seller as s ON
pb.seller_sk = s.seller_sk
CROSS JOIN market_percentile_base as mpb
WHERE pb.total_shipments >=30
ORDER BY pb.p90 - mpb.market_p90 DESC;