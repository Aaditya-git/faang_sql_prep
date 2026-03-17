CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(50),
    country VARCHAR(50),
    signup_date DATE
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(50),
    price INT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    product_id INT,
    order_date DATE,
    quantity INT
);


INSERT INTO users VALUES
(1,'Alice','USA','2023-01-10'),
(2,'Bob','USA','2023-02-15'),
(3,'Charlie','Canada','2023-03-20'),
(4,'David','USA','2023-01-05'),
(5,'Eva','India','2023-02-10'),
(6,'Frank','India','2023-04-01');

INSERT INTO products VALUES
(1,'Laptop','Electronics',1000),
(2,'Phone','Electronics',700),
(3,'Tablet','Electronics',500),
(4,'Chair','Furniture',150),
(5,'Desk','Furniture',300);

INSERT INTO orders VALUES
(1,1,1,'2023-05-01',1),
(2,1,2,'2023-05-03',2),
(3,2,3,'2023-05-04',1),
(4,3,4,'2023-05-05',4),
(5,4,1,'2023-05-06',1),
(6,5,5,'2023-05-07',2),
(7,5,1,'2023-05-08',1),
(8,6,2,'2023-05-08',3),
(9,2,4,'2023-05-09',1),
(10,3,1,'2023-05-10',1),
(11,3,2,'2023-05-10',1);

-- ------------------------------------------------------------------------