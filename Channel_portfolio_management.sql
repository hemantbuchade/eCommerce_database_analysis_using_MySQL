USE mavenfuzzyfactory;

-- Weekly trends of paid search channels

SELECT 
	MIN(DATE(created_at)) AS Weeks,
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE 
	utm_campaign = "nonbrand"
    AND created_at BETWEEN "2012-08-22" AND "2012-11-29"
GROUP BY WEEK(created_at);


-- 2. Comparing channels by % of traffic coming from mobile
SELECT 
	utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END ) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = "mobile" THEN website_session_id ELSE NULL END )/COUNT(DISTINCT website_session_id) AS pct_mobile
FROM website_sessions
WHERE 
	utm_campaign = "nonbrand"
    AND created_at BETWEEN "2012-08-22" AND "2012-11-30"
GROUP BY utm_source;


-- 3. Should the bid for gsearch and bsearch be the same?
-- can evaluate on basis of conversion rates and device types used
SELECT 
	device_type,
	utm_source,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/ COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate
FROM website_sessions
LEFT JOIN orders
ON
	website_sessions.website_session_id = orders.website_session_id
WHERE 
	utm_campaign = "nonbrand"
    AND website_sessions.created_at > "2012-08-22" 
    AND website_sessions.created_at < "2012-09-19"
GROUP BY device_type,utm_source;
-- bid down bsearch based on its under performance


-- 4. Weekly sessions for gsearch and bsearch by device type
-- to understand the impact of bid down on bsearch
-- bsearch is analysed as % of gsearch to nullify any effect due to seasonality 
-- as a effect of seasonality gsearch dropped a bit therefore drop in bsearch was due to bid down or seasonality
-- was better understood with the help of % of bsearch wrt gsearch on desktop
-- on contrary in mobile devices bsearch is not much affected with bid down and vol there is less sensitive to bid changes
SELECT
	MIN(DATE(created_at)) AS Weeks,
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) AS gsearch_desktop_sessions,
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) AS bsearch_desktop_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type = "desktop" THEN website_session_id ELSE NULL END) AS b_pct_g_dtopsessions,
    
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) AS gsearch_mobile_sessions,
	COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) AS bsearch_mobile_sessions,
    
    COUNT(DISTINCT CASE WHEN utm_source="bsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN utm_source="gsearch" AND device_type = "mobile" THEN website_session_id ELSE NULL END) AS b_pct_g_mobsessions
FROM website_sessions
WHERE 
	utm_campaign = "nonbrand"
    AND website_sessions.created_at > "2012-11-04" 
    AND website_sessions.created_at < "2012-12-23"
GROUP BY WEEK(created_at);


####################################################################################################################
-- ANALYZING FREE CHANNELS

-- Monthly trends of non-brand,brand,direct type-in and organic search traffic and all of them as % of non brand
SELECT 
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mnt,
	COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id ELSE NULL END) AS nonbrand,
	COUNT(DISTINCT CASE WHEN utm_campaign="brand" THEN website_session_id ELSE NULL END) AS brand,
    
    COUNT(DISTINCT CASE WHEN utm_campaign="brand" THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id ELSE NULL END) AS brand_pct_nonbrand,
    
    COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct,

	COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id ELSE NULL END) AS direct_pct_nonbrand,

	COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic,

	COUNT(DISTINCT CASE WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) /
    COUNT(DISTINCT CASE WHEN utm_campaign="nonbrand" THEN website_session_id ELSE NULL END) AS organic_pct_nonbrand
    
FROM website_sessions
WHERE created_at < "2012-12-23"
GROUP BY YEAR(created_at),MONTH(created_at);


SELECT 
	CASE
		WHEN utm_campaign = "nonbrand" THEN "paid_nonbrand"
        WHEN utm_campaign = "brand" THEN "paid_brand"
        WHEN utm_source IS NULL AND http_referer IN ("https://www.gsearch.com","https://www.bsearch.com") THEN "organic_search"
        WHEN utm_source IS NULL AND http_referer IS NULL THEN "direct_type_in"
        END AS channel_group,
	utm_campaign,
    utm_source,
    utm_content,
    http_referer
FROM website_sessions
GROUP BY 1;