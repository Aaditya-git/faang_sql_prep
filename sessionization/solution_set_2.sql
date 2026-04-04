-- a) Basic
-- Assign session_ids using a 30-minute inactivity rule.
WITH PREV_TBL AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM
		APP_EVENTS
    ),
MINUTE_RULE AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		CASE 
			WHEN PREV_TIME IS NULL THEN 1
			WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1 
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TBL
	),
SESSION_TBL AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
	FROM
		MINUTE_RULE
)
SELECT * FROM SESSION_TBL;

-- Count total sessions per user.
WITH PREV_TBL AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM
		APP_EVENTS
    ),
MINUTE_RULE AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		CASE 
			WHEN PREV_TIME IS NULL THEN 1
			WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1 
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TBL
	),
SESSION_TBL AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
	FROM
		MINUTE_RULE
)
SELECT 	
	USER_ID,
    COUNT(DISTINCT SESSION_ID) AS SESSION_CT
FROM 
	SESSION_TBL
    GROUP BY USER_ID;
    
-- b) Medium
-- For each session, calculate:
-- session_start
-- session_end
-- number of events
WITH PREV_TBL AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM
		APP_EVENTS
    ),
MINUTE_RULE AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		CASE 
			WHEN PREV_TIME IS NULL THEN 1
			WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1 
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TBL
	),
SESSION_TBL AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
	FROM
		MINUTE_RULE
) 
SELECT 
	USER_ID,
    SESSION_ID,
    MIN(EVENT_TIME) AS SESSION_START,
    MAX(EVENT_TIME) AS SESSION_END,
	COUNT(*) AS CN_OF_EVENTS
FROM 
	SESSION_TBL
    GROUP BY USER_ID,SESSION_ID; 
	

-- Find sessions where a purchase event occurred.
WITH PREV_TBLE AS (
SELECT
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
    LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
FROM 
	APP_EVENTS
),
TIME_GAP AS (
SELECT 
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
    CASE 
		WHEN PREV_TIME IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME, EVENT_TIME)>30 THEN 1 
        ELSE 0 
	END AS SESSION_FLAG 
FROM
	PREV_TBLE
),
SESSION_TBL AS (
SELECT 
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
    SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID 
FROM 
	TIME_GAP
)
SELECT 
	USER_ID,
    SESSION_ID
FROM 
	SESSION_TBL
    WHERE
     EVENT_TYPE =LOWER('PURCHASE')
    GROUP BY USER_ID,SESSION_ID;
	
-- For each user, compute the average number of events per session.
WITH PREV_TABLE AS(
	SELECT 
		USER_ID,
		EVENT_TYPE,
		EVENT_TIME,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM
		APP_EVENTS
    ),
TIME_GAP AS (
	SELECT
		USER_ID,
		EVENT_TYPE,
		EVENT_TIME,
		CASE
			WHEN PREV_TIME IS NULL THEN 1
			WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME, EVENT_TIME)>30 THEN 1 
			ELSE 0
		END AS SESSION_FLAG
	FROM 
		PREV_TABLE
),
SESSION_ID AS (
	SELECT 
		USER_ID,
		EVENT_TYPE,
		EVENT_TIME,
		SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
	FROM 
		TIME_GAP
),
CT_TBLE AS (
SELECT 
	USER_ID,
    SESSION_ID,
	COUNT(*) AS CT
FROM 
	SESSION_ID
    GROUP BY USER_ID,SESSION_ID
    )
SELECT 
	USER_ID,
    CT,
    SUM(CT) OVER(PARTITION BY USER_ID) AS SM
FROM CT_TBLE;
-- Identify sessions that start with 'open' and end with 'close'.
WITH PREV_TABLE AS (
	SELECT
		USER_ID,
		EVENT_TIME,
		EVENT_TYPE,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM 
		APP_EVENTS
),
TIME_GAP AS (
SELECT 
	USER_ID,
    EVENT_TYPE,
    EVENT_TIME,
    CASE 
		WHEN PREV_TIME IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1 
        ELSE 0
	END AS SESSION_FLAG
FROM 
	PREV_TABLE
),
SESSION_TABLE AS (
SELECT 
	USER_ID,
    EVENT_TYPE,
    EVENT_TIME,
    SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
FROM 
	TIME_GAP
), ROW_NUM AS (
SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY USER_ID,SESSION_ID ORDER BY EVENT_TIME ) AS RN_START,
    ROW_NUMBER() OVER(PARTITION BY USER_ID,SESSION_ID ORDER BY EVENT_TIME DESC) AS RN_END
FROM 
	SESSION_TABLE)
    SELECT 
		USER_ID,
        SESSION_ID
	FROM ROW_NUM 
		GROUP BY USER_ID, SESSION_ID
        HAVING 
			MAX(CASE WHEN RN_START=1 THEN EVENT_TYPE END) ='open'
            AND
            MAX(CASE WHEN RN_END = 1 THEN EVENT_TYPE END) = 'close'; 
		

-- c) HARD - FAANG LEVELLED
-- Assign session_ids where a new session starts if:
-- gap > 30 minutes OR
-- event_type = 'open'
WITH PREV_TBLE AS (
SELECT
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
    LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
FROM 
	APP_EVENTS
),
TIME_GAP AS (
SELECT 
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
    CASE 
		WHEN PREV_TIME IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME, EVENT_TIME)>30 THEN 1 
        WHEN EVENT_TYPE =LOWER('OPEN') THEN 1
        ELSE 0 
	END AS SESSION_FLAG 
FROM
	PREV_TBLE
),
SESSION_TBL AS (
SELECT 
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
    SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID 
FROM 
	TIME_GAP)
SELECT * FROM SESSION_TBL;
-- For each user, find the conversion rate:
-- sessions with purchase / total sessions

-- Find the longest session (by duration) across all users.

-- For each user, find the first event of every session.
WITH PREV_TABLE AS (
	SELECT
		USER_ID,
		EVENT_TIME,
		EVENT_TYPE,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM 
		APP_EVENTS
),
TIME_GAP AS (
SELECT 
	USER_ID,
    EVENT_TYPE,
    EVENT_TIME,
    CASE 
		WHEN PREV_TIME IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1 
        ELSE 0
	END AS SESSION_FLAG
FROM 
	PREV_TABLE
),
SESSION_TABLE AS (
SELECT 
	USER_ID,
    EVENT_TYPE,
    EVENT_TIME,
    SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
FROM 
	TIME_GAP
),
ROW_NUM AS (
SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY USER_ID,SESSION_ID ORDER BY EVENT_TIME) AS RN
FROM 
	SESSION_TABLE)
SELECT 
	USER_ID,
    EVENT_TYPE,
    EVENT_TIME,
    SESSION_ID
FROM 
	ROW_NUM
    WHERE RN =1;


-- Write a query to:
-- 20 MINS WINDOW
-- Assign a unique session_id to each event (format: user_id_sessionNumber).
WITH PREV_TABLE AS (
	SELECT 
		USER_ID,
        EVENT_TIMESTAMP,
		LAG(EVENT_TIMESTAMP) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS PREV_TIME
	FROM 
		WEB_EVENTS
    ), 
SESSION_FLAG AS (
	SELECT 
		USER_ID,
        EVENT_TIMESTAMP,
        CASE 
			WHEN PREV_TIME IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIMESTAMP)>20 THEN 1
            ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TABLE
	),
SESSION_TABLE AS(
	SELECT 
		USER_ID,
        EVENT_TIMESTAMP,
        SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS SESSION_ID
	FROM
		SESSION_FLAG
)
SELECT 
	*
FROM 
	SESSION_TABLE;


-- Calculate the start time, end time, and total duration (in minutes) for each session.
WITH PREV_TABLE AS (
	SELECT 
		USER_ID,
        EVENT_TIMESTAMP,
		LAG(EVENT_TIMESTAMP) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS PREV_TIME
	FROM 
		WEB_EVENTS
    ), 
SESSION_FLAG AS (
	SELECT 
		USER_ID,
        EVENT_TIMESTAMP,
        CASE 
			WHEN PREV_TIME IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIMESTAMP)>20 THEN 1
            ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TABLE
	),
SESSION_TABLE AS(
	SELECT 
		USER_ID,
        EVENT_TIMESTAMP,
        SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS SESSION_ID
	FROM
		SESSION_FLAG
)
SELECT
	USER_ID,
    SESSION_ID,
	MIN(EVENT_TIMESTAMP) AS SESSION_START,
    MAX(EVENT_TIMESTAMP) AS SESSION_END,
    TIMESTAMPDIFF(MINUTE,MIN(EVENT_TIMESTAMP),MAX(EVENT_TIMESTAMP)) AS TIME_DIFF
FROM 
	SESSION_TABLE
    GROUP BY USER_ID,SESSION_ID;


-- Identify the first and last event_type for each session.
    WITH PREV_TABLE AS (
	SELECT 
		USER_ID,
        event_type,
        EVENT_TIMESTAMP,
		LAG(EVENT_TIMESTAMP) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS PREV_TIME
	FROM 
		WEB_EVENTS
    ), 
SESSION_FLAG AS (
	SELECT 
		USER_ID,
        event_type,
        EVENT_TIMESTAMP,
        CASE 
			WHEN PREV_TIME IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIMESTAMP)>20 THEN 1
            ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TABLE
	),
SESSION_TABLE AS(
	SELECT 
		USER_ID,
        event_type,
        EVENT_TIMESTAMP,
        SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS SESSION_ID
	FROM
		SESSION_FLAG
),
NUMBERED_FRAME AS (
select 
	*,
    ROW_NUMBER() OVER(PARTITION BY USER_ID,SESSION_ID ORDER BY EVENT_TIMESTAMP) AS RN_START,
    ROW_NUMBER() OVER(PARTITION BY USER_ID,SESSION_ID ORDER BY EVENT_TIMESTAMP DESC) AS RN_END
from session_table
)
SELECT 
	USER_ID,
    SESSION_ID,
    RN_START,
    RN_END,
    MAX(CASE WHEN RN_START = 1 THEN EVENT_TYPE END) AS FIRST_EVENT,
    MAX(CASE WHEN RN_END = 1 THEN EVENT_TYPE END) AS LAST_EVENT
FROM 
	NUMBERED_FRAME
GROUP BY 
	USER_ID,SESSION_ID;
    

    
-- The "State-Reset" Sessionization Challenge

-- A session starts when a user logs in. However, a session must be terminated and a new one started if:
-- 1. There is a gap of 30 minutes or more.
-- 2. OR the user performs a security_checkpoint event (this forces a session reset regardless of time).
-- 3. OR the user changes their device_id.
with prev_tbl as (
	select 
		user_id,
		device_id,
        event_timestamp,
		event_type,
		lag(event_timestamp) over(partition by user_id order by event_timestamp) as prev_time,
		lag(device_id) over(partition by user_id order by event_timestamp) as prev_device
	from 
		security_logs
    ),
    time_diff as (
		select 
			user_id,
			device_id,
            event_timestamp,
			event_type,
			case 
				when prev_time is null then 1
                when prev_device is null then 1 
				when timestampdiff(minute,prev_time,event_timestamp)>30 then 1 
				WHEN LAG(event_type) OVER(PARTITION BY user_id ORDER BY event_timestamp) = 'security_checkpoint' THEN 1
				when device_id <> prev_device then 1
				else 0 
			end as session_flag
		from 
			prev_tbl
    ),
    session_table as (
		select 
			user_id,
			device_id,
            event_timestamp,
			event_type,
            sum(session_flag) over(partition by user_id order by event_timestamp) as session_id
		from 
			time_diff
    )
    select * from session_table;
-- Your Task:

-- Generate a session_id that increments based on the three conditions above.

-- For each session, calculate the total number of events and the "Lead Event" 
-- (the very first event type that triggered the session).

-- Identify "Short Sessions": sessions that lasted less than 5 minutes but had more than 10 events 
-- (potential bot behavior).


WITH base_events AS (
    SELECT 
        user_id,
        device_id,
        event_timestamp,
        event_type,
        LAG(event_timestamp) OVER(PARTITION BY user_id ORDER BY event_timestamp) AS prev_time,
        LAG(device_id) OVER(PARTITION BY user_id ORDER BY event_timestamp) AS prev_device,
        LAG(event_type) OVER(PARTITION BY user_id ORDER BY event_timestamp) AS prev_event
    FROM security_logs
),
session_identification AS (
    SELECT 
        *,
        CASE 
            WHEN prev_time IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE, prev_time, event_timestamp) >= 30 THEN 1 
            WHEN device_id <> prev_device THEN 1
            WHEN prev_event = 'security_checkpoint' THEN 1
            ELSE 0 
        END AS is_new_session
    FROM base_events
),
session_assignments AS (
    SELECT 
        user_id,
        event_type,
        event_timestamp,
        SUM(is_new_session) OVER(PARTITION BY user_id ORDER BY event_timestamp) AS session_no
    FROM session_identification
)
SELECT 
    user_id,
    session_no,
    MIN(event_timestamp) AS session_start,
    COUNT(*) AS event_count,
    -- Short Suspicious: Duration < 5 mins AND events > 10
    CASE 
        WHEN TIMESTAMPDIFF(MINUTE, MIN(event_timestamp), MAX(event_timestamp)) < 5 
             AND COUNT(*) > 10 THEN 1 
        ELSE 0 
    END AS is_short_suspicious
FROM session_assignments
GROUP BY 
    user_id, 
    session_no;

-- ------------------------------------------------------------------ --------------------------------- 
--   Define sessions based on a 30-minute inactivity gap.

-- BUT, if a session’s cumulative duration exceeds 240 minutes, force a new session ID to start at that event.

-- Report: user_id, session_id, original_start, forced_split_flag (1 if the session was split due to the 4-hour rule).
WITH PREV_TABLE AS (
	SELECT
		USER_ID,
        EVENT_TIMESTAMP,
		LAG(EVENT_TIMESTAMP) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS PREV_TIME
	FROM
		STREAM_LOGS
    ),
    TIME_DIFF AS (
		SELECT 
			USER_ID,
            EVENT_TIMESTAMP,
            PREV_TIME,
            CASE
				WHEN PREV_TIME IS NULL THEN 1
                WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIMESTAMP) > 30 THEN 1
                WHEN SUM(MINUTE(EVENT_TIMESTAMP)) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP)>240 THEN 1
                ELSE 0
			END AS SESSION_FLAG
		FROM 
			PREV_TABLE
    ),
    SESSION_TABLE AS (
    SELECT 
		USER_ID,
		EVENT_TIMESTAMP,
		PREV_TIME,
        SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIMESTAMP) AS SESSION_ID
	FROM 
		TIME_DIFF
    ) SELECT 
			* 
	FROM SESSION_TABLE;
    
  WITH base AS (
    SELECT
        event_id,
        user_id,
        event_timestamp,
        LAG(event_timestamp) OVER (
            PARTITION BY user_id
            ORDER BY event_timestamp
        ) AS prev_ts
    FROM stream_logs
),
gap_flagged AS (
    SELECT
        event_id,
        user_id,
        event_timestamp,
        CASE
            WHEN prev_ts IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE, prev_ts, event_timestamp) > 30 THEN 1
            ELSE 0
        END AS new_gap_session_flag
    FROM base
),
gap_sessions AS (
    SELECT
        event_id,
        user_id,
        event_timestamp,
        SUM(new_gap_session_flag) OVER (
            PARTITION BY user_id
            ORDER BY event_timestamp
            ROWS UNBOUNDED PRECEDING
        ) AS gap_session_id
    FROM gap_flagged
),
with_original_start AS (
    SELECT
        event_id,
        user_id,
        event_timestamp,
        gap_session_id,
        MIN(event_timestamp) OVER (
            PARTITION BY user_id, gap_session_id
        ) AS original_start
    FROM gap_sessions
),
forced_split_calc AS (
    SELECT
        event_id,
        user_id,
        event_timestamp,
        gap_session_id,
        original_start,
        FLOOR(
            TIMESTAMPDIFF(MINUTE, original_start, event_timestamp) / 240
        ) AS forced_bucket
    FROM with_original_start
),
final_labeled AS (
    SELECT
        event_id,
        user_id,
        event_timestamp,
        original_start,
        CASE
            WHEN forced_bucket > 0 THEN 1
            ELSE 0
        END AS forced_split_flag,
        CONCAT(gap_session_id, '_', forced_bucket) AS session_id
    FROM forced_split_calc
)
SELECT
    user_id,
    session_id,
    original_start,
    forced_split_flag
FROM final_labeled
ORDER BY user_id, event_timestamp;

-- The Challenge:

-- For each store, find the Top 2 products with the highest total revenue (Price * Quantity).

-- Tie-breaking Rule: If two products have the exact same revenue, 
-- rank the one with the higher total quantity sold first.

-- The Twist: You must return the results even for stores that have only one product sold, 
-- but you must exclude any product that has a "Returned" status 
-- in more than 20% of its total orders for that store.

select * from  product_sales;
WITH product_metrics AS (
    -- Step 1: Calculate metrics per store/product
    SELECT 
        store_id,
        product_name,
        SUM(CASE WHEN status = 'Sold' THEN quantity * unit_price ELSE 0 END) AS total_revenue,
        SUM(CASE WHEN status = 'Sold' THEN quantity ELSE 0 END) AS total_quantity,
        -- Calculate return rate: (Count of Returned / Total Count of records)
        COUNT(CASE WHEN status = 'Returned' THEN 1 END) * 1.0 / COUNT(*) AS return_rate
    FROM product_sales
    GROUP BY store_id, product_name
),
ranked_products AS (
    -- Step 2: Filter out high-return products and rank
    SELECT 
        store_id,
        product_name,
        total_revenue,
        total_quantity,
        RANK() OVER(
            PARTITION BY store_id 
            ORDER BY total_revenue DESC, total_quantity DESC
        ) AS rnk
    FROM product_metrics
    WHERE return_rate <= 0.20
)
SELECT 
    store_id,
    product_name,
    total_revenue,
    rnk
FROM ranked_products
WHERE rnk <= 2;