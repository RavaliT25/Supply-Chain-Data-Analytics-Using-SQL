CREATE DATABASE Supply_chain_Star_schema;
use Supply_chain_star_schema;
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
INSERT INTO Dim_Date (date_key, full_date, day, month, month_name, quarter, year, day_of_week)
SELECT DISTINCT
    CAST(DATE_FORMAT(Order_Date, '%Y%m%d') AS UNSIGNED),
    Order_Date,
    DAY(Order_Date),
    MONTH(Order_Date),
    MONTHNAME(Order_Date),
    CONCAT('Q', QUARTER(Order_Date)),
    YEAR(Order_Date),
    DAYNAME(Order_Date)
FROM supply_chain.orders;

-- Dim_Customer: one row per customer, carried over as-is
INSERT INTO Dim_Customer (customer_id, first_name, last_name, city, state, segment, zipcode)
SELECT Id, First_Name, Last_Name, City, State, Segment, Zipcode
FROM supply_chain.customer_info;

-- Dim_Product: category and department flattened onto the product row
INSERT INTO Dim_Product (product_id, product_name, category_name, department_name, product_price)
SELECT p.Product_Id, p.Product_Name, c.Name, d.Name, p.Product_Price
FROM supply_chain.product_info p
JOIN supply_chain.category c   ON p.Category_Id = c.Id
JOIN supply_chain.department d ON p.Department_Id = d.Id;

-- Dim_Geography: distinct shipping destinations seen in orders
INSERT INTO Dim_Geography (order_city, order_state, order_region)
SELECT DISTINCT Order_City, Order_State, Order_Region FROM supply_chain.orders;

-- Dim_Shipping: distinct combinations of order type, status, and shipping mode
INSERT INTO Dim_Shipping (order_type, order_status, shipping_mode)
SELECT DISTINCT Type, Order_Status, Shipping_Mode FROM supply_chain.orders;

-- Fact_Order_Sales: one row per order line item, resolved to every dimension's surrogate key
INSERT INTO Fact_Order_Sales
SELECT
    CAST(DATE_FORMAT(o.Order_Date, '%Y%m%d') AS UNSIGNED) AS date_key,
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
FROM supply_chain.ordered_items oi
JOIN supply_chain.orders o        ON oi.Order_Id = o.Order_Id
JOIN Dim_Customer dc  ON o.Customer_Id = dc.customer_id
JOIN Dim_Product dp   ON oi.Item_Id = dp.product_id
JOIN Dim_Geography dg ON o.Order_City = dg.order_city AND o.Order_State = dg.order_state AND o.Order_Region = dg.order_region
JOIN Dim_Shipping ds  ON o.Type = ds.order_type AND o.Order_Status = ds.order_status AND o.Shipping_Mode = ds.shipping_mode;


