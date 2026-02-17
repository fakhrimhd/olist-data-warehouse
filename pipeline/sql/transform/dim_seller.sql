INSERT INTO final.dim_seller (
    seller_nk,
    zip_code,
    city,
    state
)
SELECT 
    seller_id AS seller_nk,
    seller_zip_code_prefix AS zip_code,
    seller_city AS city,
    seller_state AS state
FROM stg.sellers
WHERE NOT EXISTS (
    SELECT 1 
    FROM final.dim_seller 
    WHERE final.dim_seller.seller_nk = stg.sellers.seller_id
);