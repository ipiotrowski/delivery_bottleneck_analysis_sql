-- Staging layer indexes.
-- Required before building marts layer. Without these, CTAS joins in marts hang on full table scans.
-- All natural keys used in marts joins get indexed.

ALTER TABLE olist_staging.stg_orders ADD INDEX idx_customer_id (customer_id);
ALTER TABLE olist_staging.stg_customers ADD INDEX idx_customer_unique_id (customer_unique_id);
ALTER TABLE olist_staging.stg_order_items ADD INDEX idx_order_id (order_id);
ALTER TABLE olist_staging.stg_order_items ADD INDEX idx_seller_id (seller_id);
ALTER TABLE olist_staging.stg_order_items ADD INDEX idx_product_id (product_id);