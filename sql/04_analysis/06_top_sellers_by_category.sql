-- Top sellers by product category using three ranking functions side by side.
-- Metric: items_sold (COUNT of order_item rows per (category, seller)) - chosen because it produces natural ties.
-- Three window functions demonstrated on the same partition:
--   ROW_NUMBER: unique position 1..N; ties broken arbitrarily (deterministic here via seller_id ASC).
--   RANK: same position on ties, then skips (e.g. 1, 2, 2, 4).
--   DENSE_RANK: same position on ties, no skips (e.g. 1, 2, 2, 3).
-- Filter: DENSE_RANK <= 5 keeps five distinct levels of items_sold per category, including all sellers that tie.
-- Filters: 2017-01-01 onwards, excludes canceled/unavailable orders and 'unclassified' category.
-- Revenue and orders_count kept as context columns; ranking is by items_sold only.

WITH seller_category_revenue AS (SELECT
								  p.product_category,
                                  s.seller_id,
                                  sum(oi.price) as revenue,
                                  count(oi.order_item_sk) as items_sold,
                                  count(distinct o.order_id) as orders_count
								 FROM fact_order_items as oi
                                 INNER JOIN fact_orders as o ON
                                 oi.order_sk = o.order_sk
                                 INNER JOIN dim_seller as s ON
                                 oi.seller_sk = s.seller_sk
                                 INNER JOIN dim_product as p ON
                                 oi.product_sk = p.product_sk
                                 WHERE o.order_purchase_timestamp >= '2017-01-01'
								  AND o.order_status NOT IN('canceled','unavailable')
                                  AND p.product_category <> 'unclassified'
								 GROUP BY
                                  p.product_category,
                                  s.seller_id),
				ranking_base AS (SELECT
								   product_category,
                                   seller_id,
                                   revenue,
                                   items_sold,
                                   orders_count,
                                   ROW_NUMBER() OVER(PARTITION BY product_category ORDER BY items_sold DESC) as row_num_val,
                                   RANK() OVER(PARTITION BY product_category ORDER BY items_sold DESC) as rank_val,
                                   DENSE_RANK() OVER(PARTITION BY product_category ORDER BY items_sold DESC) as dense_rank_val
								 FROM seller_category_revenue)
								
SELECT
  product_category,
  seller_id,
  items_sold,
  row_num_val,
  rank_val,
  dense_rank_val,
  revenue,
  orders_count
FROM ranking_base
WHERE dense_rank_val <= 5
ORDER BY product_category, row_num_val;