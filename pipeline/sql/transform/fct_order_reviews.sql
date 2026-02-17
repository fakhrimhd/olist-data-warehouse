INSERT INTO final.fct_order_reviews (
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_date_id
)
SELECT 
    o.order_id,
    r.review_score,
    r.review_comment_title,
    r.review_comment_message,
    TO_CHAR(r.review_creation_date, 'yyyymmdd')::INT AS review_date_id
FROM stg.order_reviews r
JOIN final.fct_order o ON r.order_id = o.order_nk;