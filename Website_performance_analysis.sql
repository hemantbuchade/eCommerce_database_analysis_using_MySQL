use mavenfuzzyfactory;

-- Finding top pages
SELECT pageview_url,
		COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY pageview_url
ORDER BY pvs DESC;

-- TOP ENTRY PAGES
CREATE TEMPORARY TABLE first_pageview
SELECT
		website_session_id, 
		MIN(website_pageview_id) as first_viewed_page_id
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY website_session_id;
-- select * from first_pageview;


SELECT 
        website_pageviews.pageview_url as Landing_page,
        count(distinct first_pageview.website_session_id)
FROM first_pageview
LEFT JOIN website_pageviews
ON 
	first_pageview.first_viewed_page_id = website_pageviews.website_pageview_id
group by website_pageviews.pageview_url;


-- SAME RESULT WITHOUT THE USE OF TEMP TABLE
SELECT website_session_id, pageview_url
FROM website_pageviews
WHERE website_pageview_id < 1000
	AND website_pageview_id in (select min(website_pageview_id) from website_pageviews group by website_session_id);

-- most viewed website pages ranked by session volume
SELECT 
	pageview_url,
	COUNT(distinct website_session_id) AS session_volume
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY session_volume DESC;

-- all entry pages and order them on entry volume
CREATE TEMPORARY TABLE landing_page
SELECT website_session_id,
	MIN(website_pageview_id) as first_pg
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;
-- select * from landing_page 

SELECT wp.pageview_url, COUNT(lp.website_session_id) as first_pg_session_volume
FROM landing_page lp
LEFT JOIN website_pageviews wp
ON 
	lp.first_pg = wp.website_pageview_id 
WHERE created_at < '2012-06-12'
GROUP BY wp.pageview_url;
-- FOR ALL SESSIONS THE LANDING PAGE IS HOMEPAGE ONLY


-- ### NEW DAY ###

-- FINDING BOUNCE RATE FOR LANDING PAGE
CREATE TEMPORARY TABLE first_pgview
SELECT website_session_id,
	MIN(website_pageview_id) as first_pg
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id;

SELECT * FROM first_pgview;


-- LINKING THE FIRST PAGEVIEW ID OF EACH SESSION WITH ITS URL
CREATE TEMPORARY TABLE landing_pg_of_sessions
SELECT 
		first_pgview.website_session_id,
		first_pgview.first_pg,
        website_pageviews.pageview_url
FROM first_pgview
LEFT JOIN website_pageviews
ON 
	first_pgview.first_pg = website_pageviews.website_pageview_id;
-- select * from landing_pg_of_sessions


-- FINDING SESSIONS WITH ONLY ONE PAGE VIEW I.E BOUNCE PAGE
CREATE TEMPORARY TABLE bounce_sessions_id_new
SELECT 
		website_session_id,
		COUNT(website_pageview_id) AS page_viewed
FROM website_pageviews
GROUP BY website_session_id
HAVING page_viewed = 1;

-- JOIN ABOVE TEMP TABLES TO FIND BOUNCE AND UNBOUNCED SESSIONS
SELECT 
        landing_pg_of_sessions.pageview_url,
        COUNT(DISTINCT landing_pg_of_sessions.website_session_id) AS total_sessions,
        COUNT(DISTINCT bounce_sessions_id_new.website_session_id) AS bounced_sessions,
        COUNT(bounce_sessions_id_new.website_session_id)/COUNT(landing_pg_of_sessions.website_session_id) AS bounce_rate
FROM landing_pg_of_sessions
LEFT JOIN bounce_sessions_id_new
ON 
	landing_pg_of_sessions.website_session_id = bounce_sessions_id_new.website_session_id
GROUP BY landing_pg_of_sessions.pageview_url
ORDER BY landing_pg_of_sessions.pageview_url; 
