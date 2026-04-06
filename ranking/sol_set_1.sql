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
	USER_ID,
    SUM(TOTAL_SPENT) AS TOTAL
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
WITH JOINED AS (
SELECT
	U.USER_ID,
    U.CITY,
    O.ORDER_ID,
    O.ORDER_DATE
FROM
	USERS U 
	JOIN ORDERS O ON
		U.USER_ID = O.USER_ID
	WHERE
		O.ORDER_STATUS = LOWER('COMPLETED')
), RANKED AS (
	SELECT 
		*,
        ROW_NUMBER() OVER(
			PARTITION BY USER_ID 
			ORDER BY ORDER_DATE DESC
        ) AS RN_PER_USER
	FROM
		JOINED
),
ORDER_ITEMS_JOINED AS (
SELECT 
	R.USER_ID,
    R.CITY,
    R.ORDER_DATE,
    sum(OI.QUANTITY*OI.UNIT_PRICE) AS TOTAL_SPENT
FROM 
	RANKED R 
    JOIN ORDER_ITEMS OI ON
		R.ORDER_ID = OI.ORDER_ID
    WHERE R.RN_PER_USER =1
    GROUP BY R.USER_ID,R.CITY,R.ORDER_DATE
),-- rank users within each city by total order value and return the top 2 ranks per city with ties.
PARTITIONED AS (
SELECT 
*,
DENSE_RANK() OVER(PARTITION BY CITY ORDER BY TOTAL_SPENT DESC) AS RNK_PER_CITY
FROM
	ORDER_ITEMS_JOINED)
SELECT 
	USER_ID,
    CITY,
    ORDER_DATE,
    TOTAL_SPENT
FROM
	PARTITIONED
    WHERE RNK_PER_CITY <=2
    ORDER BY USER_ID;

        
-- For each city, rank users by number of completed orders descending. Break ties by total spend descending. 
-- Return the top 2 users per city using row-level ranking.
WITH JOINED AS(
SELECT
	U.USER_ID,
    U.CITY,
    O.ORDER_DATE,
    OI.QUANTITY * OI.UNIT_PRICE AS TOTAL_PRICE
FROM
	USERS U 
    JOIN ORDERS O ON
		U.USER_ID = O.USER_ID
	JOIN ORDER_ITEMS OI ON
		O.ORDER_ID = OI.ORDER_ID
	WHERE
		O.ORDER_STATUS = 'completed'
),
ORDER_COUNT AS (
SELECT
	USER_ID,
    CITY,
    TOTAL_PRICE,
    COUNT(*) OVER(
		PARTITION BY USER_ID
    ) AS COUNT_PER_USER,
    SUM(TOTAL_PRICE) OVER(
		PARTITION BY USER_ID
    ) AS TOTAL_SPENT
FROM
	JOINED
),
RANKED AS (
	SELECT
		USER_ID,
		CITY,
		TOTAL_PRICE,
		TOTAL_SPENT,
		ROW_NUMBER() OVER(
			PARTITION BY CITY
			ORDER BY COUNT_PER_USER DESC,TOTAL_SPENT DESC
		) AS RN_PER_USER
	FROM 
		ORDER_COUNT
)
SELECT 
	USER_ID,
    CITY,
    TOTAL_PRICE
FROM
	RANKED
    WHERE RN_PER_USER <=2;
-- rank users by number of completed orders descending. Break ties by total spend descending. 
WITH JOINED AS (
    SELECT
        U.USER_ID,
        U.CITY,
        O.ORDER_ID,
        OI.QUANTITY * OI.UNIT_PRICE AS TOTAL_PRICE
    FROM USERS U
    JOIN ORDERS O
        ON U.USER_ID = O.USER_ID
    JOIN ORDER_ITEMS OI
        ON O.ORDER_ID = OI.ORDER_ID
    WHERE O.ORDER_STATUS = 'completed'
),
ORDER_LEVEL AS (
    SELECT
        USER_ID,
        CITY,
        ORDER_ID,
        SUM(TOTAL_PRICE) AS ORDER_TOTAL
    FROM JOINED
    GROUP BY USER_ID, CITY, ORDER_ID
),
USER_LEVEL AS (
    SELECT
        USER_ID,
        CITY,
        COUNT(ORDER_ID) AS COMPLETED_ORDER_COUNT,
        SUM(ORDER_TOTAL) AS TOTAL_SPEND
    FROM ORDER_LEVEL
    GROUP BY USER_ID, CITY
),
RANKED AS (
    SELECT
        USER_ID,
        CITY,
        COMPLETED_ORDER_COUNT,
        TOTAL_SPEND,
        ROW_NUMBER() OVER (
            PARTITION BY CITY
            ORDER BY COMPLETED_ORDER_COUNT DESC, TOTAL_SPEND DESC
        ) AS RN_PER_CITY
    FROM USER_LEVEL
)
SELECT
    USER_ID,
    CITY,
    COMPLETED_ORDER_COUNT,
    TOTAL_SPEND
FROM RANKED
WHERE RN_PER_CITY <= 2;

-- For each department, take only the top 3 employees by salary using row-level ranking. 
-- Within that reduced set, rank again by hire_date ascending and return the earliest hired employee.
WITH RANKED AS (
SELECT
	DEPARTMENT_ID,
    EMPLOYEE_ID,
    SALARY,
    HIRE_DATE,
    ROW_NUMBER() OVER(
		PARTITION BY DEPARTMENT_ID
        ORDER BY SALARY DESC
	) AS RANKED_USER
FROM
	EMPLOYEES
), RERANKED AS (
SELECT 
	*,
    DENSE_RANK() OVER (
		PARTITION BY  DEPARTMENT_ID
        ORDER BY hire_date 
    ) AS RERANKED
FROM
	RANKED
    WHERE RANKED_USER <=3
)
SELECT
	DEPARTMENT_ID,
    EMPLOYEE_ID,
    SALARY,
    HIRE_DATE
FROM 
	RERANKED
    WHERE RERANKED = 1;
    
-- For each user, rank their completed orders by total order value descending. 
-- Then, across all users, find the users whose 2nd ranked order has the highest value. Return all ties.
WITH FILTERED_JOIN AS (
SELECT	
	O.USER_ID,
	O.ORDER_ID,
	O.ORDER_DATE,
	SUM(OI.QUANTITY * OI.UNIT_PRICE) AS TOTAL_SPENT
FROM
	ORDERS O 
    JOIN ORDER_ITEMS OI ON
		O.ORDER_ID = OI.ORDER_ID
	WHERE
		O.ORDER_STATUS = 'completed'
        GROUP BY O.USER_ID,O.ORDER_ID, O.ORDER_DATE
), 
RANKED AS(
SELECT
    USER_ID,
	ORDER_ID,
    TOTAL_SPENT,
    DENSE_RANK() OVER(
		PARTITION BY USER_ID 
        ORDER BY TOTAL_SPENT DESC
    ) AS RANK_PER_USER 
FROM
	FILTERED_JOIN
)
SELECT
	USER_ID,
    ORDER_ID,
    TOTAL_SPENT,
    DENSE_RANK() OVER(
        ORDER BY TOTAL_SPENT DESC
    ) AS RMK
FROM
	RANKED 
    WHERE RANK_PER_USER = 2;

-- For each city, find the user(s) with the highest completed-order spend, 
-- but only among users whose single largest completed order is not the highest in their city.

SELECT
	U.USER_ID,
    U.CITY,
    SUM(OI.UNIT_PRICE * OI.QUANTITY) AS TOTAL_SPENT
FROM
	USERS U 
    JOIN ORDERS O ON
		U.USER_ID = O.USER_ID
	JOIN ORDER_ITEMS OI ON
		O.ORDER_ID = OI.ORDER_ID
	WHERE 
		O.ORDER_STATUS = 'completed'
        GROUP BY U.USER_ID,U.CITY
)















