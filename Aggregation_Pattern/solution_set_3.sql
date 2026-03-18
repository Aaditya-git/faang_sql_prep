
-- a) Basic
-- 1. Find the total number of distinct users who placed orders.
SELECT 
	DISTINCT O.USER_ID
FROM
	USERS U 
    JOIN ORDERS O ON
    U.USER_ID = O.USER_ID;
    
-- 2. Find the total number of distinct categories ordered.
SELECT
	P.CATEGORY,
    COUNT(O.PRODUCT_ID) AS CT
FROM 
	ORDERS O JOIN PRODUCTS P ON
    P.PRODUCT_ID = O.PRODUCT_ID
    GROUP BY(P.CATEGORY);
    
-- b) Medium

-- 3. Find the user who spent the most money in a single day.
-- 4. Find the average revenue per order for each category.
-- 5. Find the top 2 users by total spending.
-- 6. Find the number of users who have never placed an order.
-- 7. Find the category with the lowest total revenue.
-- 8. Find the users whose average order value is greater than 500.
-- 9. Find the percentage contribution of each category to total revenue.

-- c) HARD – FAANG LEVELLED

-- 10. Find the users whose total spending is in the top 20% of all users.
-- 11. Find the category whose revenue increased the most between any two consecutive days.
-- 12. Find the users who contributed to more than 30% of total revenue individually.
-- 13. Find the day with the highest revenue growth compared to the previous day.
