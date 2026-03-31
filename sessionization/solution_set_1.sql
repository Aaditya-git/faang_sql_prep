-- a) Basic
-- 1. Assign a session_id to each event for every user where 
-- a new session starts if the time gap between consecutive events is more than 30 minutes.
SELECT
	USER_ID,
    EVENT_TIME,
    EVENT_TYPE,
	LAG(EVENT_TIME) OVER(
		PARTITION BY USER_ID
		ORDER BY EVENT_TIME
    ) AS PREV_VALUE
FROM
	EVENTS;
-- 2. For each user, count the total number of sessions using the 30-minute inactivity rule.

-- 3. For each session, return:
-- user_id
-- session_id
-- session_start
-- session_end