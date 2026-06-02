-- Raw tables for Olist CSVs. All columns VARCHAR, no keys, no indexes.
-- Typing and cleaning happen in the staging layer.

USE olist_raw;

-- Source: olist_customers_dataset.csv
CREATE TABLE IF NOT EXISTS customers (
    customer_id              VARCHAR(64),
    customer_unique_id       VARCHAR(64),
    customer_zip_code_prefix VARCHAR(16),
    customer_city            VARCHAR(128),
    customer_state           VARCHAR(8)
);

-- Source: olist_geolocation_dataset.csv
CREATE TABLE IF NOT EXISTS geolocation (
    geolocation_zip_code_prefix VARCHAR(16),
    geolocation_lat             VARCHAR(32),
    geolocation_lng             VARCHAR(32),
    geolocation_city            VARCHAR(128),
    geolocation_state           VARCHAR(8)
);

-- Source: olist_order_items_dataset.csv
CREATE TABLE IF NOT EXISTS order_items (
    order_id            VARCHAR(64),
    order_item_id       VARCHAR(8),
    product_id          VARCHAR(64),
    seller_id           VARCHAR(64),
    shipping_limit_date VARCHAR(32),
    price               VARCHAR(32),
    freight_value       VARCHAR(32)
);

-- Source: olist_order_payments_dataset.csv
CREATE TABLE IF NOT EXISTS order_payments (
    order_id             VARCHAR(64),
    payment_sequential   VARCHAR(8),
    payment_type         VARCHAR(32),
    payment_installments VARCHAR(8),
    payment_value        VARCHAR(32)
);

-- Source: olist_order_reviews_dataset.csv
CREATE TABLE IF NOT EXISTS order_reviews (
    review_id               VARCHAR(64),
    order_id                VARCHAR(64),
    review_score            VARCHAR(8),
    review_comment_title    VARCHAR(255),
    review_comment_message  TEXT,
    review_creation_date    VARCHAR(32),
    review_answer_timestamp VARCHAR(32)
);

-- Source: olist_orders_dataset.csv
CREATE TABLE IF NOT EXISTS orders (
    order_id                      VARCHAR(64),
    customer_id                   VARCHAR(64),
    order_status                  VARCHAR(32),
    order_purchase_timestamp      VARCHAR(32),
    order_approved_at             VARCHAR(32),
    order_delivered_carrier_date  VARCHAR(32),
    order_delivered_customer_date VARCHAR(32),
    order_estimated_delivery_date VARCHAR(32)
);

-- Source: olist_products_dataset.csv
-- "lenght" typo matches the source CSV. Fixed in staging.
CREATE TABLE IF NOT EXISTS products (
    product_id                 VARCHAR(64),
    product_category_name      VARCHAR(128),
    product_name_lenght        VARCHAR(8),
    product_description_lenght VARCHAR(8),
    product_photos_qty         VARCHAR(8),
    product_weight_g           VARCHAR(16),
    product_length_cm          VARCHAR(8),
    product_height_cm          VARCHAR(8),
    product_width_cm           VARCHAR(8)
);

-- Source: olist_sellers_dataset.csv
CREATE TABLE IF NOT EXISTS sellers (
    seller_id              VARCHAR(64),
    seller_zip_code_prefix VARCHAR(16),
    seller_city            VARCHAR(128),
    seller_state           VARCHAR(8)
);

-- Source: product_category_name_translation.csv
CREATE TABLE IF NOT EXISTS product_category_translation (
    product_category_name         VARCHAR(128),
    product_category_name_english VARCHAR(128)
);
