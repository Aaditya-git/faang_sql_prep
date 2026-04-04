-- Within each genre, rank artists by their total stream_count.

-- The Challenge: Instead of a Top N, 
-- return all artists who are in the top 10% of their genre by stream count.

-- If a genre has fewer than 10 artists, just return the #1 ranked artist for that genre.

select * from artist_Streams;
WITH PRCNT_RNK AS (
SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY genre ORDER BY stream_count DESC) as artist_rank,
    COUNT(ARTIST_NAME) OVER(PARTITION BY GENRE) AS CNT_ARTIST
FROM 
	ARTIST_STREAMS ),
    CALCULATIONS AS (
    SELECT 
		*,
        (artist_rank)*100/CNT_ARTIST AS PERCENTILE
	FROM
		PRCNT_RNK)
        SELECT 
			*
            FROM CALCULATIONS
        WHERE PERCENTILE <=10 OR
        (CNT_ARTIST<10 AND artist_rank =1);
-- -------------------------------------------------------------------------------------------------------------    
        
	CREATE TABLE monthly_revenue (
    service_id VARCHAR(20),
    report_month DATE,
    revenue DECIMAL(15,2)
);

INSERT INTO monthly_revenue VALUES
('TV+', '2023-01-01', 10000), 
('TV+', '2023-02-01', 9000),  -- Decline 1 (9000 < 10000)
('TV+', '2023-03-01', 8000),  -- Decline 2 (8000 < 9000) -> SUCCESS: Return this row
('TV+', '2023-04-01', 8500),  -- Increase (Not a decline)
('Music', '2023-01-01', 20000), 
('Music', '2023-02-01', 21000), 
('Music', '2023-03-01', 19000), -- Decline 1 (Only one consecutive)
('iCloud', '2023-01-01', 5000), 
('iCloud', '2023-02-01', 4500),  -- Decline 1
('iCloud', '2023-03-01', 4000),  -- Decline 2 -> SUCCESS: Return this row
('iCloud', '2023-04-01', 3500);  -- Decline 3 (Since 3500 < 4000 AND 4000 < 4500) -> SUCCESS: Return this row


WITH FORMATTED_DATE AS (
SELECT 
	 SERVICE_ID,
     DATE_FORMAT(REPORT_MONTH,'%Y-%m') AS YEAR_MONTHH,
     REVENUE
FROM
	MONTHLY_REVENUE),
    PREV_MONTH AS (
SELECT 
	*,
    LAG(REVENUE) OVER(PARTITION BY SERVICE_ID ORDER BY YEAR_MONTHH) AS PREV_MONTH,
    LAG(REVENUE,2) OVER(PARTITION BY SERVICE_ID ORDER BY YEAR_MONTHH) AS PREV_MONTH_TWO
FROM 
	FORMATTED_DATE
    ),
    FILTRED AS (
    SELECT 
    *,
    ROUND((REVENUE - PREV_MONTH)/PREV_MONTH*100,2) AS GROWTH_PCT,
    CASE 
		WHEN (REVENUE < PREV_MONTH) AND (PREV_MONTH < PREV_MONTH_TWO) THEN YEAR_MONTHH 
        END AS MONTH_FLAG
	FROM PREV_MONTH)
    SELECT 
		SERVICE_ID,
        REPORT_MONTH,
        REVENUE,
        PREV_MONTH,
        GROWTH_PCT
	FROM 
		FILTRED
        WHERE MONTH_FLAG IS NOT NULL;