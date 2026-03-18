
-- a) Basic
-- 1. Find the total number of distinct users who placed orders.
SELECT 
	COUNT(DISTINCT O.USER_ID)
FROM
	USERS U 
    JOIN ORDERS O ON
    U.USER_ID = O.USER_ID;
    
-- 2. Find the total number of distinct categories ordered.
SELECT 
    COUNT(DISTINCT P.CATEGORY) AS CT
FROM 
    ORDERS O 
    JOIN PRODUCTS P 
    ON P.PRODUCT_ID = O.PRODUCT_ID;
-- IF ASKED SINGLE AGGREGATED Value NO NEED TO ADD GROUP BY.
    
-- b) Medium

-- 3. Find the user who spent the most money in a single day.
WITH SM AS(
SELECT
	O.USER_ID,
	O.ORDER_DATE,
    P.PRICE * O.QUANTITY  AS SM
FROM 
	ORDERS O JOIN PRODUCTS P ON
    P.PRODUCT_ID = O.PRODUCT_ID),
    RNK AS (
    SELECT 
		*,
        DENSE_RANK() OVER(ORDER BY SM DESC) AS RN
	FROM 
		SM)
        SELECT 
			USER_ID FROM RNK WHERE RN = 1;
    
-- 4. Find the average revenue per order for each category.



-- 5. Find the top 2 users by total spending.
WITH JOINED_DATA AS (
SELECT
	O.USER_ID,
    SUM(P.PRICE * O.QUANTITY) AS TOTAL_SPEND
FROM
	PRODUCTS P JOIN ORDERS O ON
    P.PRODUCT_ID = O.PRODUCT_ID
    GROUP BY O.USER_ID),
     FINAL AS(
SELECT 
	USER_ID,
    TOTAL_SPEND,
    DENSE_RANK() OVER(ORDER BY TOTAL_SPEND DESC) AS D_RNK
FROM 
	JOINED_DATA)
    SELECT USER_ID FROM FINAL WHERE D_RNK <=2;
-- 6. Find the number of users who have never placed an order.
SELECT 
	COUNT(U.USER_ID)
FROM USERS U LEFT JOIN ORDERS O ON 
	U.USER_ID = O.USER_ID
    WHERE O.ORDER_ID IS NULL;
-- 7. Find the category with the lowest total revenue.
SELECT
	P.CATEGORY,
	SUM(P.PRICE * O.QUANTITY) AS SM
FROM 
	PRODUCTS P JOIN ORDERS O ON
    P.PRODUCT_ID = O.PRODUCT_ID
    GROUP BY P.CATEGORY
    ORDER BY SM LIMIT 1;
-- 8. Find the users whose average order value is greater than 500.
WITH AVG_VAL AS (
SELECT 
	O.USER_ID AS USER_ID,
    ROUND(AVG(P.PRICE * O.QUANTITY),2) AS AVG_ORD_VAL
FROM
	ORDERS O JOIN PRODUCTS P ON
    P.PRODUCT_ID = O.PRODUCT_ID
    GROUP BY O.USER_ID)
SELECT 
	USER_ID 
FROM 
	AVG_VAL
    WHERE AVG_ORD_VAL>500;
-- 9. Find the percentage contribution of each category to total revenue.
WITH REV_BY_ECH_CTGRY AS(
	SELECT 
		P.CATEGORY,
		SUM(P.PRICE * O.QUANTITY) AS SM
	FROM
		PRODUCTS P JOIN ORDERS O ON
        P.PRODUCT_ID = O.PRODUCT_ID
        GROUP BY P.CATEGORY),
        TOTAL_SUM AS(
	SELECT
		*,
        SUM(SM) OVER() AS TOTAL_SUM
	FROM
		REV_BY_ECH_CTGRY)
	SELECT 
		CATEGORY,
		ROUND(((SM / TOTAL_SUM)) * 100,2) AS PRCNTG_VAL
	FROM 
		TOTAL_SUM;
        
-- c) HARD – FAANG LEVELLED

-- 10. Find the users whose total spending is in the top 20% of all users.
WITH SPEND_PER_USER AS (
    SELECT
        O.USER_ID,
        SUM(P.PRICE * O.QUANTITY) AS TOTAL_SPENDING
    FROM ORDERS O
    JOIN PRODUCTS P
        ON O.PRODUCT_ID = P.PRODUCT_ID
    GROUP BY O.USER_ID
),
RANKED_USERS AS (
    SELECT
        USER_ID,
        TOTAL_SPENDING,
        NTILE(5) OVER (ORDER BY TOTAL_SPENDING DESC) AS SPENDING_BUCKET
    FROM SPEND_PER_USER
)
SELECT
    USER_ID,
    TOTAL_SPENDING
FROM RANKED_USERS
WHERE SPENDING_BUCKET = 1;
-- 11. Find the category whose revenue increased the most between any two consecutive days.

-- 12. Find the users who contributed to more than 30% of total revenue individually.

-- 13. Find the day with the highest revenue growth compared to the previous day.
