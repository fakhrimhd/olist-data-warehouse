CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE SCHEMA IF NOT EXISTS stg AUTHORIZATION postgres;

-- Staging Tables
CREATE TABLE stg.order_items (
    id uuid default uuid_generate_v4(),
    order_item_id serial primary key NOT NULL,
    order_id varchar(50) NOT NULL,
    product_id varchar(100) NOT NULL,
    seller_id varchar(100) NOT NULL,
    shipping_limit_date timestamp NULL,
    price numeric(10, 2) NOT NULL,
    freight_value numeric(10, 2) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg.products (
    id uuid default uuid_generate_v4(),
    product_id varchar(100) primary key NOT NULL,
    product_category_name varchar(255) NULL,
    product_name_length int4 NULL,
    product_description_length int4 NULL,
    product_photos_qty int4 NULL,
    product_weight_g int4 NULL,
    product_length_cm int4 NULL,
    product_height_cm int4 NULL,
    product_width_cm int4 NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg.sellers (
    id uuid default uuid_generate_v4(),
    seller_id varchar(100) primary key NOT NULL,
    seller_zip_code_prefix varchar(20) NULL,
    seller_city varchar(100) NULL,
    seller_state varchar(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg.orders (
    id uuid default uuid_generate_v4(),
    order_id varchar(50) primary key NOT NULL,
    customer_id varchar(100) NOT NULL,
    order_status varchar(50) NOT NULL,
    order_purchase_timestamp timestamp NOT NULL,
    order_approved_at timestamp NULL,
    order_delivered_carrier_date timestamp NULL,
    order_delivered_customer_date timestamp NULL,
    order_estimated_delivery_date date NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg.customers (
    id uuid default uuid_generate_v4(),
    customer_id varchar(100) primary key NOT NULL,
    customer_unique_id varchar(100) NOT NULL,
    customer_zip_code_prefix varchar(20) NULL,
    customer_city varchar(100) NULL,
    customer_state varchar(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg.geolocation (
    id uuid default uuid_generate_v4(),
    geolocation_zip_code_prefix varchar(20) primary key NOT NULL,
    geolocation_lat numeric(15, 10) NULL,
    geolocation_lng numeric(15, 10) NULL,
    geolocation_city varchar(100) NULL,
    geolocation_state varchar(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg.order_payments (
    id uuid default uuid_generate_v4(),
    order_id varchar(50) NOT NULL,
    payment_sequential int4 NOT NULL,
    payment_type varchar(50) NOT NULL,
    payment_installments int4 NULL,
    payment_value numeric(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, order_id, payment_sequential)
);

CREATE TABLE stg.order_reviews (
    id uuid default uuid_generate_v4(),
    review_id varchar(100) primary key NOT NULL,
    order_id varchar(50) NOT NULL,
    review_score int4 NULL,
    review_comment_title varchar(255) NULL,
    review_comment_message text NULL,
    review_creation_date timestamp NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE stg.product_category_name_translation (
    id uuid default uuid_generate_v4(),
    product_category_name varchar(255) primary key NOT NULL,
    product_category_name_english varchar(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Foreign Key Constraints
ALTER TABLE stg.order_items
ADD FOREIGN KEY (order_id) REFERENCES stg.orders(order_id);

ALTER TABLE stg.order_items
ADD FOREIGN KEY (product_id) REFERENCES stg.products(product_id);

ALTER TABLE stg.order_items
ADD FOREIGN KEY (seller_id) REFERENCES stg.sellers(seller_id);

ALTER TABLE stg.orders
ADD FOREIGN KEY (customer_id) REFERENCES stg.customers(customer_id);

ALTER TABLE stg.order_payments
ADD FOREIGN KEY (order_id) REFERENCES stg.orders(order_id);

ALTER TABLE stg.order_reviews
ADD FOREIGN KEY (order_id) REFERENCES stg.orders(order_id);

ALTER TABLE stg.products
ADD FOREIGN KEY (category_name) REFERENCES stg.product_category_name_translation(product_category_name);

ALTER TABLE stg.sellers
ADD FOREIGN KEY (seller_zip_code_prefix) REFERENCES stg.geolocation(customer_zip_code_prefix);

ALTER TABLE stg.customers
ADD FOREIGN KEY (customer_zip_code_prefix) REFERENCES stg.geolocation(customer_zip_code_prefix);