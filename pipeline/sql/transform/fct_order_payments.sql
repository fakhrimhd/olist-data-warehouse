INSERT INTO final.fct_order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT 
    o.order_id,
    p.payment_sequential,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM stg.order_payments p
JOIN final.fct_order o ON p.order_id = o.order_nk;