USE mavenfuzzyfactory;

-- Analyzing top traffic sources
select  
	website_sessions.utm_content, 
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id)*100 as session_to_order_conv_rate
from website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
where website_sessions.website_session_id between 1000 AND 2000 
group by website_sessions.utm_content
order by sessions desc;

-- Finding top traffic sources
SELECT utm_source, utm_campaign, http_referer, COUNT(DISTINCT website_session_id) as sessions
FROM website_sessions 
WHERE created_at < "2012-04-12 00:00:00"
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions DESC;

-- Traffic source conversion rate
SELECT COUNT(DISTINCT w.website_session_id) as sessions,
	COUNT(DISTINCT o.order_id) as orders,
    COUNT(DISTINCT o.order_id) * 100 / COUNT(DISTINCT w.website_session_id)  as CVR
FROM website_sessions w
LEFT JOIN orders o
ON
	o.website_session_id = w.website_session_id
WHERE w.created_at < "2012-04-14 00:00:00"
	AND w.utm_source = 'gsearch'
    AND w.utm_campaign = 'nonbrand'
    AND w.http_referer = 'https://www.gsearch.com';
    
    -- date function
    SELECT 
    year(created_at), 
    week(created_at),
    MIN(DATE(created_at)) as week_Start,
	count(DISTINCT website_session_id) as sessions
    FROM website_sessions
    WHERE website_session_id BETWEEN 100000 AND 150000
    GROUP BY 1,2;
    
    -- pivot,case
SELECT primary_product_id ,
		COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS single_item_orders,
        COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) AS two_item_orders,
		COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_id BETWEEN 31000 AND 32000
GROUP BY primary_product_id;

-- gsearch nonbrand trended session volume by week
SELECT  MIN(DATE(created_at)) as week, COUNT(DISTINCT website_session_id) as sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
		AND	utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
		AND http_referer = 'https://www.gsearch.com'
GROUP BY week(created_at) ;

-- conversion rates from sessions to order by device type
SELECT w.device_type, COUNT(DISTINCT w.website_session_id) as sessions, COUNT(DISTINCT o.order_id) as orders,
		COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) as CVR -- session to order conv rate
FROM website_sessions w
LEFT JOIN orders o
ON 
	w.website_session_id = o.website_session_id
WHERE w.created_at < '2012-05-11'
	AND w.utm_source = 'gsearch'
    AND w.utm_campaign = 'nonbrand'
GROUP BY w.device_type;

-- weekly trends for both desktops and mobiles
SELECT  MIN(DATE(created_at)) as Weeks,
		COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) as Desktop_sessions,
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) as Mobile_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-09'
		AND	utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
		AND http_referer = 'https://www.gsearch.com'
GROUP BY WEEK(created_at);
