INSERT INTO final.fct_order_items (
    order_id,
    product_id,
    seller_id,
    shipping_limit_date_id,
    price,
    freight_value
)
SELECT 
    o.order_id,
    p.product_id,
    s.seller_id,
    TO_CHAR(i.shipping_limit_date, 'yyyymmdd')::INT AS shipping_limit_date_id,
    i.price,
    i.freight_value
FROM stg.order_items i
JOIN final.fct_order o ON i.order_id = o.order_nk
JOIN final.dim_product p ON i.product_id = p.product_nk
JOIN final.dim_seller s ON i.seller_id = s.seller_nk;