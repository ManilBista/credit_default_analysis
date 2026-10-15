-- =====================================================================
-- queries.sql  -  15 analysis queries on the raw customers table
-- Database: credit_default (MySQL)
-- "Default rate" = % of customers with default_next_month = 1
-- Because the target is 0/1, AVG(default_next_month) is already the rate:
--   ROUND(100.0 * AVG(default_next_month), 2)  -> percentage
-- =====================================================================

USE credit_default;


-- Q1. Overall picture: customers, defaulters, default rate
SELECT
    COUNT(*)                                AS customers,
    SUM(default_next_month)                 AS defaulters,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers;


-- Q2. Default rate by credit limit band
SELECT
    CASE
        WHEN LIMIT_BAL < 50000  THEN '1. <50K'
        WHEN LIMIT_BAL < 100000 THEN '2. 50K-100K'
        WHEN LIMIT_BAL < 200000 THEN '3. 100K-200K'
        WHEN LIMIT_BAL < 500000 THEN '4. 200K-500K'
        ELSE '5. 500K+'
    END AS limit_band,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY limit_band
ORDER BY limit_band;


-- Q3. Default rate by age group
SELECT
    CASE
        WHEN AGE <= 30 THEN '21-30'
        WHEN AGE <= 40 THEN '31-40'
        WHEN AGE <= 50 THEN '41-50'
        WHEN AGE <= 60 THEN '51-60'
        ELSE '61+'
    END AS age_group,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY age_group
ORDER BY age_group;


-- Q4. Default rate by education (codes 0, 5, 6 are undocumented)
SELECT
    EDUCATION,
    CASE EDUCATION
        WHEN 1 THEN 'Graduate school'
        WHEN 2 THEN 'University'
        WHEN 3 THEN 'High school'
        WHEN 4 THEN 'Others'
        ELSE 'Undocumented'
    END AS education_label,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY EDUCATION
ORDER BY EDUCATION;


-- Q5. Default rate by marital status (code 0 is undocumented)
SELECT
    MARRIAGE,
    CASE MARRIAGE
        WHEN 1 THEN 'Married'
        WHEN 2 THEN 'Single'
        WHEN 3 THEN 'Others'
        ELSE 'Undocumented'
    END AS marriage_label,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY MARRIAGE
ORDER BY MARRIAGE;


-- Q6. Default rate by sex
SELECT
    CASE SEX WHEN 1 THEN 'Male' ELSE 'Female' END AS sex,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY SEX;


-- Q7. Default rate by most recent payment status (PAY_0 = September)
SELECT
    PAY_0 AS september_status,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY PAY_0
ORDER BY PAY_0;


-- Q8. Default rate by number of months (out of 6) with a payment delay
SELECT
    (CASE WHEN PAY_0 > 0 THEN 1 ELSE 0 END
   + CASE WHEN PAY_2 > 0 THEN 1 ELSE 0 END
   + CASE WHEN PAY_3 > 0 THEN 1 ELSE 0 END
   + CASE WHEN PAY_4 > 0 THEN 1 ELSE 0 END
   + CASE WHEN PAY_5 > 0 THEN 1 ELSE 0 END
   + CASE WHEN PAY_6 > 0 THEN 1 ELSE 0 END) AS months_delayed,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY months_delayed
ORDER BY months_delayed;


-- Q9. Average credit limit, latest bill and latest payment for defaulters vs non-defaulters
SELECT
    default_next_month,
    COUNT(*)                 AS customers,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit,
    ROUND(AVG(BILL_AMT1), 0) AS avg_sept_bill,
    ROUND(AVG(PAY_AMT1), 0)  AS avg_sept_payment
FROM customers
GROUP BY default_next_month;


-- Q10. Default rate by sex and education together (documented education codes only)
SELECT
    CASE SEX WHEN 1 THEN 'Male' ELSE 'Female' END AS sex,
    EDUCATION,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
WHERE EDUCATION BETWEEN 1 AND 4
GROUP BY SEX, EDUCATION
ORDER BY SEX, EDUCATION;


-- Q11. Default rate by credit utilization band (September bill / credit limit)
SELECT
    CASE
        WHEN 1.0 * BILL_AMT1 / LIMIT_BAL <= 0    THEN '1. 0% or less'
        WHEN 1.0 * BILL_AMT1 / LIMIT_BAL < 0.25  THEN '2. 0-25%'
        WHEN 1.0 * BILL_AMT1 / LIMIT_BAL < 0.50  THEN '3. 25-50%'
        WHEN 1.0 * BILL_AMT1 / LIMIT_BAL < 0.75  THEN '4. 50-75%'
        WHEN 1.0 * BILL_AMT1 / LIMIT_BAL <= 1.00 THEN '5. 75-100%'
        ELSE '6. Over limit'
    END AS utilization_band,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY utilization_band
ORDER BY utilization_band;


-- Q12. Default rate for customers with at least one negative bill vs the rest
SELECT
    CASE WHEN LEAST(BILL_AMT1, BILL_AMT2, BILL_AMT3, BILL_AMT4, BILL_AMT5, BILL_AMT6) < 0
         THEN 'Has negative bill' ELSE 'No negative bill' END AS bill_type,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY bill_type;


-- Q13. Default rate for customers who paid nothing in September but had a bill
SELECT
    CASE WHEN PAY_AMT1 = 0 THEN 'Paid nothing' ELSE 'Paid something' END AS september_payment,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
WHERE BILL_AMT1 > 0
GROUP BY september_payment;


-- Q14. Average credit limit by education level
SELECT
    EDUCATION,
    COUNT(*) AS customers,
    ROUND(AVG(LIMIT_BAL), 0) AS avg_limit,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY EDUCATION
ORDER BY avg_limit DESC;


-- Q15. Top 10 riskiest segments: age group x limit band (only segments with 200+ customers)
SELECT
    CASE
        WHEN AGE <= 30 THEN '21-30'
        WHEN AGE <= 40 THEN '31-40'
        WHEN AGE <= 50 THEN '41-50'
        ELSE '51+'
    END AS age_group,
    CASE
        WHEN LIMIT_BAL < 50000  THEN '1. <50K'
        WHEN LIMIT_BAL < 100000 THEN '2. 50K-100K'
        WHEN LIMIT_BAL < 200000 THEN '3. 100K-200K'
        ELSE '4. 200K+'
    END AS limit_band,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(default_next_month), 2) AS default_pct
FROM customers
GROUP BY age_group, limit_band
HAVING COUNT(*) >= 200
ORDER BY default_pct DESC
LIMIT 10;
