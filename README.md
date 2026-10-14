# Consumer-Goods-Ad-hoc-Insights

## About Company :
- Atliq Hardware is a leading computer hardware manufacturer based in India, with a strong global presence across 26 countries. The company specializes in three major product divisions: Peripherals & Accessories, PC, Networking & Storage.

- With a diverse customer base of 74 clients—including prominent names like Neptune, Sage, Leader, and Vijay Sales—Atliq Hardware serves markets worldwide.

- Recently, the management identified a need for deeper, faster insights into sales and performance data to support agile, data-informed decision-making. This has led to the initiation of a data analytics project aimed at transforming raw sales data into actionable intelligence through SQL analysis and visualization.

-------------------------

## Company Product Structure, Platform & Market Channel :
![product_structure](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/Company_product_structure.png?raw=true)

---------------------

## Dataset View :
![data-model](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/data_model.png?raw=true)

-----------------------------------------

- Fiscal year for AtliQ Hardware :- 1st September to 31st August
- Sales data is available for fiscal year 2020-2021

-----------------------------

## Ad-hoc Requests & its Solutions :

### 1.Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 

```sql
SELECT
    DISTINCT market FROM  dim_customer
WHERE region = 'APAC' AND customer = "Atliq Exclusive";
```
![br-1](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-1.png?raw=true)

- AtliQ Exclusive operates its business in **8** markets of Asia Pacific Region
- AtliQ Exclusive is a Brick & Mortar store means it is a physical store directly sold their products from the store
- AtliQ has highest store in APAC followed by **EU(6)**, **NA(2)**, **LATAM** has **zero** physical stores

-------------------------------

### 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
- unique_products_2020 
- unique_products_2021 
- percentage_chg

```sql
WITH unique_products_yearly AS (
    SELECT 
        fiscal_year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM fact_gross_price
    GROUP BY fiscal_year
)
SELECT
    MAX(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS unique_products_2020,
    MAX(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS unique_products_2021,
    ROUND(
        (
            MAX(CASE WHEN fiscal_year = 2021 THEN unique_products END) -
            MAX(CASE WHEN fiscal_year = 2020 THEN unique_products END)
        ) * 100.0 /
        MAX(CASE WHEN fiscal_year = 2020 THEN unique_products END),
        2
    ) AS percent_change
FROM unique_products_yearly;
```
![br-2](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-update.png?raw=true)

- In FY 2020, we had a total of **245** products, but in FY 2021 our count increased by **36.33%** to **334** products.
- It’s a good sign that we are continuously innovating and introducing new products to the market.

---------------------------------

### 3.Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts. The final output contains 2 fields, 
- segment 
- product_count
```sql
SELECT
    segment,
    COUNT(DISTINCT product_code) as unique_products
FROM dim_product
GROUP BY segment
ORDER BY unique_products DESC
```
![br-3](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-3.png?raw=true)

- We have a wide range of products under segments : **Notebook**, **Accessories**, **Peripherals** with an average of **110** products per segment
- While **Desktop**,**Storage**,**Networking** are lagging with an average of **23** products per segment
- Product development team needs to give attention on products that require redesigning as per modern standards
- Innovations will keep AtliQ Hardware ahead in this competitive market

-------------------------------

### 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, 
- segment 
- product_count_2020 
- product_count_2021 
- difference
```sql
WITH yearly_data AS (
    SELECT
        p.segment,
        g.fiscal_year,
        COUNT(DISTINCT g.product_code) AS unique_products
    FROM dim_product p
    JOIN fact_gross_price g
        ON p.product_code = g.product_code
    GROUP BY p.segment, g.fiscal_year
)
SELECT
    segment,
    MAX(CASE WHEN fiscal_year = 2020 THEN unique_products END) AS unique_products_2020,
    MAX(CASE WHEN fiscal_year = 2021 THEN unique_products END) AS unique_products_2021,
    (
        MAX(CASE WHEN fiscal_year = 2021 THEN unique_products END)
        -
        MAX(CASE WHEN fiscal_year = 2020 THEN unique_products END)
    ) AS products_difference
FROM yearly_data
GROUP BY segment
ORDER BY products_difference DESC;
```
![br-4](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-4.png?raw=true)

- With the introduction of **34** new products, **Accessories** segment has the highest increase in number of products
- **Notebook** and **Peripherals** each has an increment of **16** products
- Product team has done good job in **Desktop** segment by increasing count **2020(7)** < **2021(22)**
- **Networking** segment is at bottom with only **3** new products in 2021

----------------------------------

### 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, 
- product_code 
- product 
- manufacturing_cost
```sql
SELECT
    p.product_code,
    CONCAT(p.product, ' (', p.variant, ')') AS product,
    m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
    ON p.product_code = m.product_code
WHERE m.manufacturing_cost = (
        SELECT MAX(manufacturing_cost)
        FROM fact_manufacturing_cost
    )
   OR m.manufacturing_cost = (
        SELECT MIN(manufacturing_cost)
        FROM fact_manufacturing_cost
    );
```
![br-5](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-5.png?raw=true)

--------------------------------

### 6. Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the Indian  market. The final output contains these fields, 
- customer_code 
- customer 
- average_discount_percentage
```sql
SELECT
    c.customer_code,
    c.customer,
    AVG(pre.pre_invoice_discount_pct) as avg_pre_invoice_discount_pct
FROM dim_customer c 
JOIN fact_pre_invoice_deductions pre
    ON c.customer_code=pre.customer_code
WHERE 
    pre.fiscal_year=2021 AND c.market='India'
GROUP BY 
    c.customer_code,
    c.customer
ORDER BY 
    avg_pre_invoice_discount_pct desc 
LIMIT 5;

```
![br-6](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-6.png?raw=true)

- Flipkart has received highest 30.83% pre-invoice discount
- Amazon has low pre invoice discount 29.33%

--------------------------------------

### 7.Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month  .  This analysis helps to  get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: 
- Month 
- Year 
- Gross sales Amount
```sql
SELECT 
       MONTHNAME(date) AS month_name,
       YEAR(date) AS year_, 
       CONCAT(ROUND(SUM(a.sold_quantity * b.gross_price)/1000000,2),'M') AS gross_sales 
FROM fact_sales_monthly AS a
INNER JOIN fact_gross_price AS b
ON b.product_code = a.product_code
AND b.fiscal_year = a.fiscal_year
INNER JOIN dim_customer AS c
ON c.customer_code = a.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY month_name, year_
ORDER BY year_;
```
![br-7](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-7.png?raw=true)

- Highest sales were recorderd in **November-2020 (20.5M)** & lowest sales in **March-2020(0.38M)**
- From **March-August** in **2020** sales are low because of the pandemic all the stores are closed
- Lockdowns increased demand for laptops and other home electronics, due to work from home

---------------------------------

### 8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, 
- Quarter 
- total_sold_quantity
```sql
SELECT
    CASE
        WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
        WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
        WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
        WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
    END AS fiscal_quarter,
    SUM(sold_quantity) AS total_sold_units
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY fiscal_quarter
ORDER BY
    CASE fiscal_quarter
        WHEN 'Q1' THEN 1
        WHEN 'Q2' THEN 2
        WHEN 'Q3' THEN 3
        WHEN 'Q4' THEN 4
    END;
```
![br-8](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-8.png?raw=true)

- **Q1 (September-November)** has highest sales (**7.01M**)
- **Q3 (March-May)** sales dropped because of pandemic
- **Q4(June-August)** sales are increasing 

------------------------------

### 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?  The final output  contains these fields, 
- channel 
- gross_sales_mln 
- percentage
```sql
SELECT
    c.channel,
    CONCAT(ROUND(SUM(s.sold_quantity * g.gross_price) / 1000000, 2),' M') AS gross_sales,
    CONCAT(
        ROUND(
            SUM(s.sold_quantity * g.gross_price) * 100.0 /
            (
                SELECT SUM(s2.sold_quantity * g2.gross_price)
                FROM fact_sales_monthly s2
                JOIN fact_gross_price g2
                    ON s2.product_code = g2.product_code
                WHERE s2.fiscal_year = 2021
            ),2),' %') AS percent_contribution
FROM fact_sales_monthly s
JOIN fact_gross_price g
    ON s.product_code = g.product_code
JOIN dim_customer c
    ON s.customer_code = c.customer_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
ORDER BY gross_sales DESC;
```
![br-9](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-9.png?raw=true)

- **Retailer** brings the maximum sales to the company **1024.17M (73.2%)**
- Channel **Direct** generates **406.69M (15.5%)** sales
- Distributor contributes least only **297.18M (11.3%)**

-------------------------------------

### 10.Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these fields, 
- division 
- product_code
- product 
- total_sold_quantity 
- rank_order 
```sql
WITH total_sold_units AS (
    SELECT
        p.division,
        p.product_code,
        CONCAT(p.product, ' (', p.variant, ')') AS product,
        SUM(s.sold_quantity) AS total_sold_quantity
    FROM fact_sales_monthly s
    JOIN dim_product p
        ON s.product_code = p.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY
        p.division,
        p.product_code,
        p.product,
        p.variant
),
ranking AS (
    SELECT
        division,
        product_code,
        product,
        total_sold_quantity,
        DENSE_RANK() OVER (
            PARTITION BY division
            ORDER BY total_sold_quantity DESC
        ) AS rank_order
    FROM total_sold_units
)
SELECT *
FROM ranking
WHERE rank_order <= 3
ORDER BY division, rank_order;
```
![br-10](https://github.com/parthpatoliya97/Ad-hoc-Consumer-Goods-Insights-CRPC-4/blob/main/Images/br-10.png?raw=true)

- N&S : Top selling product is **AQ Pen Drive 2 IN 1** with a total of **7,01,373** quantities sold, followed by two variants of **AQ Pen Drive DRC** with **6,88,003** and **6,76,245** quantity.
- P&A : **AQ Gamers Ms** is top selling product with a total of **4,28,498** quantities sold, followed by two variants of **AQ Maxima Ms**
- PC : **AQ Digit** is top selling product with a total of **17,434** quantities 
