-- a) Basic
-- 1. Assign a session_id to each event for every user where 
-- a new session starts if the time gap between consecutive events is more than 30 minutes.
WITH PREV_VALUE AS (
SELECT
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
	LAG(EVENT_TIME) OVER(
		PARTITION BY USER_ID
		ORDER BY EVENT_TIME
    ) AS PREV_VALUE
FROM
	EVENTS),
    SESSION AS (
SELECT 
	*,
    CASE 
		WHEN PREV_VALUE IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE,PREV_VALUE,EVENT_TIME) > 30 THEN 1 
        ELSE 0
	END AS NEW_SESSION_FLAG
FROM 
	PREV_VALUE)
SELECT 
	*,
    SUM(NEW_SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME)
FROM 
	SESSION;
-- 2. For each user, count the total number of sessions using the 30-minute inactivity rule.
WITH PREV_EV AS (
SELECT 	
	USER_ID,
    EVENT_TIME,
    LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
FROM
	EVENTS),
     SESSION_FLG AS (
SELECT 
	USER_ID,
    EVENT_TIME,
    CASE
		WHEN PREV_TIME IS NULL THEN 1
        WHEN timestampdiff(MINUTE,PREV_TIME,EVENT_TIME) > 30 THEN 1 ELSE 0
	END AS NEW_SESSION_FLAG
FROM 
	PREV_EV),
   SESSION_ID AS (
SELECT 
	USER_ID,
    SUM(NEW_SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
FROM 
	SESSION_FLG)
   SELECT 
		USER_ID,
		COUNT(DISTINCT SESSION_ID) AS S_ID
	FROM 
		SESSION_ID
        GROUP BY USER_ID;
-- 3. For each session, return:
-- user_id
-- session_id
-- session_start
-- session_end
WITH PREV_SESSION AS (
SELECT 
	USER_ID,
    EVENT_TIME,
	LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
FROM 
	EVENTS),
    TIME_DFF AS(
    
    SELECT 
		USER_ID,
        EVENT_TIME,
        CASE
			WHEN PREV_TIME IS NULL THEN 1
            WHEN timestampdiff(MINUTE,PREV_TIME, EVENT_TIME)> 30 THEN 1 
            ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_SESSION
    ),
    SESSION_ID_TABLE AS (
		SELECT 
			USER_ID,
            EVENT_TIME,
            SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
		FROM 
			TIME_DFF
    )
    SELECT 
		USER_ID,
        SESSION_ID,
        MIN(EVENT_TIME) AS SESSION_START,
        MAX(EVENT_TIME) AS SESSION_END
    FROM 
		SESSION_ID_TABLE
        GROUP BY USER_ID,SESSION_ID;

-- b) Medium
-- 4. For each session, calculate the total number of events and session duration (in minutes).
WITH PREV_EVENT AS (
SELECT 
	USER_ID,
    EVENT_TIME,
    LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
FROM 
	EVENTS),
    
    TIME_DIFF AS (
SELECT 
	USER_ID,
    EVENT_TIME,
    PREV_TIME,
    CASE
		WHEN PREV_TIME IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1 
        ELSE 0
	END AS SESSION_FLAG
FROM
	 PREV_EVENT),
     SESSION_ID_TBL AS (
		SELECT 
			USER_ID,
            EVENT_TIME,
            PREV_TIME,
            SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
		FROM 
			TIME_DIFF
     )
     SELECT 
    user_id,
    session_id,
    COUNT(*) AS total_events,
    TIMESTAMPDIFF(
        MINUTE,
        MIN(event_time),
        MAX(event_time)
    ) AS session_duration_minutes
FROM session_id_tbl
GROUP BY user_id, session_id;
	
	
	
	 
-- 5. Find the average session duration per user.

	
-- 6. Identify sessions where the user performed at least 3 events.
WITH PREV_TIME_TBL AS(
	SELECT
		USER_ID,
		EVENT_TIME,
        EVENT_TYPE,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM
		EVENTS
        ),
TIME_DIFF AS (
	SELECT
		USER_ID,
        EVENT_TIME,
        EVENT_TYPE,
		CASE
			WHEN PREV_TIME IS NULL THEN 1
			WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TIME_TBL
        ),
SESSION_FORMATION AS(
SELECT
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
    SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
FROM
	TIME_DIFF
)
SELECT 
	USER_ID,
    SESSION_ID,
    COUNT(*) AS EVNT_CT
FROM 
	SESSION_FORMATION
    GROUP BY USER_ID,SESSION_ID
    HAVING EVNT_CT >= 2
    ORDER BY USER_ID;


-- 7. For each user, find the longest session duration.
WITH PREV_TIME_TBL AS(
	SELECT
		USER_ID,
		EVENT_TIME,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM
		EVENTS
        ),
TIME_DIFF AS (
	SELECT
		USER_ID,
        EVENT_TIME,
        PREV_TIME,
		CASE
			WHEN PREV_TIME IS NULL THEN 1
			WHEN TIMESTAMPDIFF(MINUTE,PREV_TIME,EVENT_TIME)>30 THEN 1
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TIME_TBL
        ),
SESSION_FORMATION AS(
SELECT
	USER_ID,
    EVENT_TIME,
    PREV_TIME,
    SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
FROM
	TIME_DIFF
),
SESSION_DURATION AS (
SELECT 
	USER_ID,
    SESSION_ID,
    TIMESTAMPDIFF(MINUTE,MIN(EVENT_TIME),MAX(EVENT_TIME)) AS DIFF_IN_MINUTES
FROM 
	SESSION_FORMATION
    GROUP BY USER_ID, SESSION_ID),
    RANKKING_TBL AS(
SELECT
	*,
	DENSE_RANK() OVER(PARTITION BY USER_ID ORDER BY DIFF_IN_MINUTES DESC) AS RN
FROM SESSION_DURATION)

SELECT 
	USER_ID,
    SESSION_ID
FROM RANKKING_TBL
WHERE
	RN = 1;
-- c) HARD - FAANG LEVELLED
-- 8. Assign session_ids where a new session starts if:
-- time gap > 30 minutes OR
-- device changes
WITH base AS (
    SELECT
        event_id,
        user_id,
        event_time,
        event_type,
        device,
        LAG(event_time) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS prev_time,
        LAG(device) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS prev_device
    FROM events
),
flagged AS (
    SELECT
        event_id,
        user_id,
        event_time,
        event_type,
        device,
        CASE
            WHEN prev_time IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE, prev_time, event_time) > 30 THEN 1
            WHEN prev_device <> device THEN 1
            ELSE 0
        END AS new_session_flag
    FROM base
)
SELECT
    event_id,
    user_id,
    event_time,
    event_type,
    device,
    SUM(new_session_flag) OVER (
        PARTITION BY user_id
        ORDER BY event_time
        ROWS UNBOUNDED PRECEDING
    ) AS session_id
FROM flagged
ORDER BY user_id, event_time;

-- 9. For each user, find the session with the maximum number of events, and return:
-- user_id
-- session_id
-- event_count
WITH base AS (
    SELECT
        event_id,
        user_id,
        event_time,
        LAG(event_time) OVER (
            PARTITION BY user_id
            ORDER BY event_time
        ) AS prev_time
    FROM events
),
flagged AS (
    SELECT
        event_id,
        user_id,
        event_time,
        CASE
            WHEN prev_time IS NULL THEN 1
            WHEN TIMESTAMPDIFF(MINUTE, prev_time, event_time) > 30 THEN 1
            ELSE 0
        END AS new_session_flag
    FROM base
),
sessionized AS (
    SELECT
        event_id,
        user_id,
        event_time,
        SUM(new_session_flag) OVER (
            PARTITION BY user_id
            ORDER BY event_time
            ROWS UNBOUNDED PRECEDING
        ) AS session_id
    FROM flagged
),
session_counts AS (
    SELECT
        user_id,
        session_id,
        COUNT(*) AS event_count
    FROM sessionized
    GROUP BY user_id, session_id
),
ranked AS (
    SELECT
        user_id,
        session_id,
        event_count,
        DENSE_RANK() OVER (
            PARTITION BY user_id
            ORDER BY event_count DESC
        ) AS rn
    FROM session_counts
)
SELECT
    user_id,
    session_id,
    event_count
FROM ranked
WHERE rn = 1
ORDER BY user_id, session_id;
	


-- 10. Find users who had more than 1 session in a single day, using the 30-minute rule.
WITH PREV_TIME_TBL AS (
	SELECT
		USER_ID,
		EVENT_TIME,
		LAG(EVENT_TIME) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS PREV_TIME
	FROM 
		EVENTS
    ),
TIME_DIFF_TABLE AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		CASE 
			WHEN PREV_TIME IS NULL THEN 1
			WHEN TIMESTAMPDIFF(MINUTE, PREV_TIME,EVENT_TIME)>30 THEN 1
			ELSE 0
		END AS SESSION_FLAG
	FROM
		PREV_TIME_TBL
    ),
SESSION_ID_FRMTN AS (
	SELECT 
		USER_ID,
		EVENT_TIME,
		SUM(SESSION_FLAG) OVER(PARTITION BY USER_ID ORDER BY EVENT_TIME) AS SESSION_ID
	FROM
		TIME_DIFF_TABLE
    )
SELECT 
	user_id,
    DATE(event_time),
    COUNT(DISTINCT session_id)
FROM 
	SESSION_ID_FRMTN
    group by date(event_time),user_id;
	
    

