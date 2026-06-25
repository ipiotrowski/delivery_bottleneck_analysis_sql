-- Marts layer indexes.
-- Required after building dimensions but before building facts.
-- Facts join to dimensions on natural keys to resolve surrogate keys; without indexes, CTAS hangs.

ALTER TABLE olist_marts.dim_customer ADD INDEX idx_customer_unique_id (customer_unique_id);
ALTER TABLE olist_marts.dim_seller ADD INDEX idx_seller_id (seller_id);
ALTER TABLE olist_marts.dim_product ADD INDEX idx_product_id (product_id);
ALTER TABLE olist_marts.fact_orders ADD INDEX idx_order_id (order_id);