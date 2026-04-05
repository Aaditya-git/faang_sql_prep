-- c) HARD - FAANG LEVELLED
-- For each department, find employees whose salary is in the top 3 distinct salaries within that department.
WITH JOINED AS (
	SELECT
		D.DEPARTMENT_ID AS DEPT_ID,
		E.EMPLOYEE_ID AS EMP_ID,
        E.SALARY AS EMP_SALARY
	FROM
		DEPARTMENTS D 
        JOIN EMPLOYEES E ON
			D.DEPARTMENT_ID = E.DEPARTMENT_ID
), RANKED AS (
	SELECT
		DEPT_ID,
        EMP_ID,
        EMP_SALARY,
        DENSE_RANK() OVER(PARTITION BY DEPT_ID ORDER BY EMP_SALARY DESC) AS SAL_RANKING
	FROM
		JOINED
	)
    SELECT 
		DISTINCT DEPT_ID,
        EMP_ID,
		EMP_SALARY
	FROM
		RANKED
        WHERE SAL_RANKING <=3;

-- For each product category, find the product with the 2nd highest price. 
-- Return all ties if multiple products share that 2nd highest price.
WITH RANKED AS (
SELECT
	PRODUCT_ID,
	CATEGORY,
    PRICE,
    DENSE_RANK() 
	OVER(
		PARTITION BY CATEGORY
        ORDER BY PRICE DESC
    ) AS RANKING
FROM
	PRODUCTS
    )
    SELECT 
		*
	FROM
		RANKED
        WHERE RANKING=2;


-- For each city, find the user who spent the most across completed orders. 
-- If multiple users tie for the highest spend in a city, return all of them.
with joined as (
select
    u.city,
    o.user_id,
    oi.quantity * oi.unit_price as total_spent
from
	users u 
	join orders o on
		u.user_id = o.user_id
	join order_items oi on
		o.order_id = oi.order_id
	where
	o.order_status='completed'
),
grouped as (
select 
	user_id,
    city,
    CAST(SUM(total_spent) AS SIGNED) AS sm_amt
from 
	joined
    group by user_id,city
),
ranked as (
select 
	*,
    dense_rank() over(partition by city order by sm_amt desc) as rnk
from
	grouped)
select 
	user_id,
    city,
    sm_amt
from ranked where rnk = 1;

    
-- ----------------------------------------------------------------------------------
-- For each department, rank employees by salary descending and hire_date ascending. 
-- Return only employees whose row-number rank is 2 or 3, but only for departments having at least 4 employees.
WITH JOINED AS (
SELECT 
	D.DEPARTMENT_ID,
    E.EMPLOYEE_ID,
    E.SALARY,
    E.HIRE_DATE
FROM 
	DEPARTMENTS D 
	JOIN EMPLOYEES E ON
		D.DEPARTMENT_ID = E.DEPARTMENT_ID
	),
    RANKED AS (
    SELECT
		*,
        ROW_NUMBER() OVER(PARTITION BY DEPARTMENT_ID ORDER BY SALARY DESC, HIRE_DATE ASC) AS RNKED
	FROM
		JOINED
),
EMP_COUNT AS (
SELECT 
	*,
    COUNT(*) OVER(PARTITION BY DEPARTMENT_ID) AS COUNT_OF_EMPLOYEES
FROM 
	RANKED
)
SELECT 
	*
FROM 
	EMP_COUNT
    WHERE 
		COUNT_OF_EMPLOYEES>=4
        AND
        RNKED IN (2,3);





-- For each user, 
-- find their most recent completed order. Then, 
-- among those most recent completed orders only, 
-- rank users within each city by total order value and return the top 2 ranks per city with ties.








