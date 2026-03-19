DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(50),
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE sellers (
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(50),
    seller_city VARCHAR(50),
    rating DECIMAL(2,1)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    seller_id INT,
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
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



-- -----------------------------------------------------------------------------------

INSERT INTO users (user_id, user_name, city, signup_date) VALUES
(1, 'Ava', 'Phoenix', '2023-01-10'),
(2, 'Ben', 'Seattle', '2023-02-14'),
(3, 'Cara', 'Austin', '2023-03-01'),
(4, 'Dev', 'Phoenix', '2023-03-18'),
(5, 'Eli', 'Denver', '2023-04-22'),
(6, 'Fiona', 'Seattle', '2023-05-09'),
(7, 'Gabe', 'Austin', '2023-06-30'),
(8, 'Hana', 'Boston', '2023-07-11');

INSERT INTO sellers (seller_id, seller_name, seller_city, rating) VALUES
(101, 'TechWorld', 'San Jose', 4.8),
(102, 'HomeHive', 'Dallas', 4.3),
(103, 'FitMart', 'Austin', 4.6),
(104, 'BookBarn', 'Boston', 4.1),
(105, 'GizmoHub', 'Seattle', 4.9);

INSERT INTO products (product_id, product_name, category, price, seller_id) VALUES
(1001, 'Laptop Pro 14', 'Electronics', 1200.00, 101),
(1002, 'Wireless Mouse', 'Electronics', 25.00, 101),
(1003, 'Standing Desk', 'Furniture', 300.00, 102),
(1004, 'Office Chair', 'Furniture', 180.00, 102),
(1005, 'Yoga Mat', 'Fitness', 40.00, 103),
(1006, 'Dumbbell Set', 'Fitness', 90.00, 103),
(1007, 'SQL Mastery', 'Books', 55.00, 104),
(1008, 'Data Pipelines 101', 'Books', 65.00, 104),
(1009, 'Mechanical Keyboard', 'Electronics', 110.00, 105),
(1010, 'USB-C Dock', 'Electronics', 150.00, 105);

INSERT INTO orders (order_id, user_id, order_date, order_status) VALUES
(5001, 1, '2024-01-05', 'completed'),
(5002, 2, '2024-01-06', 'completed'),
(5003, 1, '2024-01-08', 'cancelled'),
(5004, 3, '2024-01-09', 'completed'),
(5005, 4, '2024-01-10', 'completed'),
(5006, 5, '2024-01-11', 'completed'),
(5007, 6, '2024-01-12', 'pending'),
(5008, 2, '2024-01-13', 'completed'),
(5009, 7, '2024-01-14', 'completed'),
(5010, 8, '2024-01-15', 'completed'),
(5011, 3, '2024-01-16', 'completed'),
(5012, 6, '2024-01-17', 'completed');

INSERT INTO order_items (order_item_id, order_id, product_id, quantity) VALUES
(1, 5001, 1001, 1),
(2, 5001, 1002, 2),
(3, 5002, 1003, 1),
(4, 5002, 1007, 1),
(5, 5003, 1009, 1),
(6, 5004, 1005, 3),
(7, 5004, 1006, 1),
(8, 5005, 1004, 1),
(9, 5005, 1002, 1),
(10, 5006, 1008, 2),
(11, 5006, 1007, 1),
(12, 5007, 1010, 1),
(13, 5008, 1001, 1),
(14, 5008, 1009, 1),
(15, 5009, 1003, 2),
(16, 5009, 1004, 1),
(17, 5010, 1005, 1),
(18, 5010, 1002, 4),
(19, 5011, 1006, 2),
(20, 5011, 1008, 1),
(21, 5012, 1010, 2),
(22, 5012, 1007, 1);




-- --------------------------------------------------------------------
DROP TABLE IF EXISTS shipment_events;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_name VARCHAR(50),
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE sellers (
    seller_id INT PRIMARY KEY,
    seller_name VARCHAR(50),
    seller_city VARCHAR(50),
    rating DECIMAL(2,1)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    seller_id INT,
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
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

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_date DATE,
    amount DECIMAL(10,2),
    payment_status VARCHAR(20),
    payment_method VARCHAR(20),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY,
    order_id INT,
    shipment_date DATE,
    carrier VARCHAR(30),
    delivery_status VARCHAR(20),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE shipment_events (
    event_id INT PRIMARY KEY,
    shipment_id INT,
    event_time DATETIME,
    event_type VARCHAR(30),
    hub_city VARCHAR(50),
    FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id)
);