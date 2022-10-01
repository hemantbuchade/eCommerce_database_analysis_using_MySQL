USE mavenfuzzyfactory;

-- '/lander-1','/products','/the-original-mr-fuzzy', '/cart','/shipping','/billing','/thank-you-for-your-order'

-- 1. SESSIONS HAVING FIRST PAGE LANDER-1
CREATE TEMPORARY TABLE lander1_page
SELECT 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url,
    MIN(website_pageviews.website_pageview_id) AS lander
FROM website_pageviews
LEFT JOIN website_sessions
ON 
	website_pageviews.website_session_id = website_sessions.website_session_id
WHERE pageview_url = '/lander-1'
		AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
        AND website_pageviews.created_at BETWEEN '2012-08-05' AND '2012-09-05'
GROUP BY website_pageviews.website_session_id;
-- select * from lander1_page;

-- 2. BASIC FUNNEL
-- (like one hot encoding)
CREATE TEMPORARY TABLE conversion_funnel
SELECT 
		lander1_page.website_session_id,
        website_pageviews.pageview_url,
        CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS to_lander_1,
        CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS to_products,
        CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_the_original_mr_fuzzy,
        CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
        CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
        CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
        CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_for_your_order
FROM lander1_page
LEFT JOIN website_pageviews
ON 
	lander1_page.website_session_id = website_pageviews.website_session_id
WHERE created_at BETWEEN '2012-08-05' AND '2012-09-05';
--select * from conversion_funnel;

CREATE TEMPORARY TABLE merged
SELECT 
		conversion_funnel.website_session_id,
		MAX(to_lander_1) as to_lander_1,
        MAX(to_products) as to_products,
        MAX(to_the_original_mr_fuzzy) as to_the_original_mr_fuzzy,
        MAX(cart) as to_cart,
        MAX(shipping) as to_shipping,
        MAX(billing) as to_billing,
        MAX(thank_you_for_your_order) as to_thank_you_for_your_order
FROM conversion_funnel
GROUP BY conversion_funnel.website_session_id;
-- select * from merged;

SELECT
	COUNT(DISTINCT website_session_id) AS Total_sessions,
    
    COUNT(DISTINCT CASE WHEN to_products = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_lander_1 = 1 THEN website_session_id ELSE NULL END) AS lander_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_the_original_mr_fuzzy = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_products = 1 THEN website_session_id ELSE NULL END) AS products_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_the_original_mr_fuzzy = 1 THEN website_session_id ELSE NULL END) AS the_original_mr_fuzzy_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_cart = 1 THEN website_session_id ELSE NULL END) AS cart_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_shipping = 1 THEN website_session_id ELSE NULL END) AS shipping_clickthrough_rate,
    
    COUNT(DISTINCT CASE WHEN to_thank_you_for_your_order = 1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_billing = 1 THEN website_session_id ELSE NULL END) AS billing_clickthrough_rate
FROM merged;

#######################################################################################################

-- ANALYZING BILLING-2 PAGE 
-- 1.FIND THE FIRST TIME THIS PAGE WAS SEEN
SELECT 
	MIN(website_pageview_id),
    DATE(created_at)
	FROM website_pageviews
	WHERE pageview_url = "/billing-2"
    group by website_pageview_id;

-- /billing-2 page was started from 53550 pageview_id at 10th Sept

-- 2. Find session, orders and rate of /billing and /billing-2 pages to order
SELECT
	pageview_url,
	COUNT(website_pageviews.website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id)/COUNT(website_pageviews.website_session_id) AS billing_to_order_rt  
FROM website_pageviews
LEFT JOIN orders
		ON website_pageviews.website_session_id = orders.website_session_id
WHERE pageview_url in ("/billing","/billing-2")
		AND website_pageviews.created_at < "2012-11-10"
        AND website_pageviews.website_pageview_id > 53550
GROUP BY pageview_url;