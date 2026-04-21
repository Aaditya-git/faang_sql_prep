select * from web_logs;
-- The Scenario: Wants to see how many users drop off between viewing an item and buying it.
-- Task: Calculate the conversion rate from view to purchase. 
-- A conversion only counts if the purchase happened after the view but within 24 hours.

WITH VW_TIME_TBL AS(
	SELECT
		USER_ID,
		MIN(EVENT_TIMESTAMP) AS MIN_VW_TIME
	FROM
		WEB_LOGS
		WHERE EVENT_NAME = LOWER('VIEW')
		GROUP BY USER_ID
),
PR_TIME_TBL AS (
	SELECT
		VW.USER_ID
	FROM
		VW_TIME_TBL VW 
		JOIN WEB_LOGS WL ON 
			VW.USER_ID = WL.USER_ID
		AND WL.EVENT_TIMESTAMP > VW.MIN_VW_TIME 
        AND WL.EVENT_TIMESTAMP <= DATE_ADD(VW.MIN_VW_TIME, INTERVAL 1 DAY)
		AND WL.EVENT_NAME = LOWER('PURCHASE')
		GROUP BY VW.USER_ID
)
SELECT 
	COUNT(V.USER_ID) AS NUMERATOR, 
    COUNT(PR.USER_ID) AS DENOMINATOR,
    ROUND(100*COUNT(V.USER_ID)/NULLIF(COUNT(PR.USER_ID),0),2) AS PRCTG
    
FROM VW_TIME_TBL V
	 LEFT JOIN  PR_TIME_TBL PR ON
    PR.USER_ID = V.USER_ID;
    
    
CREATE TABLE app_sales (
    app_id INT,
    category VARCHAR(20),
    total_revenue DECIMAL(10,2)
);

INSERT INTO app_sales VALUES 
(1, 'Games', 5000), (2, 'Games', 5000), (3, 'Games', 4000), (4, 'Games', 3000),
(5, 'Social', 8000), (6, 'Social', 7000), (7, 'Social', 9000);

SELECT * FROM APP_SALES;


-- The Scenario: 
-- Find the top 2 highest-grossing apps for each category. 
-- If two apps have the exact same revenue, they should share the same rank, and the next rank should be skipped

SELECT APP_ID,CATEGORY FROM(
SELECT
	APP_ID,
    CATEGORY,
    RANK() OVER(
		PARTITION BY CATEGORY 
		ORDER BY TOTAL_REVENUE DESC
    ) AS RANKED_CATEGORY
FROM
	APP_SALES ) T
WHERE RANKED_CATEGORY <=2;
    
    

 
CREATE TABLE daily_revenue (
    sale_date DATE,
    revenue DECIMAL(10,2)
);

INSERT INTO daily_revenue VALUES 
('2025-01-01', 1000), ('2025-01-02', 1050), 
('2025-01-03', 2000), ('2025-01-04', 1500),
('2025-01-05', 3000);

SELECT * FROM DAILY_REVENUE;
-- The Scenario: Identify "anomalous" days. 
-- Find any date where the total revenue was more than 50% higher than the previous day's revenue.

WITH PREV_VAL_TABLE AS(
SELECT
	SALE_DATE,
    REVENUE,
    SUM(REVENUE) OVER(ORDER BY SALE_DATE) AS RUNNING_SUM,
    LAG(REVENUE) OVER(
    ) AS PREV_AMT
FROM
	DAILY_REVENUE
)
SELECT 	
	SALE_DATE,
    REVENUE,
    RUNNING_SUM,
    PREV_AMT,
    CASE
		WHEN PREV_AMT IS NULL THEN 0
        WHEN RUNNING_SUM >= (0.5 * PREV_AMT) + PREV_AMT THEN 1
        ELSE 0
	END AS FLAG
FROM
	PREV_VAL_TABLE;
    
    
    CREATE TABLE connection_logs (
    device_id INT,
    connection_type VARCHAR(10), -- 'WiFi', 'Cellular'
    log_time DATETIME
);

INSERT INTO connection_logs VALUES 
(1, 'WiFi', '2025-01-01 10:00:00'), (1, 'Cellular', '2025-01-01 10:05:00'),
(1, 'WiFi', '2025-01-01 10:10:00'), (1, 'Cellular', '2025-01-01 10:15:00'),
(2, 'WiFi', '2025-01-01 10:00:00'), (2, 'WiFi', '2025-01-01 10:20:00');

SELECT * FROM CONNECTION_LOGS;

-- The Scenario: 
-- A device is "flapping" if it switches its connection type more than 3 times in 1 hour. 
-- Identify the device_ids that exhibited flapping behavior.
with prev_type_tbl as (
	select 
		*,
		lag(connection_type) over(
			partition by device_id 
			order by log_time
		) as prev_conn_type
	from 
		connection_logs
), filtered_table as(
	select
		*
	from
		prev_type_tbl
		where connection_type <> prev_conn_type
        or prev_conn_type is null
	)
    select
		*,
        count(*) over(
			partition by device_id
            order by log_time
            range between interval 1 hour preceding and current row
        ) as ct
	from
		filtered_table;



CREATE TABLE activity_stream (
    user_id INT,
    activity_time DATETIME
);

INSERT INTO activity_stream VALUES 
(1, '2025-01-01 09:00:00'), (1, '2025-01-01 09:15:00'), (1, '2025-01-01 09:20:00'),
(1, '2025-01-01 11:00:00'), (1, '2025-01-01 11:10:00'),
(2, '2025-01-01 09:00:00');

SELECT * FROM ACTIVITY_STREAM;
-- 5. Sessionization: "User Engagement"
-- The Scenario: Define a "Session" as a group of actions where each action occurs within 30 minutes of the previous one.
-- Task: For each user, return the session_id, start_time, end_time, and the count of events in that session.

WITH PREV_TIME AS(
SELECT 
	USER_ID,
    ACTIVITY_TIME,
    LAG(ACTIVITY_TIME) OVER(
		PARTITION BY USER_ID
        ORDER BY ACTIVITY_TIME
    ) AS PREV_ACT_TM
FROM	
	ACTIVITY_STREAM
),
SESSION_FLG_TBL AS(
SELECT 
	*,
    CASE 
		WHEN PREV_ACT_TM IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE, PREV_ACT_TM,ACTIVITY_TIME)>30 THEN 1
        ELSE 0
	END AS SESSION_FLAG
FROM 
	PREV_TIME
),
SESSION_ID_TBL AS (
	SELECT 
		USER_ID,
        ACTIVITY_TIME,
		SUM(SESSION_FLAG) OVER(
			PARTITION BY USER_ID
			ORDER BY ACTIVITY_TIME
		) AS SESSION_ID
	FROM
		SESSION_FLG_TBL
)
SELECT 
	USER_ID,
    SESSION_ID,
    MIN(ACTIVITY_TIME) AS SESSION_START,
    MAX(ACTIVITY_TIME) AS SESSION_END,
    COUNT(*) AS COUNT_OF_EVENTS
FROM 
	SESSION_ID_TBL
    GROUP BY USER_ID,SESSION_ID;
    
    
    CREATE TABLE server_status (
    check_time DATETIME,
    status VARCHAR(5) -- 'UP', 'DOWN'
);

INSERT INTO server_status VALUES 
('2025-01-01 00:00:00', 'UP'), ('2025-01-01 00:01:00', 'UP'),
('2025-01-01 00:02:00', 'DOWN'), ('2025-01-01 00:03:00', 'UP'),
('2025-01-01 00:04:00', 'UP'), ('2025-01-01 00:05:00', 'UP');

SELECT * FROM SERVER_STATUS;

-- The Scenario: We need to report server "Uptime Windows."
-- Task: Find the start and end of every continuous period where the server status was UP.
SELECT
	CHECK_TIME,
    STATUS,
    ROW_NUMBER() OVER(ORDER BY CHECK_TIME) -
    ROW_NUMBER() OVER(PARTITION BY STATUS ORDER BY CHECK_TIME) AS RN1
FROM
	SERVER_STATUS;



-- DATASET
CREATE TABLE music_logs (
    user_id INT,
    listen_date DATE
);

INSERT INTO music_logs VALUES 
(1, '2026-01-01'), (2, '2026-01-01'), 
(1, '2026-01-03'), 
(3, '2026-01-05');

select * from music_logs;

-- The Scenario: Apple Music wants a report of daily active users (DAU). However, if no one listens to music on a Tuesday, 
-- the logs simply don't have a row for Tuesday. A standard GROUP BY will skip that date.
-- Task: Generate a report for the first week of January that shows every single day, with a 0 if there were no listeners.

with recursive datee as (
	select '2026-01-01' as dated_log
    union all
    select date_add(dated_log,interval 1 day) from datee where dated_log<='2026-01-06'
)
select 
	dated_log,
	count(distinct ml.user_id) as ct
from 
	datee d left join music_logs ml on
    d.dated_log = ml.listen_date
    group by dated_log;
    
    
-- DATASET
CREATE TABLE specialist_sales (
    sale_id INT,
    employee_id INT,
    sale_amount INT,
    sale_time TIMESTAMP
);

INSERT INTO specialist_sales VALUES 
(1, 101, 4000, '2026-01-01 09:00:00'),
(2, 101, 5000, '2026-01-01 10:00:00'),
(3, 101, 3000, '2026-01-01 11:00:00'), -- This hits the 10k (total 12k). Reset!
(4, 101, 2000, '2026-01-01 12:00:00'); -- Starts fresh.

select * from specialist_sales;

-- The Scenario: An Apple Specialist has a sales quota of $10,000. 
-- We want to see how many transactions it takes them to hit that quota, 
-- and then reset the counter to zero and start counting toward the next $10,000.
-- Task: For each transaction, show the "Current Progress" toward the current $10k goal.


select 
	*,
    case 
		when sum(sale_amount) over(partition by employee_id order by sale_time) > 10000 then 0 
        else 1 end as flag
from
	specialist_sales;
    
    
    
    
    
CREATE TABLE store_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    app_id INT,
    event_type ENUM('ADD_TO_CART', 'PURCHASE'),
    event_time TIMESTAMP
);

select * from store_events;
-- Task: Find users who ADD_TO_CART but never PURCHASE the same app_id within the next 24 hours.

with filtered_addc as (
	select
		user_id,
		
		min(event_time) as min_add_cart_time
	from
		store_events
        group by user_id
)
	select 
		f.user_id,
        min(event_time) as min_pur_time
	from
		filtered_addc f 
        left join store_events se on
			f.user_id = se.user_id
		where
			se.event_type='purchase' and 
            se.event_time > min_add_cart_time
            and se.event_time > date_add(se.event_time,interval 24 hour)
            group by f.user_id;
            
SELECT 
    cart.user_id,
    cart.app_id,
    cart.event_time AS cart_time
FROM store_events cart
LEFT JOIN store_events purchase 
    ON  cart.user_id = purchase.user_id 
    AND cart.app_id = purchase.app_id 
    AND purchase.event_type = 'PURCHASE'
    -- The successful purchase must happen within 24 hours AFTER adding to cart
    AND purchase.event_time BETWEEN cart.event_time AND DATE_ADD(cart.event_time, INTERVAL 24 HOUR)
WHERE cart.event_type = 'ADD_TO_CART'
  -- This is the "Magic Filter": Keep only those who HAVE NO MATCHING PURCHASE
  AND purchase.event_id IS NULL;
  
  
  
  -- Create the main telemetry table
CREATE TABLE media_logs (
    event_id SERIAL PRIMARY KEY,
    user_id INT,
    event_time TIMESTAMP,
    action VARCHAR(50), -- 'play', 'login', 'stop', 'search'
    content_id INT,
    content_type VARCHAR(20), -- 'song', 'movie', 'podcast'
    country_code VARCHAR(3)
);

-- Insert sample data for testing
INSERT INTO media_logs (user_id, event_time, action, content_id, content_type, country_code) VALUES
(101, '2026-01-29 10:00:00', 'login', NULL, NULL, 'USA'),
(101, '2026-01-29 10:05:00', 'play', 5001, 'song', 'USA'),
(102, '2026-01-29 11:00:00', 'login', NULL, NULL, 'CAN'),
(102, '2026-01-29 11:15:00', 'play', 6001, 'movie', 'CAN'),
(101, '2026-01-30 09:00:00', 'login', NULL, NULL, 'USA'),
(101, '2026-01-31 08:30:00', 'login', NULL, NULL, 'USA'), -- User 101 has a 3-day streak
(103, '2026-01-31 12:00:00', 'login', NULL, NULL, 'USA'),
(103, '2026-01-31 12:10:00', 'play', 5001, 'song', 'USA'),
(102, '2026-02-02 14:00:00', 'play', 6002, 'movie', 'CAN'); -- User 102 watched movie 4 days later
            
            
            
select * from media_logs;

-- Find the top 3 songs per country. If multiple songs have the same play count, they should all occupy the same rank, and the next rank should be consecutive (e.g., 1, 1, 2).
-- Find all user_ids who played a song in the first week of January but have zero activity in the last 7 days.

CREATE TABLE server_logs (
    server_id INT,
    log_time TIMESTAMP
);

INSERT INTO server_logs VALUES 
(1, '2026-01-01 10:00:00'),
(1, '2026-01-01 10:01:00'),
(1, '2026-01-01 10:02:00'),
-- Gap here
(1, '2026-01-01 10:05:00'),
(1, '2026-01-01 10:06:00'),
(2, '2026-01-01 10:00:00');


select * from server_logs;

-- Identify the continuous "uptime" sessions for each server. 
-- Return the server_id, start_time, end_time, and how many minutes the session lasted.

WITH FILTERED_CTE AS(
	SELECT
		SERVER_ID,
		LOG_TIME,
		DATE_SUB(LOG_TIME, INTERVAL ROW_NUMBER() OVER(PARTITION BY SERVER_ID ORDER BY LOG_TIME) MINUTE) AS FLAG
	FROM
		SERVER_LOGS
)
	SELECT
		SERVER_ID,
        MIN(LOG_TIME) AS START_TIME,
        MAX(LOG_TIME) AS END_TIME
	FROM
		FILTERED_CTE
        GROUP BY SERVER_ID,FLAG;


CREATE TABLE product_prices (
    product_id INT,
    price_date DATE,
    price DECIMAL(10,2)
);

INSERT INTO product_prices VALUES 
(101, '2026-01-01', 999.00),
(101, '2026-01-02', 999.00),
(101, '2026-01-03', 899.00), -- Change
(101, '2026-01-04', 899.00),
(101, '2026-01-05', 999.00); -- Change back


SELECT * FROM PRODUCT_PRICES;

-- The Scenario: A retail product’s price changes over time. 
-- We want to group periods where the price stayed exactly the same.

-- Task: For each product, find the date ranges where the price was stable.
WITH PREV_PRICE_TABLE AS(
	SELECT
		PRODUCT_ID,
		PRICE_DATE,
		PRICE,
		LAG(PRICE) OVER(
			PARTITION BY PRODUCT_ID
			ORDER BY PRICE_DATE
		) AS PREV_PRICE
	FROM
		PRODUCT_PRICES
), SESSION_FLAG_TABLE AS(
	SELECT 
		*,
		CASE 
			WHEN PREV_PRICE IS NULL THEN 1
			WHEN PRICE - PREV_PRICE != 0 THEN 1
			ELSE 0
		END AS SESSION_FLAG
		
	FROM 
		PREV_PRICE_TABLE
),SESSION_ID_TABLE AS(
	SELECT 
		PRODUCT_ID,
        PRICE_DATE,
        PRICE,
        SESSION_FLAG,
        SUM(SESSION_FLAG) OVER(
			PARTITION BY PRODUCT_ID
			ORDER BY PRICE_DATE
        ) AS SESSION_ID
	FROM
		SESSION_FLAG_TABLE
)
SELECT 
	PRODUCT_ID,
    MIN(PRICE_DATE) AS START_RANGE_DATE,
    MAX(PRICE_DATE) AS END_RANGE_DATE
FROM
	SESSION_ID_TABLE
    GROUP BY PRODUCT_ID, SESSION_ID;



CREATE TABLE app_clicks (
    user_id INT,
    click_time TIMESTAMP
);

INSERT INTO app_clicks VALUES 
(1, '2026-01-01 10:00:00'),
(1, '2026-01-01 10:15:00'), -- 15 min gap (Same session)
(1, '2026-01-01 10:20:00'), -- 5 min gap (Same session)
(1, '2026-01-01 11:00:00'), -- 40 min gap (NEW SESSION)
(1, '2026-01-01 11:10:00'), -- 10 min gap (Same session)
(2, '2026-01-01 10:00:00');


-- A user clicks around the App Store. As long as they click something every 30 minutes, 
-- it's the same "session." If they disappear for more than 30 minutes and come back, that’s a new session.

-- The Task:
-- Find the start_time, end_time, and click_count for every session for each user.
WITH PREV_TABLE AS(
SELECT 
		*,
		LAG(CLICK_TIME) OVER(
			PARTITION BY USER_ID
			ORDER BY CLICK_TIME
		) AS PREV_CLK_TIME
	FROM
		APP_CLICKS
),SESSION_FLAG_TABLE AS (
	SELECT
		USER_ID,
        CLICK_TIME,
        PREV_CLK_TIME,
        CASE 
			WHEN PREV_CLK_TIME IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE,PREV_CLK_TIME,CLICK_TIME) > 30 THEN 1
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TABLE
), SESSION_ID_TABLE AS (
	SELECT 
		USER_ID,
        CLICK_TIME,
        SESSION_FLAG,
        SUM(SESSION_FLAG) OVER(
			PARTITION BY USER_ID
            ORDER BY CLICK_TIME
        ) AS SESSION_ID
	FROM
		SESSION_FLAG_TABLE
)
    SELECT 
		USER_ID,
        MIN(CLICK_TIME) AS START_TIME,
        MAX(CLICK_TIME) AS END_TIME
    FROM 
		SESSION_ID_TABLE
        GROUP BY USER_ID,SESSION_ID;
        


CREATE TABLE apple_employees (
    emp_id INT,
    emp_name VARCHAR(50),
    manager_id INT -- This refers back to emp_id
);

INSERT INTO apple_employees VALUES 
(1, 'Tim Cook', NULL),
(2, 'Jeff Williams', 1),
(3, 'Deirdre O’Brien', 1),
(4, 'John Ternus', 2),
(5, 'Sree Santhanam', 4);
SELECT * FROM APPLE_EMPLOYEES;

-- Return a table of all employees, their names, and their Manager's Name. 
-- If they don't have a manager (like the CEO), show "CEO".
SELECT 
    e.emp_name AS employee,
    -- If the manager's name is NULL (because the join found nothing), it's the CEO
    COALESCE(m.emp_name, 'CEO') AS manager
FROM apple_employees e
LEFT JOIN apple_employees m 
    ON e.manager_id = m.emp_id;
    
    
CREATE TABLE dev_revenue (
    developer_id INT,
    revenue DECIMAL(15, 2)
);

INSERT INTO dev_revenue VALUES 
(1, 5000000.00), (2, 3000000.00), (3, 1000000.00), 
(4, 500000.00),  (5, 300000.00),  (6, 100000.00), 
(7, 50000.00);
    
-- The Scenario: Apple wants to identify the "Whale" developers.
-- The Task: Find the developers who contribute to the top 80% of total App Store revenue.

WITH RUNNING_SUM_TABLE AS(
SELECT 
	*,
    SUM(REVENUE) OVER(ORDER BY REVENUE DESC) AS RUNNING_REVENUE,
	SUM(REVENUE) OVER() AS TOTAL_REVENUE
FROM 
	DEV_REVENUE
)
	SELECT 
		DEVELOPER_ID,
        REVENUE,
        RUNNING_REVENUE
	FROM
		RUNNING_SUM_TABLE
        WHERE
        RUNNING_REVENUE <= 0.8*TOTAL_REVENUE;
        
        

CREATE TABLE iphone_launches (
    order_id INT,
    store_id INT,
    order_time TIMESTAMP
);

INSERT INTO iphone_launches VALUES 
(1, 10, '2026-09-20 08:00:00'),
(2, 10, '2026-09-20 08:00:01'),
(3, 10, '2026-09-20 08:00:01'), -- Simultaneous with order 2
(4, 10, '2026-09-20 08:00:05'),
(5, 20, '2026-09-20 08:00:00'),
(6, 20, '2026-09-20 08:00:10');


-- The Task: For each order_id, 
-- find the difference in time between that order and the immediately preceding order in the same store.

-- The Twist: If two orders have the exact same order_time, 
-- the difference should be 0. You need to return the order_id and the gap_in_seconds.;

WITH PREV_TABLE AS (
	SELECT 
		ORDER_ID,
		ORDER_TIME,
		LAG(ORDER_TIME) OVER(
			ORDER BY ORDER_TIME
		) AS PREV_ORD_TIME
	FROM iphone_launches
)
SELECT
	ORDER_ID,
    ORDER_TIME,
    PREV_ORD_TIME,
    CASE
		WHEN PREV_ORD_TIME IS NULL THEN 0
        ELSE TIMESTAMPDIFF(SECOND, PREV_ORD_TIME,ORDER_TIME) 
	END AS DIFF_IN_MINUTES
FROM
	PREV_TABLE;
    
CREATE TABLE user_logins (
    user_id INT,
    login_date DATE
);

INSERT INTO user_logins VALUES 
(1, '2026-01-01'), (1, '2026-01-01'), -- Duplicate (Handle this!)
(1, '2026-01-02'), (1, '2026-01-03'), (1, '2026-01-04'), (1, '2026-01-05'),
(2, '2026-01-01'), (2, '2026-01-03'); -- Gap (Not a streak)

SELECT * FROM USER_LOGINS;
-- The Scenario: Apple wants to reward users who use the App Store for 5 or more consecutive days.
-- The Data: user_logins (user_id, login_date).
-- The Twist: A user might log in multiple times a day. 
-- You need to ensure you handle duplicates so the sequence doesn't break.

-- Task: Find the user_id, streak_start, streak_end, and days_count for all streaks that lasted at least 5 days.
WITH DEDUP AS(
	SELECT
		DISTINCT USER_ID,
		LOGIN_DATE
	FROM USER_LOGINS
), GROUPED AS(
	SELECT	
		USER_ID,
		LOGIN_DATE,
		DATE_SUB(LOGIN_DATE, INTERVAL ROW_NUMBER() OVER(PARTITION BY USER_ID ORDER BY LOGIN_DATE) DAY) AS FLAG
	FROM
		DEDUP
)
 SELECT 
	USER_ID,
    MIN(LOGIN_DATE) AS START_DATE,
    MAX(LOGIN_DATE) AS END_DATE,
    COUNT(*) AS DAYS_COUNT
FROM
	GROUPED
    GROUP BY USER_ID, FLAG
    HAVING COUNT(*)>=5;



CREATE TABLE inventory_status (
    check_id INT,
    check_time TIMESTAMP,
    is_in_stock INT -- 1 for Yes, 0 for No
);

INSERT INTO inventory_status VALUES 
(1, '2026-01-01 10:00:00', 1),
(2, '2026-01-01 10:30:00', 0), -- Island Starts
(3, '2026-01-01 11:15:00', 0),
(4, '2026-01-01 12:00:00', 0), -- Island Ends
(5, '2026-01-01 14:00:00', 1);

SELECT * FROM INVENTORY_STATUS;

-- The Scenario: An Apple Store tracks when the iPhone 16 is "In Stock." 
-- We want to find the longest period it stayed "Out of Stock" (Status = 0).

-- The Data: inventory_status (check_time, is_in_stock [1 or 0]).


select * from users;
select * from activities;

-- finding the cohort month from signup_date
-- checking activity in later months
-- calculating month 0, month 1, month 2 retention

with cohort_mth_table as(
	select 
		user_id,
		date_format(signup_date,'%Y-%m-01') as cohort_month
	from
		users
), diff_table as (
	select 
		c.user_id,
        c.cohort_month,
        a.activity_date,
        timestampdiff(month,cohort_month,activity_date) as cohort_number
	from
		cohort_mth_table c 
		join activities a on
			c.user_id = a.user_id
)
		select
			cohort_month,
            cohort_number,
            count(distinct user_id) as ct_of_id
		from
			diff_table
            group by cohort_month,cohort_number;
            
            
-- ----------------------------------
CREATE TABLE account_status_log (
    log_id INT PRIMARY KEY,
    account_id INT,
    status_date DATE,
    status VARCHAR(20)
);

INSERT INTO account_status_log (log_id, account_id, status_date, status) VALUES
(1, 101, '2024-01-01', 'active'),
(2, 101, '2024-01-10', 'paused'),
(3, 101, '2024-01-20', 'active'),
(4, 101, '2024-02-05', 'closed'),
(5, 102, '2024-01-03', 'active'),
(6, 102, '2024-01-15', 'active'),
(7, 102, '2024-02-01', 'paused'),
(8, 102, '2024-02-18', 'closed'),
(9, 103, '2024-01-07', 'paused'),
(10, 103, '2024-01-25', 'active'),
(11, 103, '2024-02-10', 'paused'),
(12, 103, '2024-03-01', 'closed'),
(13, 104, '2024-02-01', 'active'),
(14, 104, '2024-02-14', 'closed');


SELECT * FROM ACCOUNT_STATUS_LOG;

-- You are given a log of account status changes. 
-- An account can move between active, paused, and closed. 
-- Write a query to find every transition from one status to another, along with the transition date.

WITH PREV_TABLE AS(
	SELECT 
		ACCOUNT_ID,
		STATUS_DATE,
		STATUS,
		LAG(STATUS) OVER(
			PARTITION BY ACCOUNT_ID
			ORDER BY STATUS_DATE
		) AS PREV_STATUS,
        LAG(STATUS_DATE) OVER(
			PARTITION BY ACCOUNT_ID
            ORDER BY STATUS_DATE
        ) AS PREV_STATUS_DATE
	FROM
		ACCOUNT_STATUS_LOG
)SELECT 
    account_id,
    prev_status,
    status AS current_status,
    status_date AS transition_date
FROM prev_table
WHERE prev_status IS NOT NULL
  AND status <> prev_status
ORDER BY account_id, transition_date;



CREATE TABLE daily_revenue (
    revenue_date DATE PRIMARY KEY,
    revenue INT
);

DROP TABLE DAILY_REVENUE;

INSERT INTO daily_revenue (revenue_date, revenue) VALUES
('2024-01-01', 100),
('2024-01-02', 120),
('2024-01-04', 90),
('2024-01-07', 140),
('2024-01-08', 130),
('2024-01-10', 160);

SELECT * FROM DAILY_REVENUE;


WITH RECURSIVE CALENDAR_SPINE AS (
	SELECT '2024-01-01' AS START_DATE
    
    UNION ALL
    
    SELECT DATE_ADD(START_DATE, INTERVAL 1 DAY) FROM CALENDAR_SPINE 
    WHERE START_DATE < '2024-01-10'
),
JOINED AS (
	SELECT 
		C.START_DATE,
		D.REVENUE_DATE,
        D.REVENUE
	FROM
		CALENDAR_SPINE C 
        LEFT JOIN DAILY_REVENUE D ON
			C.START_DATE = D.REVENUE_DATE
)
SELECT 
	START_DATE AS REV_DATE,
    CASE 
		WHEN REVENUE IS NULL THEN 0 ELSE REVENUE END AS REVENUE
FROM 
	JOINED;
    
    
CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT
);

CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(50)
);

CREATE TABLE dim_region (
    region_id INT PRIMARY KEY,
    region_name VARCHAR(50)
);

CREATE TABLE fact_sales (
    sale_id INT PRIMARY KEY,
    date_id DATE,
    product_id INT,
    region_id INT,
    revenue INT,
    quantity INT,
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (region_id) REFERENCES dim_region(region_id)
);

INSERT INTO dim_date VALUES
('2023-12-01', 2023, 12, 1),
('2023-12-02', 2023, 12, 2),
('2024-01-01', 2024, 1, 1),
('2024-01-02', 2024, 1, 2),
('2024-02-01', 2024, 2, 1),
('2024-02-02', 2024, 2, 2);
INSERT INTO dim_product VALUES
(1, 'iPhone', 'Electronics'),
(2, 'MacBook', 'Electronics'),
(3, 'AirPods', 'Accessories');

INSERT INTO dim_region VALUES
(1, 'North America'),
(2, 'Europe');

INSERT INTO fact_sales VALUES
(1, '2023-12-01', 1, 1, 1000, 2),
(2, '2023-12-02', 2, 1, 2000, 1),
(3, '2024-01-01', 1, 1, 1500, 3),
(4, '2024-01-02', 3, 2, 500, 5),
(5, '2024-02-01', 2, 1, 2500, 2),
(6, '2024-02-02', 1, 2, 1800, 2);

SELECT * FROM FACT_SALES;

SELECT
	MONTH(DATE_ID),
    YEAR(DATE_ID),
    SUM(REVENUE)
FROM 
	FACT_SALES
    GROUP BY MONTH(DATE_ID), YEAR(DATE_ID);

-- Find month over month revenue growth.

WITH SUM_OF_SALE AS (
	SELECT
		MONTH(DATE_ID) AS MTH_OF_SALE,
		YEAR(DATE_ID) AS YR_OF_SALE,
		SUM(REVENUE) AS REVENUE_PER_MONTH
	FROM 
		FACT_SALES
		GROUP BY MONTH(DATE_ID), YEAR(DATE_ID)
), prev_TABLE AS (
	SELECT 
		MTH_OF_SALE,
        YR_OF_SALE,
        REVENUE_PER_MONTH,
        LAG(REVENUE_PER_MONTH) OVER(
            ORDER BY MTH_OF_SALE,YR_OF_SALE
        ) AS PREV_MONTH_SALE
	FROM
		SUM_OF_SALE
)
	SELECT
		MTH_OF_SALE,
        YR_OF_SALE,
        (REVENUE_PER_MONTH - PREV_MONTH_SALE)*100/NULLIF(PREV_MONTH_SALE,0) AS GRWTH_PERCN
	FROM
		PREV_TABLE;
        
-- Find year over year revenue growth (assume more data exists).

WITH SUM_OF_SALE AS (
	SELECT
		MONTH(DATE_ID) AS MTH_OF_SALE,
		YEAR(DATE_ID) AS YR_OF_SALE,
		SUM(REVENUE) AS REVENUE_PER_MONTH
	FROM 
		FACT_SALES
		GROUP BY MONTH(DATE_ID), YEAR(DATE_ID)
), prev_TABLE AS (
	SELECT 
		MTH_OF_SALE,
        YR_OF_SALE,
        REVENUE_PER_MONTH,
        LAG(REVENUE_PER_MONTH,12) OVER(
            ORDER BY MTH_OF_SALE,YR_OF_SALE
        ) AS PREV_MONTH_SALE
	FROM
		SUM_OF_SALE
)
	SELECT
		MTH_OF_SALE,
        YR_OF_SALE,
        (REVENUE_PER_MONTH - PREV_MONTH_SALE)*100/NULLIF(PREV_MONTH_SALE,0) AS GRWTH_PERCN
	FROM
		PREV_TABLE;
        
