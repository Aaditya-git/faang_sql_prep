DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS employee_performance;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS page_views;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(50),
    signup_date DATE,
    country VARCHAR(50)
);

CREATE TABLE page_views (
    view_id INT PRIMARY KEY,
    user_id INT,
    page_name VARCHAR(50),
    device_type VARCHAR(20),
    view_ts DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50),
    department_id INT,
    department_name VARCHAR(50),
    manager_id INT,
    hire_date DATE,
    base_salary DECIMAL(10,2)
);

CREATE TABLE employee_performance (
    review_id INT PRIMARY KEY,
    employee_id INT,
    review_month DATE,
    performance_score INT,
    projects_delivered INT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    order_status VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);