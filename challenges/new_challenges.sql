create database challenges_20apr;
use  challenges_20apr;

select * from song_plays;

-- Find all user_ids who played a song in the first week of January 2026,
--  but had zero activity in the last 7 days of January 2026.
with jan_players as (
	select 
		user_id
	from
		song_plays
		where played_at between '2026-01-01' and '2026-01-08'
		group by user_id
), last_7_days_table as (
	select 
		distinct user_id
	from
		song_plays
        where played_at between '2026-01-25' and '2026-01-31'
)
	select
		j.user_id,
        l.user_id
	from
		jan_players j 
        left join last_7_days_table l on
			j.user_id = l.user_id
		where l.user_id is null;

