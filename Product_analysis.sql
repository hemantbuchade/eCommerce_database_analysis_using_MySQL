USE mavenfuzzyfactory;

-- 1. Product analysis monthly
SELECT 
	YEAR(created_at) AS Yr,
    MONTH(created_at) AS Mon,
    COUNT(order_id) As Sales,
    SUM(price_usd) AS revenue,
    SUM(price_usd - cogs_usd) As margin
FROM orders
WHERE created_at < "2013-01-04"
GROUP BY 1,2;


-- 2. Impact of new product 
SELECT 
	YEAR(website_sessions.created_at) AS Yr,
    MONTH(website_sessions.created_at) AS Mon,
    COUNT(order_id) As orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conversion_rate,
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN order_id ELSE NULL END) AS product_two_orders
FROM website_sessions
LEFT JOIN orders
ON 
	website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < "2013-04-06"
	AND website_sessions.created_at > "2012-04-01"
GROUP BY 1,2;

#################################################################################################################################################################################################

-- 		PRODUCT LEVEL WEBSITE ANALYSIS

-- 1. Analyzing time period before and after product launch

CREATE TEMPORARY TABLE products_page1
SELECT 
	pageview_url,
    website_pageview_id as min_page,
    website_session_id
FROM website_pageviews
WHERE created_at BETWEEN "2012-10-05" AND "2013-04-07"
	AND pageview_url in ("/products");

SELECT
	products_page1.website_session_id,
    website_pageviews.website_pageview_id AS min_page_after_products_page,
    website_pageviews.pageview_url
FROM products_page1
LEFT JOIN website_pageviews
	ON products_page1.website_session_id = website_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > products_page1.min_page
GROUP BY 1;
-- JOINING such that the website_session_id is same but pageview_id greater than products pageview_id for same website_session_id

SELECT
	CASE 
		WHEN created_at < "2013-01-06" THEN "A. Pre_Product_2"
        WHEN created_at >= "2013-01-06" THEN "B. Post_Product_2"
        END AS time_period,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN pageview_url IN ("/the-original-mr-fuzzy","/the-forever-love-bear") THEN website_session_id ELSE NULL END) AS w_next_page,
    
    COUNT(DISTINCT CASE WHEN pageview_url IN ("/the-original-mr-fuzzy","/the-forever-love-bear") THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT website_session_id) AS pct_w_next_page,
    
    COUNT(DISTINCT CASE WHEN pageview_url ="/the-original-mr-fuzzy" THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    
    COUNT(DISTINCT CASE WHEN pageview_url ="/the-original-mr-fuzzy" THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
    
    COUNT(DISTINCT CASE WHEN pageview_url ="/the-forever-love-bear" THEN website_session_id ELSE NULL END) AS to_lovebear,
    
    COUNT(DISTINCT CASE WHEN pageview_url ="/the-forever-love-bear" THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT website_session_id) AS pct_to_lovebear
    
FROM website_pageviews
WHERE pageview_url IN ("/products","/the-original-mr-fuzzy","/the-forever-love-bear")
	AND created_at > "2012-10-06" 
    AND created_at < "2013-04-06"
GROUP BY 1
ORDER BY 2 DESC
LIMIT 2;

-- 2. Conversion funnel for both products
-- 1. find the pageview_id for /products page within given time period
CREATE TEMPORARY TABLE product_page
SELECT 
	pageview_url,
    website_pageview_id as min_page,
    website_session_id
FROM website_pageviews
WHERE created_at >= "2013-01-06"
	AND created_at < "2013-04-10"
	AND pageview_url in ("/products");

-- 2. Inner Join the above table with pageviews table to see only those pageview_id which have gone to mrfuzzy or lovebear page and get pageview_id for those 2 products
CREATE TEMPORARY TABLE product_seen
SELECT
	product_page.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS product_pg_id,
	CASE
		WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN "mr_fuzzy"
        WHEN website_pageviews.pageview_url = '/the-forever-love-bear' THEN "love_bear"
	END AS product_seen
FROM product_page
INNER JOIN website_pageviews
ON
	product_page.website_session_id = website_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > product_page.min_page
GROUP BY 1;

-- 3. Joined the above table with website_pageviews for pageview_ids greater than pageview_ids of those 2 products to get he pages after that products
-- created flags for the further pages
CREATE TEMPORARY TABLE encoding
SELECT
	product_seen.product_seen,
    product_seen.website_session_id,
    website_pageviews.pageview_url,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
	CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
	CASE WHEN website_pageviews.pageview_url IN ('/billing','/billing-2')  THEN 1 ELSE 0 END AS billing,
	CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thank_you_for_your_order
FROM product_seen
LEFT JOIN website_pageviews
ON 
	product_seen.website_session_id = website_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > product_seen.product_pg_id ;

-- 4. Group by the above table with product_seen to get respective session for further pages
SELECT
	product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN to_cart =1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN to_shipping =1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN to_billing =1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN to_thank_you_for_your_order =1 THEN website_session_id ELSE NULL END) AS to_thank_you_for_your_order
FROM
(SELECT
	product_seen,
    website_session_id,
	MAX(cart) as to_cart,
	MAX(shipping) as to_shipping,
	MAX(billing) as to_billing,
	MAX(thank_you_for_your_order) as to_thank_you_for_your_order
FROM encoding
GROUP BY 2) AS conv
GROUP BY 1;

-- 5. Got the conversion rates for each page
SELECT
	product_seen,
    
    COUNT(DISTINCT CASE WHEN to_cart =1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT website_session_id) AS product_ctr,
    
    COUNT(DISTINCT CASE WHEN to_shipping =1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_cart =1 THEN website_session_id ELSE NULL END) AS cart_ctr,
    
    COUNT(DISTINCT CASE WHEN to_billing =1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_shipping =1 THEN website_session_id ELSE NULL END) AS shipping_ctr,
    
    COUNT(DISTINCT CASE WHEN to_thank_you_for_your_order =1 THEN website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN to_billing =1 THEN website_session_id ELSE NULL END) AS billing_ctr
FROM
(SELECT
	product_seen,
    website_session_id,
	MAX(cart) as to_cart,
	MAX(shipping) as to_shipping,
	MAX(billing) as to_billing,
	MAX(thank_you_for_your_order) as to_thank_you_for_your_order
FROM encoding
GROUP BY 2) AS conv
GROUP BY 1;


###############################################################################################################################
-- 			CROSS SELL PRODUCTS

-- Cindy introduced the cross selling feature on the cart from 25th Sept. We need to find impact of cross selling on cart page before
-- and after this was implemented
-- 1. Sessions that saw cart and shipping page
CREATE TEMPORARY TABLE cart1
SELECT 
	website_session_id,
    website_pageview_id,
    pageview_url,
    CASE
		WHEN created_at < "2013-09-25" THEN "A.Pre_Cross_Sell"
        WHEN created_at >= "2013-09-25" THEN "B.Post_Cross_Sell"
	END AS time_period
FROM website_pageviews
WHERE created_at >= "2013-08-25"
	AND created_at <= "2013-10-25"
    AND pageview_url IN ("/cart",'/shipping' );


SELECT
	time_period,
	COUNT(DISTINCT CASE WHEN pageview_url = "/cart" THEN cart1.website_session_id ELSE NULL END) AS cart_sessions,
    
    COUNT(DISTINCT CASE WHEN pageview_url = "/shipping" THEN cart1.website_session_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN pageview_url = "/cart" THEN cart1.website_session_id ELSE NULL END) AS cart_ctr,
    
    COUNT(DISTINCT order_id) AS orders_placed,
    SUM(CASE WHEN pageview_url = "/shipping" THEN items_purchased ELSE NULL END) AS products_purchased,
    
    SUM(CASE WHEN pageview_url = "/shipping" THEN items_purchased ELSE NULL END)
    /COUNT(DISTINCT order_id) AS products_per_order,
    
    SUM(CASE WHEN pageview_url = "/shipping" THEN price_usd ELSE NULL END) AS Revenue,
    
    SUM(CASE WHEN pageview_url = "/shipping" THEN price_usd ELSE NULL END)/
    COUNT(DISTINCT order_id) AS AOV,
    
    SUM(CASE WHEN pageview_url = "/shipping" THEN price_usd ELSE NULL END)
    /COUNT(DISTINCT CASE WHEN pageview_url = "/cart" THEN cart1.website_session_id ELSE NULL END) AS rev_per_cart_sessions

FROM cart1
LEFT JOIN orders
	ON cart1.website_session_id = orders.website_session_id
GROUP BY time_period;


##########################################################################################################################

-- Analyzing impact of 3rd product on cross selling feature
-- 1.sessions having cart pg seen
CREATE TEMPORARY TABLE cart
SELECT
	CASE
		WHEN created_at < "2013-12-12" THEN "A.Pre_Birthday_Bear" 
        WHEN created_at >= "2013-12-12" THEN "A.Post_Birthday_Bear" 
	END AS time_period,
    website_session_id AS cart_id,
    website_pageview_id AS cart_pgid
FROM website_pageviews
WHERE pageview_url = "/cart"
	AND created_at BETWEEN "2013-11-12" AND "2014-01-12";

-- 2. cart_session_id after which have clicked next page
CREATE TEMPORARY TABLE cart_next
SELECT 
	time_period,
    cart.cart_id,
    MIN(website_pageview_id) AS pgid_after_cart
FROM cart
LEFT JOIN website_pageviews
ON 
	cart.cart_id = website_pageviews.website_session_id
	AND website_pageviews.website_pageview_id > cart.cart_pgid
GROUP BY cart.cart_id
HAVING MIN(website_pageview_id) IS NOT NULL
;

SELECT
	cart.time_period,
    COUNT(cart.cart_id) AS cart_sessions,
    COUNT(cart_next.cart_id) AS cart_next_session,
    
    COUNT(order_id) AS orders_placed,
    COUNT(order_id)/COUNT(cart.cart_id) AS conv_rate,
    
    SUM(items_purchased) as products_purchased,
    SUM(items_purchased)/COUNT(order_id) AS products_per_order,
    
    SUM(price_usd)/COUNT(order_id) AS AOV,
    
    SUM(price_usd) AS revenue,
    SUM(price_usd)/COUNT(cart_next.cart_id) AS rev_per_session
FROM cart
LEFT JOIN cart_next
ON
	cart.cart_id = cart_next.cart_id
LEFT JOIN orders
ON 
	cart_next.cart_id = orders.website_session_id
GROUP BY cart.time_period;
    
    
#########################################################################################################################################################################################################################################
-- 				Product Refund Analysis

-- Products refund rates by month
CREATE TEMPORARY TABLE refund
SELECT 
    YEAR(order_items.created_at) AS yr,
    MONTH(order_items.created_at) AS mon,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_id ELSE NULL END) AS p1_orders,
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refunds.order_item_refund_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_id ELSE NULL END) AS p1_refund_rt,
    
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_id ELSE NULL END) AS p2_orders,
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refunds.order_item_refund_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_id ELSE NULL END) AS p2_refund_rt,
    
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_id ELSE NULL END) AS p3_orders,
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refunds.order_item_refund_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_id ELSE NULL END) AS p3_refund_rt,
    
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_id ELSE NULL END) AS p4_orders,
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refunds.order_item_refund_id ELSE NULL END)/
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_id ELSE NULL END) AS p4_refund_rt
FROM order_items
LEFT JOIN order_item_refunds
ON 
	order_items.order_id = order_item_refunds.order_id
WHERE order_items.created_at < "2014-10-15"
GROUP BY YEAR(order_items.created_at),
		MONTH(order_items.created_at);
        

-- Product with most refund rate
SELECT
	AVG(p1_refund_rt)*100 AS 'The Original Mr. Fuzzy',
    AVG(p2_refund_rt)*100 AS 'The Forever Love Bear',
    AVG(p3_refund_rt)*100 AS 'The Birthday Sugar Panda',
    AVG(p4_refund_rt)*100 AS 'The Hudson River Mini bear'
FROM refund;