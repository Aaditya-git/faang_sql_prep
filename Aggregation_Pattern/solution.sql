-- a) Basic USERS, PRODUCTS, ORDERS. 
-- 1. Find the total number of orders.
SELECT 
	ORDER_ID,
	COUNT(*) AS CNT_OF_ORDERS
FROM
	ORDERS
    GROUP BY ORDER_ID; -- PER ORDER_ID
SELECT COUNT(*) FROM ORDERS; -- TOTAL_COUNT

-- 2. Find the total quantity of products ordered.
SELECT 
	SUM(QUANTITY) AS TOTAL_QUANTITY
FROM
	ORDERS; 
SELECT 
	PRODUCT_ID,
	SUM(QUANTITY) AS TOTAL_QUANTITY
FROM
	ORDERS
    GROUP BY PRODUCT_ID; -- PER PRODUCT ---- QUESTIONS ARE VERY VAGUE!
-- DIRECTLY GIVEN! TAKE THIS VERY SERIOUSLY, 
-- I NEED TO CRACK FAANG, SO DESIGN TABLES ACCORDINGLY

-- 3. Find the average product price.
SELECT 
	PRODUCT_NAME,
	ROUND(AVG(PRICE),2) AS AVG_PRICE
FROM
	PRODUCTS
	GROUP BY PRODUCT_NAME;
    
-- 4. AVERAGE PRODUCT PRICE ORDERED WOULD BE  :-
SELECT 
	P.PRODUCT_NAME,
    ROUND(AVG(P.PRICE * O.QUANTITY),2) AS TOTAL_PRICE
FROM
	PRODUCTS P LEFT JOIN ORDERS O ON
    P.PRODUCT_ID = O.ORDER_ID
    GROUP BY P.PRODUCT_NAME;
    
-- I HAVE MULTIPLE SOLUTIONS FOR THIS 
-- BECAUSE I DON'T KNOW HOW THE O/P IS EXPECTED, 
-- I SOLVED IT AS PER MY UNDERSTANDING OF THE QUESTION

-- MEDIUM USERS, PRODUCTS, ORDERS.
-- Find the number of users in each country.
SELECT
	COUNTRY,
	COUNT(*) AS CNT
FROM
	USERS
	GROUP BY COUNTRY
    ORDER BY CNT;
-- 5. Find the total number of orders per user.
SELECT 
	U.USER_ID,
    COUNT(O.USER_ID) AS CNT_PER_USER
FROM 
	USERS U JOIN ORDERS O ON
    U.USER_ID = O.USER_ID
    GROUP BY O.USER_ID
    ORDER BY CNT_PER_USER;

-- Find the total quantity ordered for each product.
	SELECT 
	PRODUCT_ID,
    SUM(QUANTITY) AS SM
FROM
	ORDERS
    GROUP BY PRODUCT_ID;
-- Find the average quantity per order.
	SELECT
		ORDER_ID,
        ROUND(AVG(QUANTITY),2) AS AVG
	FROM 
		ORDERS
        GROUP BY ORDER_ID;
-- Find the number of orders placed each day.
SELECT 
	ORDER_DATE,
    COUNT(ORDER_ID) AS CNT
FROM
	ORDERS
    GROUP BY ORDER_DATE;
-- Find the total revenue per product
-- (revenue = quantity × price).
SELECT 
	P.PRODUCT_ID,
    ROUND(SUM(P.PRICE * O.QUANTITY),2) AS TOTAL_PRICE
FROM
	PRODUCTS P  JOIN ORDERS O ON
    P.PRODUCT_ID = O.PRODUCT_ID
    GROUP BY P.PRODUCT_ID; -- CAN USE PRODUCT_ID

-- Find the total revenue per category.
SELECT 
	P.CATEGORY,
    ROUND(SUM(P.PRICE * O.QUANTITY),2) AS TOTAL_PRICE
FROM
	PRODUCTS P  JOIN ORDERS O ON
    P.PRODUCT_ID = O.PRODUCT_ID
    GROUP BY P.CATEGORY; -- CAN USE PRODUCT_ID
    
-- c) HARD – FAANG LEVELLED
-- Users who placed more than 1 order
	select
		user_id
	from 
		orders
		group by user_id
        having count(user_id) >1;
-- Countries with more than 2 users
select 
	country
from users
	group by country
    having count(user_id)>2;
-- Product with highest total quantity sold
select
	product_id
from orders
	group by product_id
    order by sum(product_id) desc
    limit 1;
-- Categories whose average product price is greater than 500
select
	category
from
	products
    group by category
    having avg(price)>500;


    