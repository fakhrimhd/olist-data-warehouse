INSERT INTO stg.order_reviews 
    (review_id, order_id, review_score, review_comment_title, review_comment_message, review_creation_date) 

SELECT
    review_id, 
    order_id, 
    review_score, 
    review_comment_title, 
    review_comment_message, 
    review_creation_date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_creation_date) AS row_num
    FROM public.order_reviews
) AS subquery
WHERE row_num = 1

ON CONFLICT(review_id) 
DO UPDATE SET
    order_id = EXCLUDED.order_id,
    review_score = EXCLUDED.review_score,
    review_comment_title = EXCLUDED.review_comment_title,
    review_comment_message = EXCLUDED.review_comment_message,
    review_creation_date = EXCLUDED.review_creation_date,
    updated_at = CASE WHEN 
                        stg.order_reviews.review_score <> EXCLUDED.review_score
                THEN 
                        CURRENT_TIMESTAMP
                ELSE
                        stg.order_reviews.updated_at
                END;