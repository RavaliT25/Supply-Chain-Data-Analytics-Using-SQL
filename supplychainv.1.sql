USE supplychain;

SELECT * FROM supplychain.order;
SELECT * FROM supplychain.category;
SELECT * FROM supplychain.customer_info;
SELECT * FROM supplychain.ordered_items;
SELECT * FROM supplychain.department;
SELECT * FROM supplychain.product_info;

-- Q1. How many rows are there in each table? Also check if there are null values?
SELECT COUNT(*) AS Tot_Cat_Cnt  from category; 
-- 51 rows
SELECT SUM(ISNULL(Id)) AS  Tot_catr_nulls from category; 
-- No null values

SELECT COUNT(*) AS Tot_Cusr_Cnt from customer_info; 
-- 4461 rows
SELECT  SUM(ISNULL(Id)) AS Tot_Cusr_nulls  from customer_info;
-- 0

SELECT COUNT(*) AS Tot_Dept_Cnt from department; 
-- 12 rows
SELECT SUM(ISNULL(Id)) AS Tot_Dept_nulls from department;
-- 0 rows

SELECT COUNT(*) AS Tot_OrdIt_Cnt from ordered_items; 
-- 4783 rows
SELECT SUM(ISNULL(order_item_id)) AS Tot_OrdIt_nulls from ordered_items; 
-- 0

SELECT COUNT(*) AS Tot_Orders from supplychain.order; 
-- 2152 rows
SELECT SUM(ISNULL(order_id)) AS Tot_Ord_nulls from supplychain.order;

SELECT COUNT(*) AS Tot_prdt_cnt from product_info;
-- 72 rows
SELECT SUM(ISNULL(product_id)) AS Tot_prdct_nulls from product_info; 
-- 0 rows


-- Datasets relationship
-- Customer_info- Id- PRIMARY KEY(PARENT TABLE)
-- Order table- Order_Id-PRIMARY KEY, 
--              Customer_Id- FOREIGN KEY (CHILD TABLE)

-- Order table- Order table- Order_Id-PRIMARY KEY, 
--                           Customer_Id- FOREIGN KEY (PARENT TABLE)
-- Ordered_items- Order_Item_Id-PRIMARY KEY, 
--                Order_Id-FOREIGN KEY(linked to the order table),
--                Item_Id-FOREIGN KEY(linked to products_info table) (CHILD TABLE)

 -- Product_info- Product_Id-PRIMARY KEY, (PARENT TABLE)
--                Category_Id-FOREIGN KEY,(linked to category table)
--                Department_Id-FOREIGN KEY(linked to department table)              
-- Ordered_items- Order_Item_Id-PRIMARY KEY, (CHILD TABLE)
--                Order_Id-FOREIGN KEY(linked to the order table),
--                Item_Id-FOREIGN KEY(linked to products_info table)

-- Category- Id-PRIMARY KEY (PARENT TABLE)
-- Product info-Product_Id-PRIMARY KEY.    (CHILD TABLE)
--              Category_Id-FOREIGN KEY,(linked to category table)
--              Department_Id-FOREIGN KEY(linked to department table)

-- Department- Id-PRIMARY KEY (PARENT TABLE)
-- Product_info- Product_Id-PRIMARY KEY, (CHILD TABLE)
--               Category_Id-FOREIGN KEY, 
--               Department_Id-FOREIGN KEY.

-- Are there any customers who never placed any order? customer_info and orders
-- What proportion of customers never placed a single order 2367/4461? 
WITH C1 AS
(
SELECT  c.id as Customer_id, c.first_name, c.last_name, o.order_id
FROM supplychain.customer_info AS c 
LEFT JOIN supplychain.order as o ON c.id = o.Customer_id
WHERE order_id IS NULL
)
select count(*) AS Customers_Without_Orders from c1;
-- 2367 customers who never placed an order.

-- How many products were never ordered ? Calculate the proportion of products that were never ordered?
-- orders (order_id), ordered_items (item_id), Product_info(product_id and product_name)

SELECT p.product_id, p.product_name, oi.item_id, o.order_id
FROM supplychain.product_info as p 
LEFT JOIN supplychain.ordered_items as oi ON  p.product_id = oi.item_id
LEFT JOIN supplychain.order as o ON oi.order_id = o.order_id
WHERE o.order_id is null;
-- No products are there that were never ordered. All products have been ordered atleast once.

-- Fetch the product_id and product_name 
-- from the product_info table along with the no of orders that were placed against each product?
-- Which product was mostly ordered?

SELECT 
    p.Product_Id,
    p.Product_Name,
    COUNT(DISTINCT o.Order_Id) AS NoofOrders
FROM supplychain.product_info AS p
LEFT JOIN supplychain.ordered_items AS oi ON p.Product_Id = oi.Item_Id
LEFT JOIN supplychain.order AS o ON oi.Order_Id = o.Order_Id
GROUP BY p.Product_Id, p.Product_Name
ORDER BY NoofOrders DESC;

-- Get the number of orders by the Type of Transaction. 
-- Please exclude orders shipped from Sangli and Srinagar. 
-- Also, exclude the SUSPECTED_FRAUD cases based on the Order Status.
-- Sort the result in the descending order based on the number of orders.

SELECT Type,count(Order_id) AS Total_orders
FROM supplychain.order
WHERE Order_City NOT IN ('Sangli','Srinagar') AND Order_Status NOT IN('SUSPECTED_FRAUD')
GROUP BY Type
ORDER BY Total_orders DESC;

-- Get the list of the Top 3 customers based on the completed orders along with the following details:
-- Customer Id
-- Customer First Name
-- Customer City
-- Customer State
-- Number of completed orders
-- Total Sales of completed orders
SELECT
    c.Id AS Customer_Id,
    c.First_Name,
    c.City,
    c.State,
    COUNT(o.Order_Id) AS Completed_Orders,
    SUM(oi.Sales) AS Total_sales
FROM supplychain.Order AS o
INNER JOIN supplychain.customer_info AS c ON o.Customer_Id = c.Id
INNER JOIN supplychain.ordered_items AS oi ON o.Order_Id = oi.Order_Id
WHERE o.Order_Status = 'COMPLETE'
GROUP BY c.Id, c.First_Name, c.City, c.State
ORDER BY Completed_Orders DESC
LIMIT 3;

-- Get the order count by the Shipping Mode and the Department Name. 
-- Consider departments with at least 40 closed/completed orders.

WITH eligible_departments AS (
    SELECT
        d.Name
    FROM supplychain.order AS o
    INNER JOIN supplychain.ordered_items AS oi ON o.Order_Id = oi.Order_Id
    INNER JOIN supplychain.product_info AS p ON oi.Item_Id = p.Product_Id
    INNER JOIN supplychain.department AS d ON p.Department_Id = d.ID
    WHERE o.Order_Status IN ('CLOSED', 'COMPLETE')
    GROUP BY d.Name
    HAVING COUNT(DISTINCT o.Order_Id) >= 40
)

SELECT
    o.Shipping_Mode,
    d.Name,
    COUNT(DISTINCT o.Order_Id) AS Total_Shpt_Cnt
FROM supplychain.order AS o
INNER JOIN supplychain.ordered_items AS oi ON o.Order_Id = oi.Order_Id
INNER JOIN supplychain.product_info AS p ON oi.Item_Id = p.Product_Id
INNER JOIN supplychain.department AS d ON p.Department_Id = d.ID
INNER JOIN eligible_departments AS ed ON d.Name = ed.Name
WHERE o.Order_Status IN ('CLOSED', 'COMPLETE')
GROUP BY o.Shipping_Mode, d.Name;

-- Create a new field as shipment compliance based on Real_Shipping_Days and Scheduled_Shipping_Days. It should have the following values:
-- Cancelled shipment - If the Order Status is SUSPECTED_FRAUD or CANCELED
-- Within schedule - If shipped within the scheduled number of days 
-- On time - If shipped exactly as per schedule
-- Upto 2 days of delay - If shipped beyond schedule but delay upto 2 days
-- Beyond 2 days of delay - If shipped beyond schedule with delay beyond 2 days
-- Which shipping mode was observed to have the greatest number of delayed orders?

SELECT
    o.Order_Id,
    o.Order_Status,
    o.Real_Shipping_Days,
    o.Scheduled_Shipping_Days,
CASE
        WHEN o.Order_Status IN ('SUSPECTED_FRAUD', 'CANCELED') THEN 'Cancelled shipment'
        WHEN o.Real_Shipping_Days < o.Scheduled_Shipping_Days THEN 'Within schedule'
		WHEN o.Real_Shipping_Days = o.Scheduled_Shipping_Days THEN 'On time'
	    WHEN o.Real_Shipping_Days > o.Scheduled_Shipping_Days AND o.Real_Shipping_Days - o.Scheduled_Shipping_Days <= 2 THEN 'Upto 2 days of delay'
        WHEN o.Real_Shipping_Days - o.Scheduled_Shipping_Days > 2 THEN 'Beyond 2 days of delay'
END AS Shipment_Compliance
FROM supplychain.order AS o;

SELECT * FROM supplychain.order;

-- An order is cancelled when the status of the order is either cancelled or SUSPECTED_FRAUD. 
-- Obtain the list of states by the order cancellation % and sort them in the descending order of the cancellation % 
-- Definition: Cancellation % = Cancelled orders / Total Orders
WITH Cancellation AS (
       SELECT 
              Order_State, 
              COUNT(Order_Id) AS Cancelled_orders
       FROM supplychain.order
       WHERE Order_Status IN('CANCELED','SUSPECTED_FRAUD')
       GROUP BY Order_State
),

TOTAL AS (
	SELECT 
           Order_state,
           COUNT(Order_ID) AS Total_Orders
	FROM supplychain.order
    GROUP BY Order_State
)

SELECT
    c.Order_State,
    c.Cancelled_Orders,
    t.Total_Orders,
    (c.Cancelled_Orders / t.Total_Orders) * 100 AS Cancellation_Pct
FROM Cancellation AS c
INNER JOIN Total AS t ON c.Order_State = t.Order_State
ORDER BY Cancellation_Pct DESC;
     
     
-- Now that we have analyzed our OLTP data, the next step is to prepare it for analytical purposes.
-- So, we are moving from OLTP to OLAP.

-- Our Supply Chain data is stored in different OLTP tables, mainly for daily business transactions.
-- For analysis, we often need to connect these tables using multiple JOINs.
-- So, we are moving the data into OLAP to make analysis easier and more organized.
-- We create a Star Schema with 5 Dimension tables and 1 Fact table.
-- This helps us easily analyze sales, customers, products, geography, and shipping data and create dashboards.