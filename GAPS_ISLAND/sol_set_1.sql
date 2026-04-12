select * from user_activity;
-- For each user, group consecutive activity dates into streaks (islands).
WITH DAY_OF AS (
SELECT
	USER_ID,
    ACTIVITY_DATE,
    DAY(ACTIVITY_DATE) -  ROW_NUMBER() OVER(PARTITION BY USER_ID ORDER BY ACTIVITY_DATE ) AS DAY_OF_ACTIVITY
FROM
	user_activity
)
SELECT 
	USER_ID,
    MIN(ACTIVITY_DATE) AS START_DATE,
    MAX(ACTIVITY_DATE) AS END_DATE,
    COUNT(*) AS STREAK_LENGTH
FROM
	DAY_OF
    GROUP BY USER_ID,DAY_OF_ACTIVITY;
    
    
    
-- Problem 2: Longest Streak per User
-- For each user, find:
-- the longest consecutive activity streak length


WITH DAY_OF AS (
SELECT
	USER_ID,
    ACTIVITY_DATE,
    DAY(ACTIVITY_DATE) -  ROW_NUMBER() OVER(PARTITION BY USER_ID ORDER BY ACTIVITY_DATE ) AS DAY_OF_ACTIVITY
FROM
	user_activity
),
FILTERED AS (
SELECT 
	USER_ID,
    MIN(ACTIVITY_DATE) AS START_DATE,
    MAX(ACTIVITY_DATE) AS END_DATE,
    COUNT(*) AS STREAK_LENGTH
FROM
	DAY_OF
    GROUP BY USER_ID,DAY_OF_ACTIVITY
    )
SELECT 
	USER_ID,
	MAX(STREAK_LENGTH) 
FROM FILTERED
GROUP BY USER_ID;



-- For each user:
-- find longest consecutive daily streak
-- break ties using earliest start date
-- dedupe multiple events per day

-- Return:
-- user_id
-- start_date
-- end_date
-- streak_length

WITH dedup AS (
    SELECT DISTINCT
        user_id,
        DATE(event_time) AS activity_date
    FROM user_events
),
grp AS (
    SELECT
        user_id,
        activity_date,
        DATE_SUB(
            activity_date,
            INTERVAL ROW_NUMBER() OVER (
                PARTITION BY user_id
                ORDER BY activity_date
            ) DAY
        ) AS grp_key
    FROM dedup
) SELECT * FROM GRP;


-- Problem 2

-- Using the same user_events table, 
-- find all activity islands where a user can miss at most 1 calendar day inside the island.

-- Rules:
-- multiple events on the same day count as one active day
-- days can be out of order in the table
-- a gap of 1 missing day is still part of the same island
-- a gap of 2 or more missing days starts a new island
with dedup as (
	select
		distinct 
        user_id,
        date(event_time) as activity_date
	from
		user_events
) ,
filtered as (
select 
	user_id,
    activity_date,
    lag(activity_date) over(partition by user_id order by activity_date) as prev_date
from dedup
),
session_flag as(
select 
	user_id,
    activity_date,
    prev_date,
    case 
		when prev_date is null then 1
        when datediff(activity_date,prev_date)>2 then 1
        else 0
	end as session_flag
from filtered),
grped_table as (
select 
	user_id,
    activity_date,
    sum(session_flag) over(partition by user_id order by activity_date) as grp_id
from
	session_flag)
    select 
		user_id,
        min(activity_date) as start_date,
        max(activity_date) as end_date,
        count(*) as streak_length,
        DATEDIFF(MAX(activity_date), MIN(activity_date)) + 1 - COUNT(*) AS missing_day_count
	from 
		grped_table
        group by user_id, grp_id;
        
	select * from user_events;
    
	use gapsisland;
CREATE TABLE service_status (
    service_name VARCHAR(20),
    check_time TIMESTAMP,
    status VARCHAR(10) -- 'Up' or 'Down'
);



-- The Scenario:
-- Apple’s iCloud services are monitored every hour. If a service is 'Down', 
-- we need to find the start and end time of every consecutive outage period.
WITH island_groups AS (
    SELECT
        service_name,
        check_time,
        status,
        -- We subtract the row_number from the check_time. 
        -- If check_times are 1 hour apart and row_numbers are 1 unit apart, 
        -- the result remains CONSTANT for consecutive rows.
        DATE_SUB(check_time, INTERVAL ROW_NUMBER() OVER(PARTITION BY service_name, status ORDER BY check_time) HOUR) as island_id
    FROM
        service_status
)
SELECT 
    service_name,
    status,
    MIN(check_time) as outage_start,
    MAX(check_time) as outage_end,
    COUNT(*) as hours_down
FROM 
    island_groups
WHERE 
    status = 'Down'
GROUP BY 
    service_name, status, island_id
ORDER BY 
    outage_start;
-- The "Hidden" Difficulty:
-- If a service is down at 1 PM, 2 PM, and 3 PM, that is one island (outage) lasting 3 hours. 
-- If it's down at 1 PM and 5 PM, those are two separate islands.

-- Find the start and end time for every "Down" streak.

select * from service_status;

