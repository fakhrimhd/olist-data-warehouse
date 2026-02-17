INSERT INTO final.dim_customer (
    customer_nk, 
    customer_unique_id, 
    zip_code, 
    city, 
    state
)
SELECT 
    customer_id AS customer_nk,
    customer_unique_id,
    customer_zip_code_prefix AS zip_code,
    customer_city AS city,
    customer_state AS state
FROM stg.customers
WHERE NOT EXISTS (
    SELECT 1 
    FROM final.dim_customer 
    WHERE final.dim_customer.customer_nk = stg.customers.customer_id
);