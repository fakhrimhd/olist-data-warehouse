INSERT INTO stg.order_items 
    (order_item_id, order_id, product_id, seller_id, shipping_limit_date, price, freight_value) 

SELECT
    order_item_id, 
    order_id, 
    product_id, 
    seller_id, 
    shipping_limit_date, 
    price, 
    freight_value
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_item_id ORDER BY shipping_limit_date) AS row_num
    FROM public.order_items
) AS subquery
WHERE row_num = 1
AND product_id IN (SELECT product_id FROM products)

ON CONFLICT(order_item_id) 
DO UPDATE SET
    order_id = EXCLUDED.order_id,
    product_id = EXCLUDED.product_id,
    seller_id = EXCLUDED.seller_id,
    shipping_limit_date = EXCLUDED.shipping_limit_date,
    price = EXCLUDED.price,
    freight_value = EXCLUDED.freight_value,
    updated_at = CASE WHEN 
                        stg.order_items.price <> EXCLUDED.price
                        OR stg.order_items.freight_value <> EXCLUDED.freight_value
                THEN 
                        CURRENT_TIMESTAMP
                ELSE
                        stg.order_items.updated_at
                END;