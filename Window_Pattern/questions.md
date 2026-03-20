a) Basic

For each employee review record, show employee_id, review_month, performance_score, and the previous month’s performance_score for the same employee.

For each completed order, show user_id, order_id, order_date, total order amount, and the user’s order amount rank with the most expensive order ranked highest within that user.

b) Medium
3. For each employee review record, show employee_id, department_name, review_month, performance_score, and the running average performance_score for that employee ordered by review_month.
4. For each employee review month, return only the top 2 employees per department based on performance_score. Show review_month, department_name, employee_id, and performance_score.
5. For each completed order, show user_id, order_id, order_date, total order amount, and the difference from that user’s immediately previous completed order amount.
6. For each page view, show user_id, view_ts, page_name, and assign a session number where a new session starts whenever the gap from the previous page view of the same user is more than 30 minutes.

c) HARD - FAANG LEVELLED
7. For each employee, identify the longest streak of consecutive months where performance_score increased compared to the immediately previous review month. Return employee_id and the length of the longest streak.
8. For each department and review month, show the employee or employees whose cumulative projects_delivered from January 2024 through that month is the highest within the department. Return department_name, review_month, employee_id, and cumulative projects.
9. Using completed orders only, calculate each user’s cumulative spend over time and return the first order where the user’s cumulative spend crossed 2000. Show user_id, order_id, order_date, order amount, and cumulative spend.
10. For completed orders, compute daily revenue and then return each date where the revenue was higher than both the previous day’s revenue and the next day’s revenue among dates that exist in the table. Show order_date and daily revenue.