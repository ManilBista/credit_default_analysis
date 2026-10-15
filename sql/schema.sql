-- =====================================================================
-- schema.sql  -  MySQL schema for the Default of Credit Card Clients dataset
-- Run this first:  mysql -u root -p < sql/schema.sql
-- =====================================================================

-- create the database and switch to it
CREATE DATABASE IF NOT EXISTS credit_default;
USE credit_default;

-- drop the old table so the script can be run again
DROP TABLE IF EXISTS customers;

-- one row per customer (30,000 rows), raw values as in the Excel file
-- the target "default payment next month" is renamed default_next_month
-- (spaces are awkward in SQL and DEFAULT is a reserved word)
CREATE TABLE customers (
    ID                 INT PRIMARY KEY,
    LIMIT_BAL          INT,        -- credit limit in NT dollars
    SEX                TINYINT,    -- 1 = male, 2 = female
    EDUCATION          TINYINT,    -- 1 = graduate school, 2 = university, 3 = high school, 4 = others (0, 5, 6 undocumented)
    MARRIAGE           TINYINT,    -- 1 = married, 2 = single, 3 = others (0 undocumented)
    AGE                TINYINT,    -- years
    -- repayment status: -1 = paid on time, 1..9 = months late (-2 and 0 undocumented, mean not late)
    PAY_0              TINYINT,    -- September 2005 (most recent)
    PAY_2              TINYINT,    -- August
    PAY_3              TINYINT,    -- July
    PAY_4              TINYINT,    -- June
    PAY_5              TINYINT,    -- May
    PAY_6              TINYINT,    -- April
    -- bill statement amount (NT dollars), 1 = September ... 6 = April
    BILL_AMT1          INT,
    BILL_AMT2          INT,
    BILL_AMT3          INT,
    BILL_AMT4          INT,
    BILL_AMT5          INT,
    BILL_AMT6          INT,
    -- amount paid (NT dollars), 1 = September ... 6 = April
    PAY_AMT1           INT,
    PAY_AMT2           INT,
    PAY_AMT3           INT,
    PAY_AMT4           INT,
    PAY_AMT5           INT,
    PAY_AMT6           INT,
    default_next_month TINYINT     -- 1 = defaulted, 0 = did not
);
