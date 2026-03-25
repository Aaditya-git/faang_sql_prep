a) Basic

For each employee, show the salary rank within their department, with the highest salary ranked as 1.
For each completed order, show the previous completed order amount for the same user ordered by order_date.

b) Medium
3. For each completed order, show a running total of completed order amount for each user ordered by order_date and order_id.
4. For each department, return the employees who are in the top 2 highest salaries.
5. For each login record, show the number of days since the previous login for the same user.
6. For each product category, return the completed order with the highest amount. If multiple orders tie, keep all tied rows.
7. For each page view event, show the next page viewed by the same user within the same session ordered by view_time.

c) HARD - FAANG LEVELLED
8. For each completed order, show the user_id, order_id, order_date, amount, and the difference between the order amount and that user’s average completed order amount.
9. Using the transactions table, calculate a running account balance per customer ordered by transaction_time, where deposits and refunds increase balance, and purchases decrease balance.
10. For each user, find their longest streak of consecutive login days. Return user_id and longest_streak.

c) HARD - FAANG LEVELLED
11. For each completed order, return the user’s first completed order date and the number of days between the current completed order date and that first completed order date.

For each department, return the employee or employees whose salary is the second highest in that department.
For each user, return the completed orders where the order amount is greater than that user’s immediately previous completed order amount.
For each customer, identify the first transaction_time at which their running balance became negative. Return only those customers whose balance ever went negative.
For each product category, find the completed order or orders that contributed to the category’s highest running completed revenue by date, where running revenue is calculated within category ordered by order_date and order_id.
For each session_id, find the page view where the time gap from the previous page view in that same session was the largest. Return all ties within a session.
For each user, return the completed order or orders with the largest gap in days from that user’s previous completed order. Exclude each user’s first completed order.
For each department, compute the cumulative salary ordered by salary descending and employee_id ascending, then return the row where cumulative salary first reaches or exceeds 50 percent of the department’s total salary.
For each customer, return transaction rows where the transaction amount is greater than the average of that customer’s previous transactions only. Exclude rows that do not have any previous transaction.
For each user, segment their completed orders into sequence numbers by order_date and identify whether each order is in the first half or second half of that user’s completed order history based on row position.