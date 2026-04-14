CREATE TABLE events (
event_id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT,
event_name VARCHAR(50),
event_time DATETIME
);

INSERT INTO events (user_id, event_name, event_time) VALUES
-- User 1: perfect funnel
(1, 'view_product', '2023-10-01 10:00:00'),
(1, 'add_to_cart', '2023-10-01 10:05:00'),
(1, 'purchase', '2023-10-01 10:10:00'),

-- User 2: skips add_to_cart
(2, 'view_product', '2023-10-01 11:00:00'),
(2, 'purchase', '2023-10-01 11:05:00'),

-- User 3: drops before purchase
(3, 'view_product', '2023-10-01 12:00:00'),
(3, 'add_to_cart', '2023-10-01 12:10:00'),

-- User 4: multiple views, should take earliest
(4, 'view_product', '2023-10-01 09:00:00'),
(4, 'view_product', '2023-10-01 09:05:00'),
(4, 'add_to_cart', '2023-10-01 09:10:00'),
(4, 'purchase', '2023-10-01 09:20:00'),

-- User 5: out-of-order insert but valid times
(5, 'add_to_cart', '2023-10-01 14:05:00'),
(5, 'view_product', '2023-10-01 14:00:00'),
(5, 'purchase', '2023-10-01 14:10:00'),

-- User 6: events but wrong order (invalid funnel)
(6, 'add_to_cart', '2023-10-01 15:00:00'),
(6, 'view_product', '2023-10-01 15:05:00'),
(6, 'purchase', '2023-10-01 15:10:00');
WITH vp_time_tbl AS (
    SELECT
        user_id,
        MIN(event_time) AS vp_time
    FROM events
    WHERE event_name = 'view_product'
    GROUP BY user_id
),
cart_time_tbl AS (
    SELECT
        vp.user_id,
        vp.vp_time,
        MIN(e.event_time) AS cart_time
    FROM events e
    JOIN vp_time_tbl vp
        ON vp.user_id = e.user_id
    WHERE e.event_name = 'add_to_cart'
      AND e.event_time > vp.vp_time
    GROUP BY vp.user_id, vp.vp_time
),
purchase_time_tbl AS (
    SELECT
        c.user_id,
        c.vp_time,
        c.cart_time,
        MIN(e.event_time) AS purchase_time
    FROM events e
    JOIN cart_time_tbl c
        ON c.user_id = e.user_id
    WHERE e.event_name = 'purchase'
      AND e.event_time > c.cart_time
    GROUP BY c.user_id, c.vp_time, c.cart_time
)
SELECT 1 AS step, COUNT(*) AS user_count
FROM vp_time_tbl
UNION ALL
SELECT 2 AS step, COUNT(*) AS user_count
FROM cart_time_tbl
UNION ALL
SELECT 3 AS step, COUNT(*) AS user_count
FROM purchase_time_tbl;