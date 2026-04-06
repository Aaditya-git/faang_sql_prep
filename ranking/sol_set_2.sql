-- c) HARD - FAANG LEVELLED
-- For each city, find the user whose 3rd highest order value is the highest among all users in that city. Return all ties.
WITH JOINED AS(
	SELECT
		U.USER_ID,
		U.CITY,
		O.ORDER_ID,
		SUM(OI.UNIT_PRICE * OI.QUANTITY) AS TOTAL_SPEND
	FROM
		USERS U 
		JOIN ORDERS O ON
			U.USER_ID = O.USER_ID
		JOIN ORDER_ITEMS OI ON
			O.ORDER_ID = OI.ORDER_ID
		WHERE
			O.ORDER_STATUS = 'completed'
			GROUP BY U.USER_ID,U.CITY,O.ORDER_ID
), 
RANKED AS(
	SELECT 
		CITY,
		ORDER_ID,
		USER_ID,
		TOTAL_SPEND,
		ROW_NUMBER() OVER(
			PARTITION BY USER_ID
			ORDER BY TOTAL_SPEND DESC
		) AS USER_RN
	FROM 
		JOINED
)
SELECT 
	CITY,
	ORDER_ID,
    USER_ID,
    TOTAL_SPEND,
    DENSE_RANK() OVER(
		PARTITION BY CITY 
        ORDER BY TOTAL_SPEND DESC
    ) AS RANKED_USER
FROM
	RANKED
	WHERE
		USER_RN = 2;

-- For each category, find the product whose rank by revenue (SUM of quantity * unit_price) is 2, 
-- but only among categories where the top product’s revenue is at least 2x the 2nd ranked product.
WITH JOINED AS(
SELECT
	P.PRODUCT_ID,
    P.CATEGORY,
    SUM(OI.QUANTITY * OI.UNIT_PRICE) AS REVENUE_PER_PRDCT
FROM
	PRODUCTS P
	JOIN ORDER_ITEMS OI ON
		P.PRODUCT_ID = OI.PRODUCT_ID
        GROUP BY P.PRODUCT_ID, P.CATEGORY
),
RANKED AS(
SELECT 
	*,
    ROW_NUMBER() OVER(
		PARTITION BY CATEGORY 
        ORDER BY REVENUE_PER_PRDCT DESC
    ) AS RANKED_PRDCT
FROM
	JOINED
)
SELECT 
	PRODUCT_ID,
    CATEGORY,
    REVENUE_PER_PRDCT
FROM
	RANKED;
    WHERE RANKED_PRDCT =2;
-- For each user, consider only their top 3 orders by value. Among those, compute the average order value. Then, within each city, return the user(s) with the highest such average.
-- For each city, find users whose largest order is NOT in the top 2 largest orders in that city, but whose total spend is in the top 2 in that city.
-- For each category, rank products by total quantity sold. Then, for each category, return products whose rank is 2 only if there exists at least one product in that category with strictly higher revenue but lower quantity rank.
-- For each user, rank their orders by value. Then compute the difference between their highest and 3rd highest order. Return the top 2 users with the highest such difference.
-- For each city, rank users by number of orders. Then, among the top 3 users, find the one whose median order value is highest.
-- For each category, find the product whose total revenue rank is 1, but whose unit price rank within the category is NOT 1.
-- For each user, consider only completed orders. Rank them by value. Then, for each user, find if their 2nd ranked order is closer in value to their 1st or 3rd ranked order. Return users where it is closer to the 3rd.
-- For each city, find users whose top order value is the same as another user in the same city, but whose total spend is strictly higher than all other users sharing that same top order value.
