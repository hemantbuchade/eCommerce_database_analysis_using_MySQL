USE mavenfuzzyfactory; 

-- 1. Overall session and order and volume by quarter
SELECT
	YEAR(website_sessions.created_at) AS YR,
	QUARTER(website_sessions.created_at) AS QTR,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON
	website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2;


-- 2. Conversion rates, revenue per order and revenue per session by quarter
SELECT
	YEAR(website_sessions.created_at) AS YR,
	QUARTER(website_sessions.created_at) AS QTR,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_sessions.website_session_id)  AS conversion_rate,
    
    SUM(price_usd)/COUNT(DISTINCT order_id) AS revenue_per_order,
    
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id)  AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON
	website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2;


-- 3. Orders from all channels quarterly
SELECT
	YEAR(website_sessions.created_at) AS YR,
	QUARTER(website_sessions.created_at) AS QTR,
    COUNT(CASE WHEN utm_source = "gsearch" AND utm_campaign="nonbrand" THEN order_id ELSE NULL END) AS gsearch_nonbrand_orders,
    COUNT(CASE WHEN utm_source = "bsearch" AND utm_campaign="nonbrand" THEN order_id ELSE NULL END) AS bsearch_nonbrand_orders,
	COUNT(CASE WHEN utm_campaign="brand" THEN order_id ELSE NULL END) AS brand_orders,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) AS organic_search_orders,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) AS direct_type_in_orders
FROM website_sessions
LEFT JOIN orders
ON
	website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2;
-- The organic and direct type in traffics has seen significant increase in orders placed while the paid bsearch nonbrand is still not 
-- not converting to more orders probably due to its low marketing budget

-- 4. Conversion rates for channels
SELECT
	YEAR(website_sessions.created_at) AS YR,
	QUARTER(website_sessions.created_at) AS QTR,
    
    COUNT(CASE WHEN utm_source = "gsearch" AND utm_campaign="nonbrand" THEN order_id ELSE NULL END)/
    COUNT(CASE WHEN utm_source = "gsearch" AND utm_campaign="nonbrand" THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv,
    
    COUNT(CASE WHEN utm_source = "bsearch" AND utm_campaign="nonbrand" THEN order_id ELSE NULL END)/
    COUNT(CASE WHEN utm_source = "bsearch" AND utm_campaign="nonbrand" THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv,
    
	COUNT(CASE WHEN utm_campaign="brand" THEN order_id ELSE NULL END)/
    COUNT(CASE WHEN utm_campaign="brand" THEN website_sessions.website_session_id ELSE NULL END) AS brand_conv,
    
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END)/
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_conv,
    
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END)/
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_conv

FROM website_sessions
LEFT JOIN orders
ON
	website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2;

-- When 2nd product was launched during 1st qtr of 2013 the rise in conversion rate was significant
-- Overall paid brand ads had high conversion rate considering the fact that customers already knew about the brand and products and
-- came to the website to buy via paid brand ads


#####################################################################################################################################################################################


-- 5. Monthly revenue, margin, total sales and revenue by products
SELECT
	YEAR(order_items.created_at) AS Yr,
    MONTH(order_items.created_at) AS Mon,
	
    SUM(CASE WHEN order_items.product_id=1 THEN price_usd ELSE NULL END) AS mrfuzzy_revenue,
    SUM(CASE WHEN order_items.product_id=1 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_margin,
    COUNT(CASE WHEN order_items.product_id=1 THEN order_id ELSE NULL END)
FROM order_items
LEFT JOIN products
ON
	order_items.product_id = products.product_id