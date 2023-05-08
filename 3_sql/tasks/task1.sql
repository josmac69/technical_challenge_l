-- PostgreSQL code - Click-through-rate of each product by month

SELECT
    product_id,
    date_trunc('month', date) AS month,
    SUM(CASE WHEN click THEN 1 ELSE 0 END) AS clicks,
    SUM(CASE WHEN click THEN 0 ELSE 1 END) AS impressions,
    CASE WHEN SUM(CASE WHEN click THEN 0 ELSE 1 END) = 0 THEN 0
    ELSE SUM(CASE WHEN click THEN 1 ELSE 0 END)::FLOAT / SUM(CASE WHEN click THEN 0 ELSE 1 END) END
    AS click_through_rate
FROM public.impressions
GROUP BY
    product_id,
    month;

