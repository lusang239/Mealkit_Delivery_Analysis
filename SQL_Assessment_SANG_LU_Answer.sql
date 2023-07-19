-- SQL Assessment for HelloFresh
-- Name: SANG LU
-- DATE: 2023/06/15
-- Language: MySQL


-- Note: 
-- YEAR(delivery_date_ may be replaced by INT(LEFT(delivery_week),4)
-- revenue_eur may be NULL or 0 
-- Calculation of proportion of US-based csutomers: Total US-based customers chose to having a "Vegetarian Box" delivered in the past 7 days for each delivery date / All US-based customers

-- Primary Key for boxes_shipped: box_id
-- Primary Key for customers: customer_id & country
-- Primary Key for products: product_id

-- Q1: For each week of 2020 in the US, how many boxes did we deliver, and what revenue (in Euros) did those deliveries generate?
SELECT delivery_week,
    COUNT(box_id) AS NumberOfBoxesDelivered,
    SUM(revenue_eur) AS TotalRevenueGenerated
FROM boxes_shipped
WHERE YEAR(delivery_date) = 2020
    AND country = 'US'
GROUP BY 1
ORDER BY 1;

-- Q2: How many delivery_weeks did the years 2019 and 2020 have?
SELECT YEAR(delivery_date) AS year,
    COUNT(DISTINCT delivery_week) AS NumberOfDelivery_Weeks
FROM boxes_shipped
WHERE YEAR(delivery_date) = 2019
    OR YEAR(delivery_date) = 2020
GROUP BY 1;

-- Q3: Fetch the customer IDs of all HelloFresh customers in the US who received their box for free on January 15, 2021.
SELECT DISTINCT customer_id
FROM boxes_shipped
WHERE (
        revenue_eur = 0
        OR revenue_eur IS NULL
    )
    AND country = 'US'
    AND DATE_FORMAT(delivery_date, '%Y-%m-%d') = '2021-01-15';

-- Q4:What proportion of US-based customers chose to have a “Vegetarian Box” delivered in the past 7 days? Bonus points if you make the range dynamic.
WITH past7days_boxes_shipped AS (
    SELECT customer_id AS US_cusotmer_id,
        (
            CASE
                WHEN product_id = (
                    SELECT product_id
                    FROM products
                    WHERE product_name = 'Vegetarian Box'
                )
                AND DATEDIFF(CURDATE(), DATE(delivery_date)) BETWEEN 0 AND 7 THEN customer_id
                ELSE NULL
            END
        ) AS US_Vegetarians_id_past7days
    FROM boxes_shipped
    WHERE country = 'US'
)
SELECT ROUND(
        COUNT(DISTINCT US_Vegetarians_id_past7days) / COUNT(DISTINCT US_cusotmer_id) * 100,
        2
    ) AS %_US_Vegetarians_past7days
FROM past7days_boxes_shipped;

-- Extra Bonus: Make dynamic Range
CREATE FUNCTION DynamicRange(N INT) 
RETURNS FLOAT(2) AS
BEGIN 
    WITH past_N_days_boxes_shipped AS (
        SELECT customer_id AS US_cusotmer_id,
            (
                CASE
                    WHEN product_id = (
                        SELECT product_id
                        FROM products
                        WHERE product_name = 'Vegetarian Box'
                    )
                    AND DATEDIFF(CURDATE(), DATE(delivery_date)) BETWEEN 0 AND N THEN customer_id
                    ELSE NULL
                END
            ) AS US_Vegetarians_id_past7days
        FROM boxes_shipped
        WHERE country = 'US'
    )
    SELECT ROUND(
            COUNT(DISTINCT US_Vegetarians_id_past7days) / COUNT(DISTINCT US_cusotmer_id) * 100, 
            2
        ) AS %_US_Vegetarians_past7days
    FROM past_N_days_boxes_shipped;
END;

-- Extra Bonus: For each delivery date, what proportion of US-based customers chose to have a “Vegetarian Box” delivered in the past 7 days?
WITH US_customers AS (
    SELECT delivery_date,
        customer_id AS US_customer_id,
        (
            CASE
                WHEN product_id = (
                    SELECT product_id
                    FROM products
                    WHERE product_name = 'Vegetarian Box'
                ) THEN customer_id
                ELSE NULL
            END
        ) AS US_Vegetarians_id
    FROM boxes_shipped
    WHERE country = 'US'
)
SELECT delivery_date,
    ROUND(
        COUNT(DISTINCT US_Vegetarians_id) OVER (
            ORDER BY delivery_date RANGE BETWEEN 6 PRECEDING AND CURRENT ROW
        ) / COUNT(DISTINCT US_customer_id) * 100,
        2
    ) AS %_US_Vegetarians_past7days
FROM US_customers;

-- Q5: On average, how loyal are iOS users in the US compared to Android users? 
-- (Loyalty can be defined as the total count of boxes the customer has received ever since they joined HelloFresh)
SELECT device_type,
    -- COUNT(box_id) AS loyalty,
    -- COUNT(x.customer_id) AS customers,
    IFNULL(COUNT(box_id) / COUNT(x.customer_id), 0) AS avg_US_customer_loyalty
FROM boxes_shipped AS x
    JOIN customers AS c ON x.customer_id = c.customer_id
    AND x.country = c.country
    AND c.country = 'US'
GROUP BY 1;

-- Q6:How many customers have ordered more than one type of product since they joined HelloFresh?
SELECT COUNT(*) AS customers_OrderMoreThanOneProjects
FROM boxes_shipped
GROUP BY customer_id,
    country
HAVING COUNT(DISTINCT product_id) > 1;