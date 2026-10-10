# Supply-Chain-Data-Analytics-OLTP-OLAP

An end-to-end SQL analytics project focused on supply chain operations, customer behavior, sales performance, and shipping efficiency.

**Key Features**
- Exploratory data analysis using SQL.
- Customer and product order analysis.
- Sales and order-status analysis.
- Cancellation rate analysis by state.
- Shipping compliance and delay analysis.
- OLTP-to-OLAP transformation using a star schema.
- Fact and dimension table creation and population.
- Business KPI analysis using joins, CTEs, aggregations, and window-free analytical SQL queries.

**Tools:** MySQL, SQL, Data Warehousing, Dimensional Modeling.

**Objective:** Transform transactional supply chain data into an analytical data warehouse and derive business insights to support data-driven decision-making.


Step 1: OLTP source tables
Order, customer, product, category, department, ordered items

Step 2: SQL transformation
JOIN tables, clean and transform data, create dimension keys

Step 3: OLAP star schema
Five dimension tables + one fact table

Step 4: Business insights
Sales trends, customer analysis, geography and shipping KPIs


**Difference between OLTP and OLAP**

**Feature** 	        **OLTP in this project**                        **OLAP in this project**
1.Purpose	            Transactional data analysis	                     Analytical reporting
2.Data model	       Original relational tables	                       Star schema
3.Main focus	       Customers, orders, products	                     Sales and performance KPIs
4.Query examples	     Customers without orders	                       Yearly sales
5.Data structure	    Normalized source tables	                       Fact and dimension tables


**01 — OLTP Version**
01_OLTP_Supply_Chain_Analysis.sql
Customer analysis, product orders, cancellation rates, and shipping compliance.

**02 — OLAP Version**
02_OLAP_Supply_Chain_Star_Schema.sql
Five dimension tables, one fact table, and sales and shipping KPI analysis.


## Key Business Insights

### OLTP Analysis
- Identified 2,367 customers out of 4,461 who had never placed an order, representing approximately 53.06% of the customer base.
- Analyzed product demand using distinct order counts to identify frequently ordered products.
- Examined completed orders and customer sales contributions to identify high-value customers.
- Evaluated cancellation percentages across states, including cancelled and suspected-fraud orders.
- Classified shipping performance according to scheduled and actual shipping days.
- Performed initial data quality checks on key identifier columns.

### OLAP Analysis
- Designed a star-schema data warehouse with five dimension tables and one fact table.
- Calculated overall sales and quantity KPIs.
- Analyzed yearly sales trends and ranked the top 10 products by revenue.
- Compared average order-item sales across customer segments.
- Identified states exceeding a sales threshold of 50,000.
- Compared average shipping delays across shipping modes.

### Business Value
The project demonstrates how transactional supply chain data can be transformed into a dimensional data warehouse for business intelligence. The resulting analytical model supports sales monitoring, customer analysis, geographic performance evaluation, and shipping efficiency analysis.
