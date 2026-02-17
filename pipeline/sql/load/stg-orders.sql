INSERT INTO stg.orders 
    (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, 
    order_delivered_customer_date, order_estimated_delivery_date) 

SELECT
    order_id, 
    customer_id, 
    order_status, 
    order_purchase_timestamp, 
    order_approved_at, 
    order_delivered_carrier_date, 
    order_delivered_customer_date, 
    order_estimated_delivery_date

FROM public.orders

ON CONFLICT(order_id) 
DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    order_status = EXCLUDED.order_status,
    order_purchase_timestamp = EXCLUDED.order_purchase_timestamp,
    order_approved_at = EXCLUDED.order_approved_at,
    order_delivered_carrier_date = EXCLUDED.order_delivered_carrier_date,
    order_delivered_customer_date = EXCLUDED.order_delivered_customer_date,
    order_estimated_delivery_date = EXCLUDED.order_estimated_delivery_date,
    updated_at = CASE WHEN 
                        stg.orders.order_status <> EXCLUDED.order_status
                THEN 
                        CURRENT_TIMESTAMP
                ELSE
                        stg.orders.updated_at
                END;