-- PostgreSQL - Click-through-rate by price tier

SELECT
    price_tier,
    COUNT(product_id) as products,
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
        SUM(CASE WHEN click THEN 0 ELSE 1 END) AS impressions,
        CASE
            WHEN price BETWEEN 0 AND 5 THEN '1. 0-5'
            WHEN price BETWEEN 6 AND 10 THEN '2. 5-10'
            WHEN price BETWEEN 11 AND 15 THEN '3. 10-15'
            ELSE '4. >15'
        END AS price_tier
    FROM public.impressions
    JOIN public.products USING (product_id)
    GROUP BY
        product_id,
        month,
        price_tier
) AS sub
GROUP BY price_tier
ORDER BY price_tier;
