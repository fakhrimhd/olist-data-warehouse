INSERT INTO final.dim_product (
    product_nk,
    category_name,
    category_name_english,
    name_length,
    description_length,
    photos_qty,
    weight_g,
    length_cm,
    height_cm,
    width_cm
)
SELECT 
    p.product_id AS product_nk,
    p.product_category_name AS category_name,
    t.product_category_name_english AS category_name_english,
    p.product_name_length AS name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM stg.products p
LEFT JOIN stg.product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE NOT EXISTS (
    SELECT 1 
    FROM final.dim_product 
    WHERE final.dim_product.product_nk = p.product_id
);