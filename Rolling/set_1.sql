
select * from orders;
select * from user_events;
-- For each user, compute the running total of completed order amount ordered by time.
SELECT
	USER_ID,
    ORDER_TIME,
    AMOUNT,
    SUM(AMOUNT) OVER(PARTITION BY USER_ID ORDER BY AMOUNT) AS TOTAL_AMOUNT
FROM
	ORDERS
    WHERE STATUS =LOWER('COMPLETED');

-- For each user, compute the moving average of the last 2 completed orders.
SELECT
	USER_ID,
    ORDER_TIME,
    AVG(AMOUNT) OVER(
		PARTITION BY USER_ID 
		ORDER BY AMOUNT
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS AVG_AMOUNT
FROM
	ORDERS
    WHERE STATUS=LOWER('COMPLETED');
    
-- For each user, compute the rolling sum of the last 3 completed orders, 
-- but only include rows where at least 3 completed orders exist.

WITH COMPLETED_ORD_TBL AS (
SELECT
	USER_ID,
    ORDER_TIME,
    AMOUNT,
    ROW_NUMBER() OVER(
		PARTITION BY USER_ID
        ORDER BY ORDER_TIME
    ) AS RNK
FROM
	ORDERS
    WHERE STATUS =LOWER('COMPLETED')
)
SELECT 
	USER_ID,
    ORDER_TIME,
    SUM(AMOUNT) OVER(
		PARTITION BY USER_ID
        ORDER BY ORDER_TIME
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS SUM_OF_ORDERS
FROM
	COMPLETED_ORD_TBL
    WHERE RNK>=3;
    
    WITH completed_ord_tbl AS (
    SELECT
        user_id,
        order_time,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY order_time
        ) AS rnk
    FROM orders
    WHERE status = 'completed'
),
windowed AS (
    SELECT
        user_id,
        order_time,
        rnk,
        SUM(amount) OVER (
            PARTITION BY user_id
            ORDER BY order_time
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS sum_of_orders
    FROM completed_ord_tbl
)
SELECT
    user_id,
    order_time,
    sum_of_orders
FROM windowed
WHERE rnk >= 3;


-- For each order, compute the difference between the current order amount 
-- and the average of the previous 2 completed orders for that user.

SELECT
	USER_ID,
    ORDER_TIME,
    AMOUNT - 
    AVG(AMOUNT) OVER(
		PARTITION BY USER_ID
        ORDER BY ORDER_TIME
        ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
    ) AS DIFF_OF_LAST_2_AMT
FROM
	ORDERS
    WHERE STATUS='COMPLETED';
    
-- For each user, 
-- compute a running count of completed orders and also compute the running average order amount.

SELECT 
	USER_ID,
    ORDER_TIME,
    COUNT(USER_ID) OVER(
		PARTITION BY USER_ID
        ORDER BY ORDER_TIME
    ) AS CT_OF_ORDERS,
    AVG(AMOUNT) OVER(
		PARTITION BY USER_ID
        ORDER BY ORDER_TIME
    ) AS RUNNING_AVG_AMOUNT
FROM
	ORDERS
    WHERE STATUS = 'completed';
    
    
-- For each user, compute:

-- rolling sum of completed order amount over last 3 orders
-- and rank the current order within that rolling window by amount (highest = rank 1)

WITH RUNNING_TOTAL_TABLE AS (
SELECT
	USER_ID,
    ORDER_TIME,
    AMOUNT,
    SUM(AMOUNT) OVER(
		PARTITION BY USER_ID
        ORDER BY ORDER_TIME
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	) AS RUNNING_SUM
FROM
	ORDERS
    WHERE STATUS = 'completed'
)
SELECT 
	USER_ID,
    ORDER_TIME,
    AMOUNT,
    RUNNING_SUM,
    ROW_NUMBER() OVER(
		PARTITION BY USER_ID
        ORDER BY AMOUNT DESC
    ) AS RNKED_SUM
FROM
RUNNING_TOTAL_TABLE;


WITH base AS (
    SELECT
        order_id,
        user_id,
        order_time,
        amount,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY order_time
        ) AS rn,
        SUM(amount) OVER (
            PARTITION BY user_id
            ORDER BY order_time
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS rolling_sum_3
    FROM orders
    WHERE status = 'completed'
)
SELECT
    b1.user_id,
    b1.order_id,
    b1.order_time,
    b1.amount,
    b1.rolling_sum_3,
    1 + (
        SELECT COUNT(*)
        FROM base b2
        WHERE b2.user_id = b1.user_id
          AND b2.rn BETWEEN b1.rn - 2 AND b1.rn
          AND b2.amount > b1.amount
    ) AS rank_in_window
FROM base b1;


-- For each customer, calculate the running total of completed order amount ordered by order_time.
SELECT 
	CUSTOMER_ID,
    SUM(AMOUNT) OVER(
		PARTITION BY CUSTOMER_ID
        ORDER BY ORDER_TIME
    ) AS ROLLING_AMOUNT
FROM
	SALES_ORDERS;

-- For each customer, calculate the moving average of the last 2 completed orders.

-- For each customer, 
-- calculate the rolling completed revenue over the last 7 calendar days for each completed order.
WITH FILTERED_AMT AS(
SELECT 
	ORDER_ID,
	CUSTOMER_ID,
    ORDER_TIME,
    AMOUNT
FROM
	SALES_ORDERS
    WHERE STATUS = 'completed'
)
SELECT 
	C1.CUSTOMER_ID,
    C1.ORDER_ID,
    C1.ORDER_TIME,
    SUM(C2.AMOUNT) AS AMT_SUM
FROM
	FILTERED_AMT C1 
    JOIN FILTERED_AMT C2 ON
    C1.CUSTOMER_ID = C2.CUSTOMER_ID
    AND C2.ORDER_TIME BETWEEN DATE_SUB(C1.ORDER_TIME,INTERVAL 6 DAY) AND C1.ORDER_TIME
GROUP BY
	C1.CUSTOMER_ID ,
    C1.ORDER_ID,
    C1.ORDER_TIME;

-- For each customer, 
-- calculate the maximum completed order amount in the next 2 completed orders.
-- EASY

-- For each customer, calculate the ratio of the current completed order amount to the average of the previous 3 completed orders.
-- For each region, calculate the rolling 7-day sum of completed order amounts by order_time.
WITH filtered_rows AS (
    SELECT
        order_id,
        region,
        order_time,
        amount
    FROM sales_orders
    WHERE status = 'completed'
)
SELECT
    f1.region,
    f1.order_id,
    f1.order_time,
    SUM(f2.amount) AS day_7_rolling_sum
FROM filtered_rows f1
JOIN filtered_rows f2
    ON f1.region = f2.region
   AND f2.order_time BETWEEN DATE_SUB(f1.order_time, INTERVAL 6 DAY)
                         AND f1.order_time
GROUP BY
    f1.region,
    f1.order_id,
    f1.order_time;
-- For each customer, 
-- calculate the rolling count of high priority support tickets in the last 30 days based on ticket_time.
WITH FILTERED_TABLE AS (
SELECT 
	TICKET_ID,
    CUSTOMER_ID,
    TICKET_TIME
FROM
	SUPPORT_TICKETS
    WHERE PRIORITY = LOWER('HIGH')
)
SELECT 
	F1.TICKET_ID,
    F1.CUSTOMER_ID,
    F1.TICKET_TIME,
    COUNT(F2.TICKET_ID)
FROM	
	FILTERED_TABLE F1 
	JOIN FILTERED_TABLE F2 ON
		F1.CUSTOMER_ID = F2.CUSTOMER_ID AND
        F2.TICKET_TIME BETWEEN DATE_SUB(F1.TICKET_TIME,INTERVAL 29 DAY) 
			AND F1.TICKET_TIME
	GROUP BY
	F1.TICKET_ID,
    F1.CUSTOMER_ID,
    F1.TICKET_TIME;
		

-- For each customer, 
-- calculate the difference between each completed order amount 
-- and the rolling average of the last 3 completed orders.
WITH completed AS (
    SELECT
        customer_id,
        order_time,
        amount
    FROM sales_orders
    WHERE status = 'completed'
)
SELECT
    customer_id,
    order_time,
    amount,
    amount - AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY order_time
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS diff
FROM completed;


-- For each customer, 
-- calculate both the rolling sum and rolling average of completed order 
-- amounts over the last 4 completed orders, in the same result set.
