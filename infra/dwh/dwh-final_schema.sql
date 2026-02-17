CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE SCHEMA IF NOT EXISTS final AUTHORIZATION postgres;

-- Dimension Tables
CREATE TABLE final.dim_customer(
    customer_id uuid primary key default uuid_generate_v4(),
    customer_nk varchar(100) NOT NULL,
    customer_unique_id varchar(100) NOT NULL,
    zip_code varchar(20),
    city varchar(100),
    state varchar(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE final.dim_product(
    product_id uuid primary key default uuid_generate_v4(),
    product_nk varchar(100) NOT NULL,
    category_name varchar(255),
    category_name_english varchar(255),
    name_length int,
    description_length int,
    photos_qty int,
    weight_g int,
    length_cm int,
    height_cm int,
    width_cm int,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE final.dim_seller(
    seller_id uuid primary key default uuid_generate_v4(),
    seller_nk varchar(100) NOT NULL,
    zip_code varchar(20),
    city varchar(100),
    state varchar(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE final.dim_date(
    date_id INT NOT NULL primary KEY,
    date_actual DATE NOT NULL,
    day_suffix VARCHAR(4) NOT NULL,
    day_name VARCHAR(9) NOT NULL,
    day_of_year INT NOT NULL,
    week_of_month INT NOT NULL,
    week_of_year INT NOT NULL,
    week_of_year_iso CHAR(10) NOT NULL,
    month_actual INT NOT NULL,
    month_name VARCHAR(9) NOT NULL,
    month_name_abbreviated CHAR(3) NOT NULL,
    quarter_actual INT NOT NULL,
    quarter_name VARCHAR(9) NOT NULL,
    year_actual INT NOT NULL,
    first_day_of_week DATE NOT NULL,
    last_day_of_week DATE NOT NULL,
    first_day_of_month DATE NOT NULL,
    last_day_of_month DATE NOT NULL,
    first_day_of_quarter DATE NOT NULL,
    last_day_of_quarter DATE NOT NULL,
    first_day_of_year DATE NOT NULL,
    last_day_of_year DATE NOT NULL,
    mmyyyy CHAR(6) NOT NULL,
    mmddyyyy CHAR(10) NOT NULL,
    weekend_indr VARCHAR(20) NOT NULL
);

CREATE TABLE final.dim_order_status(
    status_id uuid primary key default uuid_generate_v4(),
    status_code varchar(50) NOT NULL,
    status_description varchar(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fact Tables
CREATE TABLE final.fct_order(
    order_id uuid PRIMARY KEY default uuid_generate_v4(),
    order_nk varchar(50) NOT NULL,
    customer_id uuid references final.dim_customer(customer_id),
    purchase_date_id int references final.dim_date(date_id),
    approved_date_id int references final.dim_date(date_id),
    delivered_carrier_date_id int references final.dim_date(date_id),
    delivered_customer_date_id int references final.dim_date(date_id),
    estimated_delivery_date_id int references final.dim_date(date_id),
    status_id uuid references final.dim_order_status(status_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE final.fct_order_items(
    order_item_id uuid default uuid_generate_v4(),
    order_id uuid references final.fct_order(order_id),  -- Now valid because fct_order.order_id is primary key
    product_id uuid references final.dim_product(product_id),
    seller_id uuid references final.dim_seller(seller_id),
    shipping_limit_date_id int references final.dim_date(date_id),
    price numeric(10, 2),
    freight_value numeric(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_item_id)
);

CREATE TABLE final.fct_order_payments(
    payment_id uuid default uuid_generate_v4(),
    order_id uuid references final.fct_order(order_id),
    payment_sequential int,
    payment_type varchar(50),
    payment_installments int,
    payment_value numeric(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE final.fct_order_reviews(
    review_id uuid default uuid_generate_v4(),
    order_id uuid references final.fct_order(order_id),
    review_score int,
    review_comment_title varchar(255),
    review_comment_message text,
    review_date_id int references final.dim_date(date_id),
    answer_date_id int references final.dim_date(date_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Populate Date Dimension
INSERT INTO final.dim_date
SELECT TO_CHAR(datum, 'yyyymmdd')::INT AS date_id,
       datum AS date_actual,
       TO_CHAR(datum, 'fmDDth') AS day_suffix,
       TO_CHAR(datum, 'TMDay') AS day_name,
       EXTRACT(DOY FROM datum) AS day_of_year,
       TO_CHAR(datum, 'W')::INT AS week_of_month,
       EXTRACT(WEEK FROM datum) AS week_of_year,
       EXTRACT(ISOYEAR FROM datum) || TO_CHAR(datum, '"-W"IW') AS week_of_year_iso,
       EXTRACT(MONTH FROM datum) AS month_actual,
       TO_CHAR(datum, 'TMMonth') AS month_name,
       TO_CHAR(datum, 'Mon') AS month_name_abbreviated,
       EXTRACT(QUARTER FROM datum) AS quarter_actual,
       CASE
           WHEN EXTRACT(QUARTER FROM datum) = 1 THEN 'First'
           WHEN EXTRACT(QUARTER FROM datum) = 2 THEN 'Second'
           WHEN EXTRACT(QUARTER FROM datum) = 3 THEN 'Third'
           WHEN EXTRACT(QUARTER FROM datum) = 4 THEN 'Fourth'
           END AS quarter_name,
       EXTRACT(YEAR FROM datum) AS year_actual,
       datum + (1 - EXTRACT(ISODOW FROM datum))::INT AS first_day_of_week,
       datum + (7 - EXTRACT(ISODOW FROM datum))::INT AS last_day_of_week,
       datum + (1 - EXTRACT(DAY FROM datum))::INT AS first_day_of_month,
       (DATE_TRUNC('MONTH', datum) + INTERVAL '1 MONTH - 1 day')::DATE AS last_day_of_month,
       DATE_TRUNC('quarter', datum)::DATE AS first_day_of_quarter,
       (DATE_TRUNC('quarter', datum) + INTERVAL '3 MONTH - 1 day')::DATE AS last_day_of_quarter,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-01-01', 'YYYY-MM-DD') AS first_day_of_year,
       TO_DATE(EXTRACT(YEAR FROM datum) || '-12-31', 'YYYY-MM-DD') AS last_day_of_year,
       TO_CHAR(datum, 'mmyyyy') AS mmyyyy,
       TO_CHAR(datum, 'mmddyyyy') AS mmddyyyy,
       CASE
           WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN 'weekend'
           ELSE 'weekday'
           END AS weekend_indr
FROM (SELECT '1998-01-01'::DATE + SEQUENCE.DAY AS datum
      FROM GENERATE_SERIES(0, 29219) AS SEQUENCE (DAY)
      GROUP BY SEQUENCE.DAY) DQ
ORDER BY 1;

-- Populate Order Status Dimension
INSERT INTO final.dim_order_status (status_code, status_description)
VALUES 
    ('created', 'Order created but not yet approved'),
    ('approved', 'Payment approved'),
    ('processing', 'Order being processed'),
    ('shipped', 'Order shipped to carrier'),
    ('delivered', 'Order delivered to customer'),
    ('canceled', 'Order canceled'),
    ('unavailable', 'Product unavailable');

-- Add Unique Constraints
ALTER TABLE final.fct_order
ADD CONSTRAINT fct_order_unique UNIQUE (order_nk);

ALTER TABLE final.fct_order_items
ADD CONSTRAINT fct_order_items_unique UNIQUE (order_item_id);

ALTER TABLE final.fct_order_payments
ADD CONSTRAINT fct_order_payments_unique UNIQUE (payment_id);

ALTER TABLE final.fct_order_reviews
ADD CONSTRAINT fct_order_reviews_unique UNIQUE (review_id);