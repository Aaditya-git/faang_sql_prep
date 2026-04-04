-- a) Basic
-- For each transaction, find the difference in amount compared to the previous transaction of the same user.
WITH PREV_TRSCN AS (
SELECT 
	*,
    LAG(AMOUNT) OVER(PARTITION BY USER_ID ORDER BY TRANSACTION_TIME) AS PREV_AMT
FROM 
	TRANSACTIONS
    )
    SELECT 
		*,
        AMOUNT - PREV_AMT
	FROM
		PREV_TRSCN;
-- For each employee, calculate the salary increase compared to their previous salary record.
WITH SRTED_DATA AS (
SELECT 
	*,
    LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY UPDATED_AT) AS SORTED_SAL
FROM
	EMPLOYEE_SALARIES 
    )
    SELECT 
		*,
         SALARY- SORTED_SAL AS SALARY_DIFF
	FROM 
		SRTED_DATA;
-- For each login event, compute the time difference (in minutes) from the previous login of the same user.
WITH PREV_LOGIN_TABLE AS (
SELECT 
	*,
    LAG(LOGIN_TIME) OVER(PARTITION BY USER_ID ORDER BY LOGIN_TIME) AS PREV_LOGIN
FROM 
	WEBSITE_LOGINS )

SELECT 
	*,
	TIMESTAMPDIFF(MINUTE,PREV_LOGIN,LOGIN_TIME)
FROM 
	PREV_LOGIN_TABLE;
    
    
    
-- b) Medium
-- For each user, find the percentage change in transaction amount compared to their previous transaction.
WITH PREV_TABLE AS (
	SELECT 
		*,
		LAG(AMOUNT) OVER(PARTITION BY USER_ID ORDER BY TRANSACTION_TIME) AS PREV_AMT
	FROM 
		TRANSACTIONS
    )
    SELECT 
		*,
        ROUND((AMOUNT-PREV_AMT)*1.0/NULLIF(PREV_AMT,0),2) AS PRCNT_CHANGE
    FROM 
		PREV_TABLE;
    
-- Identify transactions where the amount decreased compared to the previous transaction for that user.
WITH PREV_TABLE AS (
SELECT 
	TRANSACTION_ID,
	USER_ID,
    AMOUNT,
    LAG(AMOUNT) OVER(PARTITION BY USER_ID ORDER BY TRANSACTION_TIME) AS PREV_AMT
FROM
	TRANSACTIONS)
    SELECT
		*
	FROM
		PREV_TABLE
        WHERE AMOUNT<PREV_AMT;
-- For each employee, flag whether the salary increased, decreased, 
-- or stayed the same compared to the previous record.
WITH PREV_TABLE AS (
	SELECT 
		EMP_ID,
		DEPARTMENT_ID,
		SALARY,
		LAG(SALARY) OVER(PARTITION BY EMP_ID ORDER BY UPDATED_AT)  AS PREV_SALARY
	FROM
		EMPLOYEE_SALARIES
    )
    SELECT 
		*,
        CASE 
			WHEN PREV_SALARY IS NULL THEN 'FIRST_RECORD'
            WHEN PREV_SALARY < SALARY THEN 'INCREASED'
            WHEN PREV_SALARY > SALARY THEN 'DECREASED'
            ELSE 'SAME'
		END AS SALARY_FLAG
	FROM
		PREV_TABLE;

-- c) HARD - FAANG LEVELLED
-- For each user, find the largest drop in transaction amount between consecutive transactions.
WITH DIFF_TABLE AS (
SELECT 
	TRANSACTION_ID,
    USER_ID,
    AMOUNT,
    AMOUNT - LAG(AMOUNT) OVER(PARTITION BY USER_ID ORDER BY TRANSACTION_TIME) AS DIFF_AMT
FROM 
	TRANSACTIONS
),
FILTERED AS (
	SELECT *
	FROM DIFF_TABLE
	WHERE DIFF_AMT < 0
),
RANKED AS (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY USER_ID ORDER BY DIFF_AMT) AS RNK
	FROM FILTERED
)
SELECT *
FROM RANKED
WHERE RNK = 1;
-- For each user, compute the average time gap (in minutes) between consecutive logins.
WITH PREV_LOGINS AS(
SELECT
	 USER_ID,
     LOGIN_TIME,
     LAG(LOGIN_TIME) OVER(PARTITION BY USER_ID ORDER BY LOGIN_TIME) AS PREV_TIME
FROM
	WEBSITE_LOGINS
    ),
    DIFF_TIME AS(
    SELECT
		*,
        TIMESTAMPDIFF(MINUTE,PREV_TIME,LOGIN_TIME) AS DIFF_IN_MINUTE
	FROM
		PREV_LOGINS
    )
    SELECT 
		USER_ID,
        AVG(DIFF_IN_MINUTE) AS AVG_TIME
	FROM 
		DIFF_TIME
        GROUP BY USER_ID;
-- For each employee, find the maximum salary jump between consecutive updates.

-- Identify users whose transaction amount strictly increased across all their transactions.


select * from user_activity;
select * from stock_prices;
select * from orders;
-- 3. Questions
-- a) Basic
-- For each stock, calculate the daily price change compared to the previous available date.
SELECT 
	STOCK_ID,
    PRICE_DATE,
    PRICE - LAG(PRICE) OVER(PARTITION BY STOCK_ID ORDER BY PRICE_DATE) AS PREV_PRICE
FROM
	STOCK_PRICES;
-- For each user, compute the difference in steps compared to their previous recorded day.
SELECT 
	USER_ID,
    STEPS,
    STEPS - LAG(STEPS) OVER(PARTITION BY USER_ID ORDER BY ACTIVITY_DATE) AS DIFF_IN_STEPS
FROM
	USER_ACTIVITY;
--     
-- b) Medium
-- Identify for each stock the days where price increased 
-- compared to previous day AND the increase was greater than 3%.
WITH PREV_PRICE_TABLE AS(
	SELECT
		STOCK_ID,
		PRICE,
        PRICE_DATE,
		LAG(PRICE) OVER(PARTITION BY STOCK_ID ORDER BY PRICE_DATE) AS PREV_PRICE
	FROM 
		STOCK_PRICES
    )
SELECT
	*
FROM
	PREV_PRICE_TABLE
    WHERE PRICE>PREV_PRICE AND PRICE-PREV_PRICE>=0.03*PREV_PRICE;

-- For each user, find the longest streak where 
-- steps strictly increased compared to the previous recorded day.
WITH PREV_TABLE AS(
	SELECT
		USER_ID,
		ACTIVITY_DATE,
		STEPS,
		LAG(STEPS) OVER(PARTITION BY USER_ID ORDER BY ACTIVITY_DATE) AS PREV_STEPS
	FROM 
		USER_ACTIVITY
    ),
    STEP_FLAG_TBL AS(
			SELECT
				*,
				CASE 
					WHEN PREV_STEPS IS NULL THEN 1
					WHEN STEPS<=PREV_STEPS THEN 1 
					ELSE 0
				END AS STEPS_FLAG
			FROM 
				PREV_TABLE
        ),
        SUMMED_FLAG AS(
			SELECT
				*,
				SUM(STEPS_FLAG) OVER(PARTITION BY USER_ID ORDER BY ACTIVITY_DATE) AS STEP_SUM
			FROM
				STEP_FLAG_TBL
        ),
        STREAK AS(
			SELECT 
				USER_ID,
				STEP_SUM,
				COUNT(*) AS CT
			FROM SUMMED_FLAG
			GROUP BY USER_ID,STEP_SUM
        )
        SELECT
			USER_ID,
            MAX(CT) AS MAX_STREAK_LEN
		FROM
			STREAK
            GROUP BY USER_ID
        



-- For each user, calculate the difference between 
-- current order amount and the average of all their previous orders.



