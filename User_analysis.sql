USE mavenfuzzyfactory; 
CREATE TEMPORARY TABLE new_sessions1
SELECT
	user_id,
	website_session_id AS new_session_id,
    is_repeat_session,
    created_at
FROM website_sessions
WHERE created_at < "2014-11-01"
	AND website_sessions.created_at >= "2014-01-01"
	AND is_repeat_session =0;

CREATE TEMPORARY TABLE sessions_w_repeats
SELECT
	new_sessions1.user_id,
    new_session_id,
    website_sessions.website_session_id AS repeat_session_id
FROM new_sessions1
LEFT JOIN website_sessions
ON 
	website_sessions.user_id = new_sessions1.user_id
    AND website_sessions.is_repeat_session = 1
    AND new_session_id < website_sessions.website_session_id
	AND website_sessions.created_at < "2014-11-01"
	AND website_sessions.created_at >= "2014-01-01"
;

SELECT 
	repeat_sessions,
    COUNT(DISTINCT user_id) AS users
FROM
(
SELECT 
	user_id,
	COUNT(DISTINCT new_session_id) AS new_sessions,
    COUNT(DISTINCT repeat_session_id) AS repeat_sessions
FROM sessions_w_repeats
GROUP BY 1
ORDER BY 1
) AS user_level
GROUP BY 1;    



-- Time between repeat sessions
CREATE TEMPORARY TABLE sessions_w_repeats_time
SELECT
	new_sessions1.user_id,
    new_session_id,
    website_sessions.website_session_id AS repeat_session_id,
    website_sessions.created_at As repeat_session_created_at
FROM new_sessions1
LEFT JOIN website_sessions
ON 
	website_sessions.user_id = new_sessions1.user_id
    AND website_sessions.is_repeat_session = 1
    AND new_session_id < website_sessions.website_session_id
	AND website_sessions.created_at < "2014-11-01"
	AND website_sessions.created_at >= "2014-01-01";

CREATE TEMPORARY TABLE time_diff
SELECT
	sessions_w_repeats_time.user_id,
    new_session_id,
    website_sessions.created_at,
    MIN(repeat_session_id) AS second_session_id,
    MIN(repeat_session_created_at) AS second_created
FROM sessions_w_repeats_time
LEFT JOIN website_sessions
ON 
	sessions_w_repeats_time.user_id = website_sessions.user_id
GROUP BY sessions_w_repeats_time.user_id
HAVING MIN(repeat_session_id) IS NOT NULL;
    
SELECT 
	AVG(DATEDIFF(second_created,created_at)),
    MIN(DATEDIFF(second_created,created_at)),
    MAX(DATEDIFF(second_created,created_at))
FROM time_diff;


-- Finding new and repeat sessions for different channel group 
SELECT
	utm_source,utm_campaign,http_referer
FROM website_sessions
GROUP BY 2;


SELECT
	CASE
		WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN "organic_search"
        WHEN utm_source IS NOT NULL and utm_campaign = "brand" THEN "paid_brand"
        WHEN utm_source IS NULL AND http_referer IS NULL THEN "direct_type_in"
        WHEN utm_source IS NOT NULL and utm_campaign = "nonbrand" THEN "paid_nonbrand"
        WHEN utm_source = "socialbook" THEN "paid_social"
	END AS channel_group ,
    COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
    COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE created_at >= "2014-01-01"
	AND created_at < "2014-11-05" 
GROUP BY 1
ORDER BY 3;


-- Comparing conversin rates and revenue per session
SELECT
	is_repeat_session,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT order_id)/COUNT(website_sessions.website_session_id) AS conversion_rate,
    SUM(price_usd)/COUNT(website_sessions.website_session_id) AS rev_per_session
FROM website_sessions
LEFT JOIN orders
ON
	website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at >= "2014-01-01"
	AND website_sessions.created_at < "2014-11-08" 
GROUP BY is_repeat_session;
