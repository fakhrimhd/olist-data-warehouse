
CREATE TABLE public.geolocation (
	geolocation_zip_code_prefix int4 NOT NULL,
	geolocation_lat float4 NULL,
	geolocation_lng float4 NULL,
	geolocation_city text NULL,
	geolocation_state text NULL,
	CONSTRAINT geolocation_pk PRIMARY KEY (geolocation_zip_code_prefix)
);


CREATE TABLE public.product_category_name_translation (
	product_category_name text NOT NULL,
	product_category_name_english text NULL,
	CONSTRAINT pk_product_category_name_translation PRIMARY KEY (product_category_name)
);

CREATE TABLE public.customers (
	customer_id text NOT NULL,
	customer_unique_id text NULL,
	customer_zip_code_prefix int4 NULL,
	customer_city text NULL,
	customer_state text NULL,
	CONSTRAINT pk_customers PRIMARY KEY (customer_id),
	CONSTRAINT fk_cyst_geo_prefix FOREIGN KEY (customer_zip_code_prefix) REFERENCES public.geolocation(geolocation_zip_code_prefix)
);


CREATE TABLE public.orders (
	order_id text NOT NULL,
	customer_id text NULL,
	order_status text NULL,
	order_purchase_timestamp TIMESTAMP NULL,
	order_approved_at timestamp NULL,
	order_delivered_carrier_date timestamp NULL,
	order_delivered_customer_date timestamp NULL,
	order_estimated_delivery_date date NULL,
	CONSTRAINT pk_orders PRIMARY KEY (order_id),
	CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id)
);


CREATE TABLE public.products (
	product_id text NOT NULL,
	product_category_name text NULL,
	product_name_length float4 NULL,
	product_description_length float4 NULL,
	product_photos_qty float4 NULL,
	product_weight_g float4 NULL,
	product_length_cm float4 NULL,
	product_height_cm float4 NULL,
	product_width_cm float4 NULL,
	CONSTRAINT pk_products PRIMARY KEY (product_id),
	CONSTRAINT fk_products_product_category FOREIGN KEY (product_category_name) REFERENCES public.product_category_name_translation(product_category_name)
);


CREATE TABLE public.sellers (
	seller_id text NOT NULL,
	seller_zip_code_prefix int4 NULL,
	seller_city text NULL,
	seller_state text NULL,
	CONSTRAINT pk_sellers PRIMARY KEY (seller_id),
	CONSTRAINT fk_seller_geo_prefix FOREIGN KEY (seller_zip_code_prefix) REFERENCES public.geolocation(geolocation_zip_code_prefix)
);


CREATE TABLE public.order_items (
	order_id text NOT NULL,
	order_item_id int4 NOT NULL,
	product_id text NULL,
	seller_id text NULL,
	shipping_limit_date timestamp NULL,
	price float4 NULL,
	freight_value float4 NULL,
	CONSTRAINT pk_order_items PRIMARY KEY (order_id, order_item_id),
	CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id) REFERENCES public.orders(order_id)
	--CONSTRAINT fk_order_items_products FOREIGN KEY (product_id) REFERENCES public.products(product_id),
	--CONSTRAINT fk_order_items_sellers FOREIGN KEY (seller_id) REFERENCES public.sellers(seller_id)
);


CREATE TABLE public.order_payments (
	order_id text NOT NULL,
	payment_sequential int4 NOT NULL,
	payment_type text NULL,
	payment_installments int4 NULL,
	payment_value float4 NULL,
	CONSTRAINT pk_order_payments PRIMARY KEY (order_id, payment_sequential),
	CONSTRAINT fk_order_payments_orders FOREIGN KEY (order_id) REFERENCES public.orders(order_id)
);


CREATE TABLE public.order_reviews (
	review_id text NOT NULL,
	order_id text NOT NULL,
	review_score int4 NULL,
	review_comment_title text NULL,
	review_comment_message text NULL,
	review_creation_date timestamp NULL,
	CONSTRAINT pk_order_reviews PRIMARY KEY (review_id, order_id),
	CONSTRAINT fk_order_reviews_orders FOREIGN KEY (order_id) REFERENCES public.orders(order_id)
);