-- TABLES INVOLVED
-- users 
-- sellers 
-- products 
-- orders 
-- order_items
-- payments 
-- shipments 
-- shipment_events 

-- a) Basic

-- Find all orders with the user name, order date, and order status.
SELECT 
    U.USER_NAME,
    O.ORDER_DATE,
    O.ORDER_STATUS
FROM
	USERS U
    JOIN ORDERS O ON 
    U.USER_ID = O.USER_ID;
-- Find all shipments with the corresponding user name and carrier.
SELECT 
	U.USER_NAME,
    S.CARRIER
FROM 
	USERS U
    JOIN ORDERS O ON
		U.USER_ID = O.USER_ID
    JOIN SHIPMENTS S ON
		S.ORDER_ID = O.ORDER_ID;
	
-- Find all products with their seller name and seller city.
SELECT
	P.PRODUCT_ID,
    S.SELLER_ID,
    S.SELLER_CITY
FROM
	PRODUCTS P 
	JOIN SELLERS S ON
		P.SELLER_ID = S.SELLER_ID;
        
-- b) Medium
-- 4. Find each user and the number of completed orders they placed, including users with zero completed orders.
SELECT
	U.USER_ID,
    COUNT(O.ORDER_ID) AS CNT_OF_CMPLTD_ORDS
FROM 
	USERS U
	JOIN ORDERS O ON
		U.USER_ID = O.USER_ID
	WHERE LOWER(O.ORDER_STATUS) = LOWER('COMPLETED')
    GROUP BY U.USER_ID;
-- 5. Find each seller and the total quantity of items sold across completed orders only.
SELECT
	S.SELLER_ID,
    COUNT(O.ORDER_ID) AS CT_CMPLTD_ORDS
FROM
	SELLERS S 
	JOIN PRODUCTS P ON
		S.SELLER_ID = P.SELLER_ID
	JOIN ORDER_ITEMS OI ON 
		P.PRODUCT_ID = OI.PRODUCT_ID
	JOIN ORDERS O ON
		OI.ORDER_ID = O.ORDER_ID
	WHERE O.ORDER_STATUS = 'completed'
	GROUP BY S.SELLER_ID;
-- 6. Find all orders that have a payment record but no shipment record.
 -- WHAT DO YOU MEAN BY PAYMENT RECORD?
 
-- 7. Find all users who placed at least one completed order that contained products from more than one category.
SELECT DISTINCT
    U.USER_ID,
    U.USER_NAME
FROM USERS U
JOIN ORDERS O
    ON U.USER_ID = O.USER_ID
JOIN ORDER_ITEMS OI
    ON O.ORDER_ID = OI.ORDER_ID
JOIN PRODUCTS P
    ON OI.PRODUCT_ID = P.PRODUCT_ID
WHERE O.ORDER_STATUS = 'completed'
GROUP BY U.USER_ID, U.USER_NAME, O.ORDER_ID
HAVING COUNT(DISTINCT P.CATEGORY) > 1;
-- 8. Find each city and the total revenue from paid payments only, where city is the user city.
-- 9. Find the sellers whose products appear in at least one paid order from users in a different city than the seller city.
-- 10. Find each payment method and the total number of distinct users who successfully paid with that method.

-- c) HARD - FAANG LEVELLED
-- 11. Find the users whose completed orders were fulfilled by at least two different carriers.
SELECT
    O.USER_ID
FROM ORDERS O
JOIN SHIPMENTS S
    ON S.ORDER_ID = O.ORDER_ID
WHERE O.ORDER_STATUS = 'completed'
GROUP BY O.USER_ID
HAVING COUNT(DISTINCT S.CARRIER) >= 2;
-- 12. Find the seller whose products generated the highest paid revenue, considering only orders with payment_status = 'paid'.
-- 13. Find all orders where every item in the order came from the same seller, considering completed orders only.
-- 14. Find the users who have bought from every seller that sells products in the Books or Kitchen categories, considering completed and paid orders only.
-- 15. Find the carrier with the highest average paid order value across shipped orders.
-- 16. Find all users whose paid completed orders include at least one product from a seller in the same city as the user and at least one product from a seller in a different city.
-- 17. Find the orders where the total paid amount in payments.amount does not match the sum of price * quantity from order items.
-- 18. Find the user who has the highest number of distinct categories purchased across paid completed orders. Return all tied users.
-- 19. Find all sellers whose products were purchased by users from at least three different cities across paid completed orders.
-- 20. Find the order ids for which the shipment reached more than one distinct hub city based on shipment events.