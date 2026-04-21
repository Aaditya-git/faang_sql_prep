
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


select * from product_views;

-- For each user, 
-- compute daily total completed transaction amount, then calculate a rolling 3-day sum of daily totals.
with grouped_total as(
	select 
		user_id,
		date(txn_time) as dated_txn,
		sum(amount) as total_amt
	from
		transactions
        where status = 'completed'
		group by user_id,dated_txn
)
select 
	user_Id,
    dated_txn,
    sum(total_amt) over(
		partition by user_id
        order by dated_txn
        rows between 2 preceding and current row
    ) as rolling_3_day_sum
from
	grouped_total;
	
	
-- For each day, 
-- compute number of distinct users who made a completed transaction, 
-- then compute a rolling 3-day average of that metric.




-- A user may transact multiple times for the same product in a day.
-- For each user-product-day, keep only the latest transaction, 
-- then compute a rolling sum of last 3 transactions per user.



-- DDL: Create Tables
CREATE TABLE apps (
    app_id INT PRIMARY KEY,
    app_name VARCHAR(100),
    category VARCHAR(50),
    developer_id INT,
    price_usd DECIMAL(10, 2)
);

CREATE TABLE transactionss (
    transaction_id INT PRIMARY KEY,
    app_id INT,
    user_id INT,
    transaction_date DATE,
    amount_usd DECIMAL(10, 2),
    is_refunded BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (app_id) REFERENCES apps(app_id)
);

-- DML: Insert Sample Data
INSERT INTO apps VALUES 
(1, 'Procreate', 'Creativity', 501, 9.99),
(2, 'Final Cut Pro', 'Video', 502, 299.99),
(3, 'Logic Pro', 'Audio', 502, 199.99),
(4, 'GoodNotes', 'Productivity', 503, 0.00),
(5, 'Octane Render', 'Graphics', 504, 19.99);

INSERT INTO transactionss (transaction_id, app_id, user_id, transaction_date, amount_usd, is_refunded) VALUES 
(101, 1, 1001, '2024-01-01', 9.99, FALSE),
(102, 1, 1002, '2024-01-02', 9.99, FALSE),
(103, 2, 1003, '2024-01-02', 299.99, FALSE),
(104, 1, 1001, '2024-01-05', 9.99, TRUE), -- Refunded
(105, 3, 1004, '2024-01-10', 199.99, FALSE),
(106, 1, 1005, '2024-02-01', 9.99, FALSE),
(107, 2, 1006, '2024-02-05', 299.99, FALSE),
(108, 4, 1007, '2024-02-10', 0.00, FALSE);


-- Finance team wants to see the net revenue (Sales minus Refunds) for each category in January 2024.
select * from apps;
select * from transactionss;

WITH JOINED_TBLE AS(
SELECT
	T.APP_ID,
    T.USER_ID,
    A.CATEGORY,
    T.TRANSACTION_DATE,
    T.AMOUNT_USD,
    T.IS_REFUNDED
FROM	
	APPS A 
    JOIN TRANSACTIONSS T ON
		A.APP_ID = T.APP_ID
),
FILTERED_TABLE AS(
	SELECT
		USER_ID,
		CATEGORY,
        TRANSACTION_DATE,
        AMOUNT_USD - 
        CASE 
			WHEN IS_REFUNDED = TRUE THEN AMOUNT_USD
            ELSE 0
		END AS SALES_REVENUE
	FROM
		JOINED_TBLE
        WHERE TRANSACTION_DATE BETWEEN '2024-01-01' AND '2024-01-31'
	)
    SELECT 
		CATEGORY,
        SUM(SALES_REVENUE) AS TOTAL_SALES_PER_CATEGORY
	FROM
		FILTERED_TABLE
        GROUP BY CATEGORY;
    
    
-- Question 2: The "Whale" Developers (Hard)
-- Identify developers who have earned more than $400 total revenue across all their apps, but only count apps that have at least 2 unique purchasers
SELECT
	A.DEVELOPER_ID,
    T.USER_ID AS CT,
    T.AMOUNT_USD AS TOTAL_SALE
FROM
	APPS A 
    JOIN TRANSACTIONSS T ON
		A.APP_ID = T.APP_ID;
	
    
    WITH qualified_apps AS (
    -- Step 1: Find apps that meet the user threshold
    SELECT 
        app_id,
        SUM(amount_usd) AS app_revenue
    FROM transactionsS
    WHERE is_refunded = FALSE
    GROUP BY app_id
    HAVING COUNT(DISTINCT user_id) >= 2
)
-- Step 2: Sum those qualified apps by Developer
SELECT 
    a.developer_id,
    SUM(q.app_revenue) AS total_qualified_revenue
FROM apps a
JOIN qualified_apps q ON a.app_id = q.app_id
GROUP BY a.developer_id
HAVING total_qualified_revenue > 400;


-- Calculate the Month-over-Month (MoM) percentage growth in total revenue for the App Store.
WITH GROUPED_TABLE AS (
	SELECT
		MONTH(TRANSACTION_DATE) AS MTH,
		YEAR(TRANSACTION_DATE) AS YR,
		SUM(AMOUNT_USD) AS TOTAL_REVENUE
	FROM
		TRANSACTIONSS
		WHERE IS_REFUNDED = FALSE
		GROUP BY MTH,YR
),
PREV_CALC_AMT AS(
SELECT 
	MTH,
    TOTAL_REVENUE,
    LAG(TOTAL_REVENUE) OVER(ORDER BY MTH) AS PREV_REV
FROM
	GROUPED_TABLE
)
SELECT 
	MTH,
    TOTAL_REVENUE,
    PREV_REV,
    round(100*(TOTAL_REVENUE - PREV_REV)/NULLIF(PREV_REV,0),2) AS GRWTH_PERCENTAGE
FROM
	PREV_CALC_AMT;
 
-- --------------------

-- Apple wants to measure User Retention. Find all users who purchased an app (from the transactions table) and then used that same app 
-- (in the user_activity table) on at least two different days within the first 7 days of their purchase.

-- Output: user_id, app_id, purchase_date.
WITH FILTERED_TABLE AS(
SELECT
	T.APP_ID,
    T.USER_ID,
    T.TRANSACTION_DATE AS PURCHASE_DATE,
    DATE(U.SESSION_START) AS START_DATE
FROM
	TRANSACTIONSS T 
	JOIN USER_ACTIVITY U ON
    T.USER_ID = U.USER_ID AND
	t.app_id = u.app_id
    WHERE IS_REFUNDED = FALSE
    AND u.session_start >= t.transaction_date
    AND SESSION_START <= DATE_ADD(T.TRANSACTION_DATE,INTERVAL 7 DAY)
)
SELECT
	USER_ID,
    APP_ID,
    MIN(PURCHASE_DATE) AS PURCHASE_DATE
FROM 
	FILTERED_TABLE
    GROUP BY USER_ID, APP_ID, START_DATE
    HAVING COUNT(START_DATE)>=2;
    
    
    
-- Identify the top 2 categories that had the highest total "Usage Duration" (session_end - session_start) during the first week of January 2024.

-- Output: category, total_usage_minutes.
WITH GROUPED AS(
SELECT
	A.CATEGORY,
    U.SESSION_START,
    U.SESSION_END,
    TIMESTAMPDIFF(MINUTE,SESSION_START,SESSION_END) AS USAGE_DURATION
FROM
	APPS A
	JOIN USER_ACTIVITY U ON
		A.APP_ID = U.APP_ID
	WHERE SESSION_START >= '2024-01-01' AND
		  SESSION_START <= '2024-01-07'
)
SELECT
	CATEGORY,
    SUM(USAGE_DURATION) AS MAX_TIME
FROM GROUPED
GROUP BY CATEGORY
LIMIT 2;


-- The Task: Find the start time and end time for every 'Online' session for each device.
select 
	DEVICE_ID,
    PING_TIME,
    STATUS,
    ROW_NUMBER() OVER(PARTITION BY DEVICE_ID ORDER BY PING_TIME) -
    ROW_NUMBER() OVER(PARTITION BY DEVICE_ID,STATUS ORDER BY PING_TIME) AS RN2
FROM
	device_pings;
    ORDER BY PING_TIME,DEVICE_ID;

    
-- Health app team wants to reward users who stay active. 
-- A "Streak" is defined as logging at least one workout every single day for at least 5 consecutive days.

WITH ISLAND AS (
select 
	USER_ID,
    WORKOUT_DATE,
    DATE_SUB(WORKOUT_DATE, INTERVAL ROW_NUMBER() OVER(
		PARTITION BY USER_ID 
        ORDER BY WORKOUT_DATE
        ) DAY 
	) AS GAPS_IN_DAYS
from 
	user_workouts
)
SELECT
	USER_ID,
    COUNT(*) AS STREAK
FROM
	ISLAND
    GROUP BY USER_ID,GAPS_IN_DAYS
    HAVING STREAK >= 5;



CREATE TABLE app_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    app_id INT,
    launch_timestamp DATETIME,
    load_time_seconds DECIMAL(5,2)
);

INSERT INTO app_logs (app_id, launch_timestamp, load_time_seconds) VALUES 
(101, '2025-02-01 08:00:00', 2.5), 
(101, '2025-02-01 08:05:00', 3.1), 
(101, '2025-02-01 08:10:00', 2.8), -- 3 consecutive slow
(101, '2025-02-01 08:15:00', 1.2), -- Reset
(101, '2025-02-01 08:20:00', 2.9), 
(102, '2025-02-01 09:00:00', 4.0);

-- For each app, 
-- find the start and end time of periods where the app had at least 3 consecutive "slow" launches (load_time > 2.0).
WITH PREV_TABLE AS (
	SELECT 
		APP_ID,
		LAUNCH_TIMESTAMP,
		LOAD_TIME_SECONDS,
		LAG(LOAD_TIME_SECONDS) OVER(
			PARTITION BY APP_ID
			ORDER BY LAUNCH_TIMESTAMP
		) AS PREV_LOAD_TIME
	FROM 
		APP_LOGS
), SESSION_FLAG_TBL AS(
	SELECT
		APP_ID,
        LAUNCH_TIMESTAMP,
        LOAD_TIME_SECONDS,
        PREV_LOAD_TIME,
        CASE
			WHEN PREV_LOAD_TIME IS NULL THEN 1
            WHEN LOAD_TIME_SECONDS > 2.00 THEN 1
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TABLE
) 
SELECT 
	APP_ID,
    SESSION_FLAG,
    MIN(LAUNCH_TIMESTAMP) AS START_TIME,
    MAX(LAUNCH_TIMESTAMP) AS END_TIME,
    COUNT(*) AS STREAK_CT
FROM 
	SESSION_FLAG_TBL
    GROUP BY APP_ID,SESSION_FLAG;
    
    
    
    CREATE TABLE price_changes (
    product_id INT,
    change_date DATE,
    new_price DECIMAL(10,2)
);

-- We also need a Calendar table (common in DE)
CREATE TABLE calendar (
    date_day DATE PRIMARY KEY
);

INSERT INTO price_changes VALUES 
(5001, '2025-01-01', 999.00),
(5001, '2025-01-15', 899.00), -- Price dropped mid-month
(5001, '2025-02-01', 949.00);

-- Inserting first 31 days of 2025 into calendar
INSERT INTO calendar (date_day)
WITH RECURSIVE days AS (
  SELECT '2025-01-01' AS d
  UNION ALL
  SELECT DATE_ADD(d, INTERVAL 1 DAY) FROM days WHERE d < '2025-01-31'
)
SELECT d FROM days;
