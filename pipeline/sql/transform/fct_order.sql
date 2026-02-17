INSERT INTO final.fct_order (
    order_nk,
    customer_id,
    purchase_date_id,
    approved_date_id,
    delivered_carrier_date_id,
    delivered_customer_date_id,
    estimated_delivery_date_id,
    status_id
)
SELECT 
    o.order_id AS order_nk,
    c.customer_id,
    TO_CHAR(o.order_purchase_timestamp, 'yyyymmdd')::INT AS purchase_date_id,
    TO_CHAR(o.order_approved_at, 'yyyymmdd')::INT AS approved_date_id,
    TO_CHAR(o.order_delivered_carrier_date, 'yyyymmdd')::INT AS delivered_carrier_date_id,
    TO_CHAR(o.order_delivered_customer_date, 'yyyymmdd')::INT AS delivered_customer_date_id,
    TO_CHAR(o.order_estimated_delivery_date, 'yyyymmdd')::INT AS estimated_delivery_date_id,
    s.status_id
FROM stg.orders o
JOIN final.dim_customer c ON o.customer_id = c.customer_nk
JOIN final.dim_order_status s ON o.order_status = s.status_code
ON CONFLICT (order_nk) 
DO UPDATE SET
    customer_id = EXCLUDED.customer_id,
    purchase_date_id = EXCLUDED.purchase_date_id,
    approved_date_id = EXCLUDED.approved_date_id,
    delivered_carrier_date_id = EXCLUDED.delivered_carrier_date_id,
    delivered_customer_date_id = EXCLUDED.delivered_customer_date_id,
    estimated_delivery_date_id = EXCLUDED.estimated_delivery_date_id,
    status_id = EXCLUDED.status_id,
    updated_at = CURRENT_TIMESTAMP;