select * from departments;
select * from employee_profiles;

-- Deduplicate employee_profiles by email using this business rule in order: 
-- highest source_priority, then latest updated_at, then highest profile_id. Return the retained rows.

WITH RANKED_EMPLOYEES AS (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY EMAIL ORDER BY SOURCE_PRIORITY DESC, UPDATED_AT, PROFILE_ID DESC) AS RNKED_ROWS
	FROM
		EMPLOYEE_PROFILES
)
SELECT 
	*
FROM
	RANKED_EMPLOYEES 
    WHERE RNKED_ROWS=1;

-- How many duplicate email groups exist in employee_profiles, 
-- and how many total rows would be removed after applying the deduplication rule?
WITH RANKED_EMPLOYEES AS (
	SELECT 
		*,
		ROW_NUMBER() OVER(PARTITION BY EMAIL ORDER BY SOURCE_PRIORITY DESC, UPDATED_AT, PROFILE_ID DESC) AS RNKED_ROWS
	FROM
		EMPLOYEE_PROFILES
)
SELECT 
	count(*) AS CT_OF_DISTINCT_EMPS
FROM
	RANKED_EMPLOYEES 
    WHERE RNKED_ROWS=1;
    
-- After deduplicating by email using the business rule above, 
-- return the headcount and average salary for each department.

WITH RANKED_TABLE AS (
	SELECT 
		*,
        ROW_NUMBER() OVER(PARTITION BY EMAIL ORDER BY SOURCE_PRIORITY DESC, UPDATED_AT, PROFILE_ID DESC) AS RANKED_ROWS
	FROM
		EMPLOYEE_PROFILES
),
DEDUP AS(
	SELECT
		*
	FROM
		RANKED_TABLE
        WHERE RANKED_ROWS=1
),
RANKED_SALARY AS (
SELECT 
	*,
    ROW_NUMBER() OVER(PARTITION BY DEPT_ID ORDER BY SALARY DESC) AS RANKED_SALARY
FROM 
	DEDUP
)
SELECT
	DEPT_ID,
    ROUND(AVG(SALARY),2) AS AVG_SALARY,
    COUNT(*) AS HEADCOUNT
FROM
	RANKED_SALARY
    GROUP BY DEPT_ID;
    
    
-- After deduplicating by email, return the 2nd highest distinct salary across the entire company.
	
WITH RANKED AS (
	SELECT
		*,
        ROW_NUMBER() OVER(
			PARTITION BY EMAIL 
			ORDER BY SOURCE_PRIORITY DESC, UPDATED_AT, PROFILE_ID DESC 
        ) AS RNKED_ROWS
	FROM 
		EMPLOYEE_PROFILES
),
FILTERED_TABLE AS(
	SELECT 
		*
	FROM 
		RANKED
		WHERE RNKED_ROWS =1
),
RANKED_SALARY AS(
	SELECT
		*,
		DENSE_RANK() OVER(ORDER BY SALARY DESC) AS DENSE_RANKED
	FROM FILTERED_TABLE
)
SELECT 
	*
FROM
	RANKED_SALARY
    WHERE DENSE_RANKED =2;
    
    

-- After deduplicating by email, return the 2nd highest distinct salary in each department. Exclude departments with fewer than 2 distinct salaries.
WITH RANKED_NUMBERS AS(
	SELECT
		*,
        ROW_NUMBER() OVER(PARTITION BY EMAIL ORDER BY SOURCE_PRIORITY DESC, UPDATED_AT DESC, PROFILE_ID DESC) AS RANKED_ROWS
	FROM
		EMPLOYEE_PROFILES
),
FILTERED_RANKED_SALARY AS (
SELECT
	*,
    DENSE_RANK() OVER(PARTITION BY DEPT_ID ORDER BY SALARY DESC) AS RANKED_SALARY 
FROM
	RANKED_NUMBERS
    WHERE RANKED_ROWS=1
)
SELECT
	*
FROM
	FILTERED_RANKED_SALARY
    WHERE RANKED_SALARY =2;
	
-- After deduplicating by email, return all employees whose salary is in the top 3 distinct salaries within their department.

-- After deduplicating by email, find the departments where the highest salary is at least 25% greater than the second-highest salary.
WITH RANKED_NUMBERS AS(
	SELECT
		*,
        ROW_NUMBER() OVER(PARTITION BY EMAIL ORDER BY SOURCE_PRIORITY DESC, UPDATED_AT DESC, PROFILE_ID DESC) AS RANKED_ROWS
	FROM
		EMPLOYEE_PROFILES
),
FILTERED_RANKED_SALARY AS (
SELECT
	*,
    DENSE_RANK() OVER(PARTITION BY DEPT_ID ORDER BY SALARY DESC) AS RANKED_SALARY 
FROM
	RANKED_NUMBERS
    WHERE RANKED_ROWS=1
),
GRP AS (
SELECT *,
	LEAD(SALARY) OVER(PARTITION BY DEPT_ID ORDER BY SALARY DESC) AS NEXT_SAL
FROM FILTERED_RANKED_SALARY
WHERE RANKED_SALARY<=2)
SELECT 
	* FROM GRP;
-- Among duplicate email groups, return the emails where the retained row chosen by the business rule is not the row with the latest updated_at.

-- After deduplicating by email, return employees whose salary rank is between 2 and 4 within their department, inclusive.

-- After deduplicating by email, find the department with the largest salary spread between its highest-paid and lowest-paid employee, and return that spread.
