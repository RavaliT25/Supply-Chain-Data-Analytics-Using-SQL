CREATE DATABASE Supply_chain_Star_schema;
USE Supply_chain_star_schema;
CREATE TABLE Dim_Date (
    date_key      INT PRIMARY KEY,
    full_date     DATE,
    day           INT,
    month         INT,
    month_name    VARCHAR(20),
    quarter       VARCHAR(2),
    year          INT,
    day_of_week   VARCHAR(10)
);

CREATE TABLE Dim_Customer (
    customer_key  INT PRIMARY KEY AUTO_INCREMENT,
    customer_id   INT,
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    city          VARCHAR(100),
    state         VARCHAR(100),
    segment       VARCHAR(50),
    zipcode       INT
);

CREATE TABLE Dim_Product (
    product_key      INT PRIMARY KEY AUTO_INCREMENT,
    product_id        INT,
    product_name      VARCHAR(255),
    category_name     VARCHAR(100),
    department_name   VARCHAR(100),
    product_price     DECIMAL(10,2)
);

CREATE TABLE Dim_Geography (
    geography_key  INT PRIMARY KEY AUTO_INCREMENT,
    order_city     VARCHAR(100),
    order_state    VARCHAR(100),
    order_region   VARCHAR(50)
);

CREATE TABLE Dim_Shipping (
    shipping_key   INT PRIMARY KEY AUTO_INCREMENT,
    order_type     VARCHAR(20),
    order_status   VARCHAR(30),
    shipping_mode  VARCHAR(30)
);

CREATE TABLE Fact_Order_Sales (
    date_key                 INT REFERENCES Dim_Date(date_key),
    customer_key             INT REFERENCES Dim_Customer(customer_key),
    product_key              INT REFERENCES Dim_Product(product_key),
    geography_key            INT REFERENCES Dim_Geography(geography_key),
    shipping_key              INT REFERENCES Dim_Shipping(shipping_key),
    order_id                  INT,                  -- degenerate dimension: kept for order-level counts
    order_item_id              INT PRIMARY KEY,
    quantity_sold              INT,
    sales_amount                DECIMAL(10,2),
    real_shipping_days           INT,
    scheduled_shipping_days       INT,
    shipping_delay_days            INT
);

-- Dim_Date: one row per distinct order date, decomposed into calendar attributes
INSERT INTO Dim_Date 
(date_key, full_date, day, month, month_name, quarter, year, day_of_week)

SELECT DISTINCT
    CAST(DATE_FORMAT(STR_TO_DATE(Order_Date, '%m/%d/%Y'), '%Y%m%d') AS UNSIGNED) AS Date_Key,
    STR_TO_DATE(Order_Date, '%m/%d/%Y') AS Full_Date,
    DAY(STR_TO_DATE(Order_Date, '%m/%d/%Y')) AS Day,
    MONTH(STR_TO_DATE(Order_Date, '%m/%d/%Y')) AS Month,
    MONTHNAME(STR_TO_DATE(Order_Date, '%m/%d/%Y')) AS Month_Name,
    CONCAT('Q', QUARTER(STR_TO_DATE(Order_Date, '%m/%d/%Y'))) Quarter_No,
    YEAR(STR_TO_DATE(Order_Date, '%m/%d/%Y')) AS Year,
    DAYNAME(STR_TO_DATE(Order_Date, '%m/%d/%Y')) AS Day_Name
FROM supplychain.order;

-- Dim_Customer: one row per customer, carried over as-is
INSERT INTO Dim_Customer (customer_id, first_name, last_name, city, state, segment, zipcode)
SELECT Id, First_Name, Last_Name, City, State, Segment, Zipcode
FROM supplychain.customer_info;

-- Dim_Product: category and department flattened onto the product row
INSERT INTO Dim_Product (product_id, product_name, category_name, department_name, product_price)
SELECT p.Product_Id, p.Product_Name, c.Name, d.Name, p.Product_Price
FROM supplychain.product_info p
JOIN supplychain.category c   ON p.Category_Id = c.Id
JOIN supplychain.department d ON p.Department_Id = d.Id;

-- Dim_Geography: distinct shipping destinations seen in orders
INSERT INTO Dim_Geography (order_city, order_state, order_region)
SELECT DISTINCT Order_City, Order_State, Order_Region FROM supplychain.order;

-- Dim_Shipping: distinct combinations of order type, status, and shipping mode
INSERT INTO Dim_Shipping (order_type, order_status, shipping_mode)
SELECT DISTINCT Type, Order_Status, Shipping_Mode FROM supplychain.order;

INSERT INTO Fact_Order_Sales
SELECT
    CAST(
        DATE_FORMAT(STR_TO_DATE(o.Order_Date, '%m/%d/%Y'), '%Y%m%d')
        AS UNSIGNED
    ) AS date_key,
    dc.customer_key,
    dp.product_key,
    dg.geography_key,
    ds.shipping_key,
    o.Order_Id,
    oi.Order_Item_Id,
    oi.Quantity,
    oi.Sales,
    o.Real_Shipping_Days,
    o.Scheduled_Shipping_Days,
    o.Real_Shipping_Days - o.Scheduled_Shipping_Days AS shipping_delay_days
FROM supplychain.ordered_items AS oi
JOIN supplychain.order AS o
    ON oi.Order_Id = o.Order_Id
JOIN Dim_Customer AS dc
    ON o.Customer_Id = dc.customer_id
JOIN Dim_Product AS dp
    ON oi.Item_Id = dp.product_id
JOIN Dim_Geography AS dg
    ON o.Order_City = dg.order_city
    AND o.Order_State = dg.order_state
    AND o.Order_Region = dg.order_region
JOIN Dim_Shipping AS ds
    ON o.Type = ds.order_type
    AND o.Order_Status = ds.order_status
    AND o.Shipping_Mode = ds.shipping_mode;
    

USE supply_chain_star_schema;
SELECT * FROM dim_customer;
SELECT * FROM dim_date;
SELECT * FROM dim_geography;
SELECT * FROM dim_product;
SELECT * FROM dim_shipping;
SELECT * FROM fact_order_sales;
--  Overall Sales Performance
-- Using the `Fact_Order_Sales` table, find:
-- Total sales amount
-- Average sales amount
-- Maximum sales amount
-- Minimum sales amount
-- Total quantity sold
SELECT SUM(sales_amount) AS Total_Sales,
	   AVG(sales_amount) AS avg_sales,
       MAX(sales_amount) AS Max_sales,
       MIN(sales_amount) AS Min_sales,
       SUM(quantity_sold) AS Total_Qnty
FROM fact_order_sales;


-- Find the total sales for each year, showing:
-- year
-- Total_Sales
-- Sort the result by year from earliest to latest.
SELECT * FROM fact_order_sales;
SELECT * FROM dim_date;

SELECT dd.year, SUM(f.sales_amount) AS Total_Sales
FROM fact_order_sales AS f
INNER JOIN dim_date AS dd ON f.date_key = dd.date_key
GROUP BY dd.year
ORDER BY dd.year ASC;

-- Find the Top 10 products based on total sales.
-- Return:
-- product_name
-- Total_Sales
-- Sort from highest sales to lowest sales.
SELECT * FROM fact_order_sales;
SELECT * FROM dim_product;
SELECT dp.product_name, SUM(f.sales_amount) AS Total_Sales
FROM fact_order_sales AS f
INNER JOIN dim_product AS dp ON f.product_key = dp.product_key
GROUP BY dp.product_name
ORDER BY Total_sales DESC
LIMIT 10;

-- Customer Analysis
-- Find the customer segment with the highest average sales amount per order item.
-- Return:
-- segment
-- Avg_Sales
-- Show all segments, sorted from highest average to lowest average.
SELECT * FROM dim_customer;
SELECT * FROM fact_order_sales;
SELECT dc.segment,AVG(f.sales_amount) AS Avg_sales
FROM fact_order_sales AS f
INNER JOIN dim_customer AS dc ON f.customer_key = dc.customer_key
GROUP BY dc.segment
ORDER BY Avg_sales DESC;

-- Geography Analysis
-- Find the total sales for each state.
-- Return:
-- order_state
-- Total_Sales
-- Show only states where total sales are greater than 50000
-- Sort from highest sales to lowest sales.
SELECT * FROM dim_geography;
SELECT * FROM fact_order_sales;

SELECT dg.Order_state, SUM(f.sales_amount) AS Total_sales
FROM fact_order_sales AS f
INNER JOIN dim_geography AS dg ON f.geography_key = dg.geography_key
GROUP BY dg.order_state
HAVING Total_sales  > 50000
ORDER BY Total_sales DESC;

-- Shipping Performance
-- Calculate the average shipping delay for each shipping mode.
-- Return:
-- shipping_mode
-- Avg_Shipping_Delay
-- Sort from highest average delay to lowest.
SELECT * FROM dim_shipping;
SELECT * FROM fact_order_sales;

SELECT ds.shipping_mode, AVG(f.shipping_delay_days) AS Avg_Shipping_Delay
FROM fact_order_sales AS f
INNER JOIN dim_shipping AS ds ON f.shipping_key = ds.shipping_key
GROUP BY ds.shipping_mode
ORDER BY Avg_Shipping_Delay DESC;


