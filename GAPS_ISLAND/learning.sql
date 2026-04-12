create database learn_gaps;
use learn_gaps;



Apple wants to find users who have logged into iCloud for consecutive days.;
Task: Identify the start date, end date, and the number of days for every consecutive login streak for each user.;
with islands as (
select 
	*,
    date_sub(login_date, 
		interval row_number() over(partition by user_id order by login_date) day
	) as day_diff,
    day(login_date) - row_number() over(partition by user_id order by login_date) as diff_in_numner
from 
	user_logins
    )
    select 
		user_id,
        min(login_date) as start_date,
        max(login_date) as end_date,
        count(*) as ct_of_streak
	from 
		islands
        group by user_id,day_diff; -- or either by diff_in_numner
        
        
with prev_time as (
select 
	*, 
    lag(end_time) over(partition by user_id order by start_time) as prev_end_time
from 
	user_sessions
),
session_flag as (
select
	user_id,
    start_time,
    end_time,
    prev_end_time,
    case
		when prev_end_time is null then 1
        when prev_end_time < start_time then 1 
        else 0
	end as end_flag
from
	prev_time
)
select 
	user_id,
    start_time,
    end_time,
    sum(end_flag) over(partition by user_id order by start_time) as summed_flag
from
	session_flag;
	
-- Let's try one that combines your knowledge.

-- Scenario: Apple Music identifies "Inactive" accounts. 
-- We want to find the longest period of inactivity for each user.
-- A "Gap" exists between the end_time of one session and the start_time of the next.
-- You need to find the largest of these gaps for each user.
with prev_table as(
select 
	user_id,
    start_time,
    end_time,
    max(end_time) over(partition by user_id order by start_time ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) as end_time_prev
from
	user_sessions
    ),
    session_flag_table as (
select 
	user_id,
    start_time,
    end_time,
    case 
		when end_time_prev is null then 1
        when end_time_prev < start_time then 1
        else 0
	end as session_flag
    from
	prev_table
    ),
    session_id_table as (
select
	*,
    sum(session_flag) over(partition by user_id order by start_time) as session_id
from
	session_flag_table
), 
final_table as (
select 
	user_id,
    min(start_time) as actual_start,
    max(end_time) as actual_end
from
	session_id_table
    group by user_id,session_id
),
prev_ac_table as (
select 
	user_id,
    actual_start,
    actual_end,
    lag(actual_end) over (partition by user_id order by actual_start) as prev_ac_end
from
	final_table
),
fin_table as (
	select 
		user_id,
        actual_start,
        actual_end,
        case 
			when prev_ac_end is null then 0
            else timestampdiff(hour,prev_ac_end,actual_start)
		end as hours_inactive
	from
    prev_ac_table)
select 
	user_id,
    max(hours_inactive) as max_inac_hours
from 
	fin_table
    group by user_id;
		
        
CREATE TABLE play_logs (
    user_id INT,
    play_time TIMESTAMP,
    duration_seconds INT
);

INSERT INTO play_logs VALUES
(1, '2024-01-01 10:00:00', 180), -- Binge 1
(1, '2024-01-01 10:05:00', 200), -- Binge 1
(1, '2024-01-01 10:10:00', 10),  -- BREAK (Gap)
(1, '2024-01-01 10:15:00', 45),  -- Binge 2
(1, '2024-01-01 10:20:00', 50),  -- Binge 2
(1, '2024-01-01 10:25:00', 60),  -- Binge 2
(2, '2024-01-01 11:00:00', 300); -- Binge 3

select * from play_logs;
WITH flagged_data AS (
    SELECT 
        *,
        -- Row Number 1: The "Real" timeline position
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY play_time) as overall_rn
    FROM play_logs
),
valid_only AS (
    SELECT 
        *,
        -- Row Number 2: The "Valid Only" timeline position
        ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY play_time) as valid_rn
    FROM flagged_data
    WHERE duration_seconds >= 30 -- FILTER HERE!
),
islands AS (
    SELECT 
        *,
        -- The Magic: (Timeline Pos) - (Valid Pos) = Constant Group ID
        (overall_rn - valid_rn) as island_id
    FROM valid_only
)
SELECT 
    user_id,
    COUNT(*) as binge_length,
    MIN(play_time) as binge_start,
    MAX(play_time) as binge_end
FROM islands
GROUP BY user_id, island_id
ORDER BY binge_length DESC;


CREATE TABLE play_logs (
    user_id INT,
    play_time TIMESTAMP,
    duration_seconds INT
);

INSERT INTO play_logs VALUES
(1, '10:00:00', 180), -- Binge 1
(1, '10:05:00', 200), -- Binge 1
(1, '10:10:00', 10),  -- BREAK (Bad row)
(1, '10:15:00', 45),  -- Binge 2
(1, '10:20:00', 50),  -- Binge 2
(1, '10:25:00', 60);  -- Binge 2



CREATE TABLE server_status (
    check_time TIMESTAMP,
    status VARCHAR(10)
);

INSERT INTO server_status VALUES
('2024-01-01 10:01:00', 'Green'),
('2024-01-01 10:02:00', 'Red'),   -- Start Red 1
('2024-01-01 10:03:00', 'Red'),   -- End Red 1
('2024-01-01 10:04:00', 'Yellow'),
('2024-01-01 10:05:00', 'Red'),   -- Start Red 2 (Separate!)
('2024-01-01 10:06:00', 'Green');


-- An Apple server reports its status every minute as either 'Green', 'Yellow', or 'Red'.
-- Task: Find the start and end time of every 'Red' period. 
-- If a server is 'Red' at 10:01 and 10:02, it's one period.

select 
	*,
    row_number() over(order by check_time) -
    row_number() over(partition by status order by check_time) as bvn
from 
	server_status;
    
CREATE TABLE theater_seats (
    seat_id INT, -- 1, 2, 3, 5, 6, 10
    is_available BOOLEAN
);

with summed as (
select 
	*,
    sum(is_available) over(order by seat_id) as sm
from 
	theater_seats
)
select
	seat_id,
    is_available,
    seat_id - sm
from
	summed;
    
CREATE TABLE map_searches (
    user_id INT,
    search_time TIMESTAMP,
    query VARCHAR(50)
);

INSERT INTO map_searches VALUES
(1, '2024-01-01 12:00:00', 'Coffee'),
(1, '2024-01-01 12:05:00', 'Donuts'), -- Within 5 mins (Same Session)
(1, '2024-01-01 12:20:00', 'Gas'),    -- 15 min gap (New Session)
(1, '2024-01-01 12:25:00', 'Park');   -- Within 5 mins (Same Session)



-- A session continues as long as the next search happens within 10 minutes of the previous one.

-- If more than 10 minutes pass, the next search starts a new session.
with prev_table as(
select 
	user_id,
    search_time,
    lag(search_time) over(partition by user_id order by search_time ) as prev_search_time,
    query
from 
	map_searches
),
session_flag_table as (
select
	user_id,
    search_time,
    query,
    case 
		when prev_search_time is null then 1
        when timestampdiff(minute,prev_search_time,search_time) > 10 then 1
		else 0
	end as session_flag
from 
	prev_table
),
session_id_table as(
select 
	user_id,
    search_time,
    query,
    sum(session_flag) over(partition by user_id order by search_time) as session_id
from 
	session_flag_table
)
select 
	user_id,
    min(search_time) as start_time,
    max(search_time) as end_time,
    count(*) as ct_per_session
from 
	session_id_table
    group by user_id,session_id;
    
    
CREATE TABLE inventory_reports (
    store_id INT,
    report_date DATE,
    units_sold INT
);

INSERT INTO inventory_reports VALUES
(101, '2024-03-01', 10),
(101, '2024-03-02', 15),
-- MISSING: March 3, 4, 5
(101, '2024-03-06', 12),
-- MISSING: March 7
(101, '2024-03-08', 20);

-- The Goal: Find the Start and End dates of the longest period 
-- where the system was offline (missing rows) for Store 101.

select * from inventory_reports;

with recursive calendar_spine as(
	select '2024-03-01' as date_col
    union all 
    select date_add(date_col, interval 1 day)
    from calendar_spine
    where
    date_col < '2024-03-10'
),
joined as (
select
	ir.store_id,
    ir.report_date,
    ir.units_sold,
    c.date_col
from
	calendar_spine c 
    left join  inventory_reports ir on 
		c.date_col = ir.report_date
	),
    filtered as (
select 
	store_id,
    report_date,
    date_col,
    row_number() over(order by date_col) as rn
from
	joined
    where report_date is null
    )
    select 
		min(date_col) as start_date,
		max(date_col) as end_Date,
        count(*) as total_off_days
	from 
		filtered;
        
        
CREATE TABLE hospital_occupancy (
    patient_id VARCHAR(5),
    start_time TIMESTAMP,
    end_time TIMESTAMP
);

INSERT INTO hospital_occupancy VALUES
('A', '2024-01-01 10:00:00', '2024-01-01 14:00:00'),
('B', '2024-01-01 12:00:00', '2024-01-01 15:00:00'), -- Overlaps A
('C', '2024-01-01 11:00:00', '2024-01-01 13:00:00'), -- Engulfed by A
('D', '2024-01-01 17:00:00', '2024-01-01 19:00:00'); -- Separate Island

with prev_time as (
select 
	*,
    max(end_time) over( order by start_time
    rows between unbounded preceding and 1 preceding) as prev_time
from 
	hospital_occupancy
),
session_flag_table as (
select 
	patient_id,
    start_time,
    end_time,
    prev_time,
    case
		when prev_time is null then 1 
        when prev_time < start_time then 1
        else 0
	end as session_flag
from 
	prev_time
),
session_id_tbl as (
select 
	patient_id,
    start_time,
    end_time,
    prev_time,
    sum(session_flag) over(order by start_time) as session_id
from
	session_flag_table
    )
select 
	session_id,
    min(start_time) as start_time,
    max(end_time) as end_time
from
	session_id_tbl
    group by session_id;
	