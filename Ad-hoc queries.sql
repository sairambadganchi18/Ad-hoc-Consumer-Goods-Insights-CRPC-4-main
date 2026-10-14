--- 1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT
    DISTINCT market FROM  dim_customer
WHERE region = 'APAC' AND customer = "Atliq Exclusive";


--- 2. What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg
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


  
--- 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields,
segment
product_count
SELECT
    segment,
    COUNT(DISTINCT product_code) as unique_products
FROM dim_product
GROUP BY segment
ORDER BY unique_products DESC


--- 4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference
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


--- 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
product_code
product
manufacturing_cost
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


--- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
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


--- 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns:
Month
Year
Gross sales Amount
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


--- 8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
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


--- 9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
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


--- 10.Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these fields,

division
product_code
product
total_sold_quantity
rank_order
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
