-- a) Basic
-- For each user, calculate how many days it took them to perform their 
-- first activity after signing up.
WITH first_activity AS (
    SELECT
        u.user_id,
        u.signup_date,
        MIN(e.event_date) AS first_event_date
    FROM users u
    JOIN events e
        ON u.user_id = e.user_id
    GROUP BY u.user_id, u.signup_date
)
SELECT
    user_id,
    DATEDIFF(first_event_date, signup_date) AS days_to_first_activity
FROM first_activity;

-- For each user, find the number of unique days on which they were active after signing up.
WITH JOINED AS (
SELECT
	E.USER_ID AS E_ID,
	U.SIGNUP_DATE AS U_DATE,
    E.EVENT_DATE AS E_DATE
FROM
	USERS U 
    JOIN EVENTS E ON
		U.USER_ID = E.USER_ID)
	SELECT 
		E_ID,
        COUNT(DISTINCT E_DATE) AS CNT
	FROM 
		JOINED 
        WHERE E_DATE > U_DATE
        GROUP BY E_ID;


-- b) Medium

-- For each signup date, calculate how many users were active on:
-- the same day they signed up
-- the next day
-- two days after signup
WITH JOINED AS (
SELECT
	E.USER_ID AS E_ID,
	U.SIGNUP_DATE,
    E.EVENT_DATE
FROM 
	USERS U JOIN EVENTS E ON
		U.USER_ID = E.USER_ID)

SELECT
	COUNT(DISTINCT CASE WHEN (DATEDIFF(EVENT_DATE,SIGNUP_DATE) =0) THEN E_ID END) AS DAY_0_CT,
    COUNT(DISTINCT CASE WHEN (DATEDIFF(EVENT_DATE,SIGNUP_DATE) =1) THEN E_ID END) AS DAY_1_CT,
    COUNT(DISTINCT CASE WHEN (DATEDIFF(EVENT_DATE,SIGNUP_DATE) =2) THEN E_ID END) AS DAY_2_CT
FROM 
	JOINED
    GROUP BY SIGNUP_DATE;
    
-- For each signup date, calculate the percentage of users 
-- who came back exactly one day after signing up.
WITH FILTERED AS (
	SELECT
		COUNT(DISTINCT USER_ID)
	FROM 
		USERS
        GROUP BY SIGNUP_DATE
),
JOINED AS (
SELECT
    F.SIGNUP_DATE,
    E.EVENT_DATE AS E_DATE
FROM 
	FILTERED F JOIN EVENTS E ON
		F.USER_ID  = E.USER_ID)
	SELECT 
		COUNT(DISTINCT USER_ID)
	FROM 
		JOINED 
        WHERE 
        DATEDIFF(E_DATE,SIGNUP_DATE)=1;



-- For each user event, calculate how many days after signup that event occurred, and return all events with this value.
-- For each signup date, find the maximum number of days it took for any user in that group to return after signup.