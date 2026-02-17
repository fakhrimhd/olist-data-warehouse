INSERT INTO stg.order_payments 
    (order_id, payment_sequential, payment_type, payment_installments, payment_value)
SELECT
    order_id, 
    payment_sequential, 
    payment_type, 
    payment_installments, 
    payment_value
FROM public.order_payments
WHERE NOT EXISTS (
    SELECT 1 
    FROM stg.order_payments 
    WHERE stg.order_payments.order_id = public.order_payments.order_id
    AND stg.order_payments.payment_sequential = public.order_payments.payment_sequential
);