USE mavenfuzzyfactory;

-- 1. Weekly and monthly volume trends to search for seasonality
SELECT
	YEAR(website_sessions.created_at) as yr,
    MONTH(website_sessions.created_at) as mon,
    MONTHNAME(website_sessions.created_at) as mon,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON 
	website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2013-01-01"
GROUP BY 1,2;

SELECT
	MIN(DATE(website_sessions.created_at)) as WK,
    MIN(DATE(website_sessions.created_at)) as WK,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON 
	website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2013-01-01"
GROUP BY WEEK(website_sessions.created_at);


-- 2. Analyzing the sessions on hourly basis for weeks of days for time period of 2 months
SELECT
	hr,
    ROUND(AVG(CASE WHEN wkday=0 THEN sessions ELSE NULL END),1) AS MON,
    ROUND(AVG(CASE WHEN wkday=1 THEN sessions ELSE NULL END),1) AS TUES,
    ROUND(AVG(CASE WHEN wkday=2 THEN sessions ELSE NULL END),1) AS WED,
    ROUND(AVG(CASE WHEN wkday=3 THEN sessions ELSE NULL END),1) AS THURS,
    ROUND(AVG(CASE WHEN wkday=4 THEN sessions ELSE NULL END),1) AS FRI,
    ROUND(AVG(CASE WHEN wkday=5 THEN sessions ELSE NULL END),1) AS SAT,
    ROUND(AVG(CASE WHEN wkday=6 THEN sessions ELSE NULL END),1) AS SUN
FROM 
(
SELECT 
	DATE(created_at) AS created_date, 
    weekday(created_at) AS wkday,
    HOUR(created_at) AS hr,
    COUNT(DISTINCT website_session_id) as sessions
FROM website_sessions
WHERE 
	created_at < "2013-11-16"
	AND created_at > "2013-09-14"
GROUP BY DATE(created_at), weekday(created_at),HOUR(created_at)
) AS daily_hourly_sessions
GROUP BY hr
