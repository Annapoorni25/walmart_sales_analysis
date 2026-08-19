--basics

CREATE DATABASE Walmart_DB

USE Walmart_DB

SELECT * FROM walmart

SELECT payment_method, 
COUNT(*) FROM walmart
GROUP BY payment_method

SELECT DISTINCT payment_method FROM walmart

SELECT COUNT(DISTINCT Branch) FROM walmart

SELECT MAX(quantity) FROM walmart

--Business Problems
--1) Find diff payment method and no of transactions , number of qty sold

SELECT 
	payment_method, 
	COUNT(*) as NoOfPayments,
	SUM(quantity) as NoOfQuantity
FROM walmart
GROUP BY payment_method

--2) Identify the highest-rated category in each branch , displaying the branch , category and avg rating

SELECT * FROM
(
	SELECT
		Branch,
		category,
		AVG(rating) AS avg_rating,
		RANK() OVER(PARTITION BY Branch ORDER BY AVG(rating) DESC)AS Rank
	FROM walmart 
	GROUP BY Branch , category 
) A
WHERE Rank = 1 

--3) Identify the busiest day for each branch based on the number of transactions


WITH formatted_data AS (
    SELECT
        Branch,
        TRY_CONVERT(date, [date], 3) AS formatted_date
    FROM walmart
)

SELECT * FROM (
SELECT
    Branch,
    DATENAME(WEEKDAY, formatted_date) AS day_name,
    COUNT(*) AS NoOfTransactions,
    RANK() OVER(PARTITION BY Branch ORDER BY COUNT(*) DESC) AS rank
FROM formatted_data
GROUP BY
    Branch,
    DATENAME(WEEKDAY, formatted_date)) AS A
WHERE rank =1 



--4) Calculate the total qty of items  sold per payment method.List the payment_method and total_quantity

SELECT 
	payment_method, 
	COUNT(*) AS NoOfQuantity
FROM walmart
GROUP BY payment_method


--5) Determine the avg , min , and max rating of products for each city.
--list the city , average_rating , min_rating and max_rating.

SELECT 
	City , 
	category,
	AVG(rating) as avg_rating,
	MIN(rating) AS min_rating,
	MAX(rating) AS max_rating
FROM walmart
GROUP BY City , category


--6)Calculate the total profit for each category by considering total_profit as
--(unit price * quantity * profit_margin).
--List the category and total_profit , ordered from highest to lowest profit

SELECT 
	category,
	SUM(unit_price * quantity * profit_margin) AS Total_profit
FROM walmart
GROUP BY category
ORDER BY Total_profit DESC 


--7) Determine the most common payment method for each branch
-- display branch and the peferred payment method

WITH PaymentCounts AS (
    SELECT
        Branch,
        payment_method,
        COUNT(*) AS Occurrences,
        RANK() OVER (
            PARTITION BY Branch
            ORDER BY COUNT(*) DESC
        ) AS rank
    FROM walmart
    GROUP BY Branch, payment_method
) 
SELECT * 
FROM PaymentCounts
WHERE rank = 1;


--8) Categorize sales into three groups morning , afternoon ,evening
-- find out each of the shift and invoices

ALTER TABLE walmart
ADD time_converted TIME;

UPDATE walmart
SET time_converted = TRY_CONVERT(TIME, time);

WITH ShiftData AS (
    SELECT 
        Branch,
        CASE
            WHEN time_converted >= '06:00:00' AND time_converted < '12:00:00'
                THEN 'Morning'
            WHEN time_converted >= '12:00:00' AND time_converted < '18:00:00'
                THEN 'Afternoon'
            ELSE 'Evening'
        END AS Shift
    FROM walmart
)
SELECT
    Branch,
    Shift,
    COUNT(*) AS Occurrences
FROM ShiftData
GROUP BY Branch, Shift
ORDER BY Branch, Occurrences DESC;


--9) Identify 5 branch with highest descrease ratio in revenue
-- compared to the last year(current year 2023 and last year 2022)

WITH Revenue2022 AS
(
    SELECT 
        Branch,
        SUM(total_price) as lyRevenue
    FROM walmart
    WHERE YEAR(TRY_CONVERT(date, [date], 3)) = 2022
    GROUP BY Branch
),
Revenue2023 AS
(
    SELECT 
        Branch,
        SUM(total_price) as cyRevenue
    FROM walmart
    WHERE YEAR(TRY_CONVERT(date, [date], 3)) = 2023
    GROUP BY Branch
)

SELECT TOP (5)
    lys.Branch,
    lys.lyRevenue as last_year_revenue,
    cys.cyRevenue as current_year_revenue,
    CAST(
        ((lys.lyRevenue - cys.cyRevenue)/ lys.lyRevenue) * 100
        AS DECIMAL(10,2)
    ) AS rev_dec_ratio
FROM Revenue2022 AS lys
JOIN Revenue2023 AS cys 
ON lys.Branch = cys.Branch
WHERE lys.lyRevenue > cys.cyRevenue
ORDER BY rev_dec_ratio DESC


