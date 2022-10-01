USE mavenfuzzyfactory;

-- NEW LANDING PAGE (LANDER-1) IS LAUNCHED WHICH NEEDS TO BE COMPARED WITH THE HOME PAGE WRT BOUNCE RATE

-- STEPS
-- 1. FIND THE FIRST INSTANCE OF LANDER-1 PAGE TO SET ANALYSIS TIMEFRAME
-- 2. CALCULATING THE BOUNCE RATE FOR BOTH PAGES IN THAT TIMEFRAME

SELECT 
		pageview_url,
        MIN(website_pageview_id) AS first_pg,
        MIN(created_at) AS first_created_at
FROM website_pageviews
WHERE pageview_url = '/lander-1';
-- /lander-1 got its traffic starting from 2012-06-19

-- GIVES LANDING PAGE OF EVERY SESSION
CREATE TEMPORARY TABLE first_page_viewed
SELECT 
		website_pageviews.website_session_id,
        website_pageviews.pageview_url,
        MIN(website_pageviews.website_pageview_id) as first_instance
FROM website_pageviews
INNER JOIN website_sessions
ON  
	website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at < '2012-07-28'
	AND website_pageviews.website_pageview_id > 23504
	AND website_pageviews.pageview_url IN ('/lander-1', '/home')
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY website_pageviews.website_session_id;


-- BOUNCED SESSIONS
CREATE TEMPORARY TABLE bounced_id
SELECT 
		first_page_viewed.website_session_id,
        COUNT(website_pageviews.website_pageview_id) AS pages_viewed
FROM first_page_viewed
LEFT JOIN website_pageviews
ON 
	first_page_viewed.website_session_id = website_pageviews.website_session_id
GROUP BY 
		website_pageviews.website_session_id
HAVING pages_viewed = 1;


SELECT 
        first_page_viewed.pageview_url,
        COUNT(DISTINCT first_page_viewed.website_session_id) AS Total_sessions,
        COUNT(DISTINCT bounced_id.website_session_id) AS bounced_sessions,
        COUNT(DISTINCT bounced_id.website_session_id)/COUNT(DISTINCT first_page_viewed.website_session_id) AS bounce_rate
FROM first_page_viewed
LEFT JOIN bounced_id
ON 
	first_page_viewed.website_session_id = bounced_id.website_session_id
GROUP BY 
		first_page_viewed.pageview_url;
        
        
###
-- VOLUMES TRENDED WEEKELY FOR BOTH LANDER PAGES
SELECT 
	MIN(DATE(website_sessions.created_at)) AS week_start,
	COUNT(DISTINCT CASE WHEN website_pageviews.pageview_url = '/home' THEN website_sessions.website_session_id ELSE NULL END) AS vol_home,
	COUNT(DISTINCT CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN website_sessions.website_session_id ELSE NULL END) AS vol_lander
FROM website_sessions
LEFT JOIN website_pageviews
ON 
	website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-06-01' AND '2012-08-31'
	AND website_pageviews.pageview_url IN ('/home','/lander-1')
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(website_sessions.created_at);

-- WEEKLY BOUNCE RATE

-- 1. LANDING PAGE
CREATE TEMPORARY TABLE w_landing_pg
SELECT 
		website_pageviews.website_session_id,
        website_pageviews.pageview_url,
        MIN(website_pageviews.website_pageview_id) as first_pg
FROM website_pageviews
INNER JOIN website_sessions
ON  
	website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_pageviews.created_at BETWEEN '2012-06-01' AND '2012-08-31'
	AND website_pageviews.pageview_url IN ('/lander-1', '/home')
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY website_pageviews.website_session_id;

	
-- 2. BOUNCED SESSIONS
CREATE TEMPORARY TABLE bounced_sessions
SELECT 
		w_landing_pg.website_session_id,
		COUNT(website_pageviews.website_pageview_id) AS pages
FROM w_landing_pg
LEFT JOIN website_pageviews
ON 
		w_landing_pg.website_session_id = website_pageviews.website_session_id
GROUP BY website_pageviews.website_session_id
HAVING pages = 1;

-- 3. Weekly Bouced rates AND VOLUMES
SELECT 
    MIN(DATE(created_at)) as weeks,
    COUNT(DISTINCT bounced_sessions.website_session_id)/COUNT(DISTINCT w_landing_pg.website_session_id) AS bounce_rate,
    COUNT(DISTINCT CASE WHEN w_landing_pg.pageview_url = '/home' THEN w_landing_pg.website_session_id ELSE NULL END) AS vol_home,
	COUNT(DISTINCT CASE WHEN w_landing_pg.pageview_url = '/lander-1' THEN w_landing_pg.website_session_id ELSE NULL END) AS vol_lander
FROM w_landing_pg
LEFT JOIN bounced_sessions
ON 
	w_landing_pg.website_session_id = bounced_sessions.website_session_id
LEFT JOIN website_pageviews
ON 	
	w_landing_pg.website_session_id = website_pageviews.website_session_id
	GROUP BY WEEK(created_at);


SELECT 
	MIN(DATE(website_sessions.created_at)) AS week_start,
    bounced_rates.bounce_rate,
	COUNT(DISTINCT CASE WHEN website_pageviews.pageview_url = '/home' THEN website_sessions.website_session_id ELSE NULL END) AS vol_home,
	COUNT(DISTINCT CASE WHEN website_pageviews.pageview_url = '/lander-1' THEN website_sessions.website_session_id ELSE NULL END) AS vol_lander
FROM website_sessions
LEFT JOIN website_pageviews
ON 
	website_sessions.website_session_id = website_pageviews.website_session_id
LEFT JOIN bounced_rates
ON 
	website_pageviews.created_at = bounced_rates.created_at
WHERE website_sessions.created_at BETWEEN '2012-06-01' AND '2012-08-31'
	AND website_pageviews.pageview_url IN ('/home','/lander-1')
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(website_sessions.created_at);