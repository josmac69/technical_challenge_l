-- PostgreSQL - Top 3 performing categories in terms of click-through-rate

SELECT
    category_id,
    SUM(clicks) AS clicks,
    SUM(impressions) AS impressions,
    CASE WHEN SUM(impressions) = 0 THEN 0
    ELSE SUM(clicks)::FLOAT / SUM(impressions) END
    AS click_through_rate
FROM (
    SELECT
        product_id,
        date_trunc('month', date) AS month,
        SUM(CASE WHEN click THEN 1 ELSE 0 END) AS clicks,
        SUM(CASE WHEN click THEN 0 ELSE 1 END) AS impressions
    FROM public.impressions
    GROUP BY
        product_id,
        month
) AS sub
JOIN public.products USING (product_id)
GROUP BY category_id
ORDER BY click_through_rate DESC
LIMIT 3;
