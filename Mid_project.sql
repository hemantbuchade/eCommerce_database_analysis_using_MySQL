USE mavenfuzzyfactory;

-- 1. Monthly trends for gsearch sessions and orders 
SELECT 
	MONTH(website_sessions.created_at) AS Month,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE 
	utm_source = "gsearch"
    AND website_sessions.created_at < "2012-11-27" 
GROUP BY MONTH(website_sessions.created_at);


-- 2. Splitting brand and nonbrand campaigns of Gsearch
SELECT 
	MONTH(website_sessions.created_at) AS Month,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "brand" THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "brand" THEN order_id ELSE NULL END) AS brand_orders,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "nonbrand" THEN website_sessions.website_session_id ELSE NULL END) AS non_brand_sessions,
    COUNT(DISTINCT CASE WHEN website_sessions.utm_campaign = "nonbrand" THEN order_id ELSE NULL END) AS non_brand_orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE 
	utm_source = "gsearch"
    AND website_sessions.created_at < "2012-11-27" 
GROUP BY MONTH(website_sessions.created_at);


-- 3. Gsearch nonbrand campaign monthly trend split by device type
SELECT 
	MONTH(website_sessions.created_at) AS Month,
	COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_sessions.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN order_id ELSE NULL END) AS mobile_orders,
    COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN website_sessions.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "desktop" THEN order_id ELSE NULL END) AS desktop_orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE 
	utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
    AND website_sessions.created_at < "2012-11-27" 
GROUP BY MONTH(website_sessions.created_at);

-- below query is imp 
-- 4. Monthly trends from gsearch and other channels 
SELECT 
	MONTH(website_sessions.created_at) AS Month,
    COUNT(DISTINCT CASE WHEN utm_source = "gsearch" THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = "bsearch" THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_sessions,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE 
	website_sessions.created_at < "2012-11-27" 
GROUP BY MONTH(website_sessions.created_at);


-- 5. Monthly conversion rate
SELECT 
	MONTH(website_sessions.created_at) AS Month,
    MONTHNAME(website_sessions.created_at) AS Name_of_month,
	COUNT(DISTINCT order_id)/COUNT(DISTINCT website_sessions.website_session_id)*100 AS Conversion_rate
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
WHERE 
     website_sessions.created_at < "2012-11-27" 
GROUP BY MONTH(website_sessions.created_at), MONTHNAME(website_sessions.created_at)
LIMIT 8;


-- 6.   
SELECT 
	website_pageviews.pageview_url,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_sessions.website_session_id ) *100 AS conversion_rate
FROM website_sessions
LEFT JOIN website_pageviews
ON  
	website_sessions.website_session_id = website_pageviews.website_session_id
LEFT JOIN orders
ON 
	website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-07-28'
	AND website_pageviews.website_pageview_id >= 23504
	AND website_pageviews.pageview_url IN ('/home','/lander-1')
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
-- GROUP BY WEEK website_pageviews.pageview_url;

SELECT
	MONTH(website_sessions.created_at) AS Month,
	COUNT(DISTINCT CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN website_sessions.website_session_id ELSE NULL END) AS lander_sessions,
    COUNT(DISTINCT CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN order_id ELSE NULL END) as lander_orders
FROM website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
    AND website_sessions.created_at < "2012-11-27" 
    AND website_sessions.created_at > "2012-06-19" 
GROUP BY MONTH website_pageviews.pageview_url  ;


-- 7. Conversion funnel for home and lander page
CREATE TEMPORARY TABLE lpg1
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageview_id) as landing_page,
    pageview_url,
    COUNT(website_pageview_id) as pages_visited
FROM website_pageviews
LEFT JOIN website_sessions
ON 
	website_pageviews.website_session_id = website_sessions.website_session_id
WHERE 
	website_pageviews.created_at BETWEEN "2012-06-19" AND "2012-07-28"
    AND utm_source = "gsearch"
    AND utm_campaign = "nonbrand"
GROUP BY website_pageviews.website_session_id;

CREATE TEMPORARY TABLE conversion_funnel11
SELECT 
	conv.website_session_id,
    conv.pageview_url,
    MAX(to_home) as to_home,
    MAX(to_lander_1) as to_lander_1,
	MAX(to_products) as to_products,
	MAX(to_the_original_mr_fuzzy) as to_the_original_mr_fuzzy,
	MAX(cart) as to_cart,
	MAX(shipping) as to_shipping,
	MAX(billing) as to_billing,
	MAX(thank_you_for_your_order) as to_thank_you_for_your_order
FROM
(SELECT 
	lpg1.website_session_id,
    lpg1.pageview_url,
    CASE WHEN website_pageviews.pageview_url = '/home' THEN 1 ELSE 0 END AS to_home,
    CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS to_lander_1,
	CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS to_products,
	CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_the_original_mr_fuzzy,
	CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
	CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
	CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
	CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_for_your_order
FROM lpg1
LEFT JOIN website_pageviews
ON 
	lpg1.website_session_id = website_pageviews.website_session_id) AS conv
GROUP BY conv.website_session_id;

SELECT 
	pageview_url,
	COUNT(DISTINCT website_session_id) AS Total_sessions,
    
    COUNT(DISTINCT CASE WHEN to_products = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT website_session_id) AS lander_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_the_original_mr_fuzzy = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_products = 1 THEN website_session_id ELSE NULL END) AS products_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_the_original_mr_fuzzy = 1 THEN website_session_id ELSE NULL END) AS original_mr_fuzzy_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END) AS cart_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END) AS shipping_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_thank_you_for_your_order = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END) AS billing_clickthrough_rate
 
FROM conversion_funnel11
GROUP BY pageview_url
LIMIT 2;

 
-- 8. Impact of new billing page on revenue
SELECT 
    website_pageviews.pageview_url AS billing_version,
    COUNT(website_pageviews.website_session_id) AS sessions,
    SUM(price_usd)/COUNT(website_pageviews.website_session_id) AS revenue_per_session
FROM website_pageviews
LEFT JOIN orders
ON 
	website_pageviews.website_session_id = orders.website_session_id
WHERE
	website_pageviews.created_at > "2012-09-10"
    AND website_pageviews.created_at < "2012-11-10"
    AND website_pageviews.pageview_url in ("/billing","/billing-2")
GROUP BY website_pageviews.pageview_url;

-- $22.83 revenue for billing
-- $31.34 revenue for billing-2 per session
-- Lift: $8.51 per billing page view

SELECT 
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews
WHERE
	website_pageviews.created_at > "2012-10-27"
    AND website_pageviews.created_at < "2012-11-27"
    AND website_pageviews.pageview_url in ("/billing","/billing-2");

-- 1193 billing session in last month
-- value of billing test 1193* $8.51 over past month