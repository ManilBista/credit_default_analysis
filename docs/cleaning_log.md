# Cleaning Log - Credit Card Default

Notebook: `notebooks/02_cleaning.ipynb`  
Input: `data/default of credit card clients.xls` (30,000 rows x 25 columns, real header on row 2)  
Outputs:
- `data/cleaned_readable.csv`: 30,000 rows x 33 columns, real NT$ amounts and text labels (for EDA and Power BI)
- `data/cleaned.csv`: 30,000 rows x 33 columns, encoded and scaled (for modeling)

All numbers below come from the notebook output.

| # | Decision | Reason | Effect |
|---|----------|--------|--------|
| 1 | Read the Excel file with `header=1` | Row 1 holds generic names (`X1`...`Y`); the real names are on row 2 | 25 correct column names |
| 2 | Rename `PAY_0` -> `PAY_1` | The series skipped from `PAY_0` to `PAY_2`. Now `PAY_1`, `BILL_AMT1` and `PAY_AMT1` all mean September | Consistent numbering 1-6 |
| 3 | Rename `default payment next month` -> `default` | Short name without spaces, easier in code | - |
| 4 | **Keep** the 35 rows that duplicate another row when `ID` is ignored | Each has its own customer `ID`; 60 of the 70 rows involved have zero bills and zero payments, i.e. inactive cards that naturally look identical. They are different real customers | 0 rows removed |
| 5 | `EDUCATION` codes 0, 5, 6 -> 4 (others) | Not in the documentation and only 345 rows, so we cannot know their meaning. "Others" is the safest existing group | `EDUCATION = 4` grows from 123 to 468 |
| 6 | `MARRIAGE` code 0 -> 3 (others) | Not documented, 54 rows | `MARRIAGE = 3` grows from 323 to 377 |
| 7 | `PAY_1`-`PAY_6`: codes -2, -1, 0 -> 0 | -1 = paid on time; -2 (no credit used) and 0 (minimum paid) are undocumented but are not delays. After this every `PAY_` value means "months late" | Changed 8,445 (`PAY_1`) to 10,635 (`PAY_6`) values |
| 8 | Negative bills -> 0 | A negative bill is a credit balance: the customer owes nothing. Keeping negatives would make utilization and payment ratios negative | 590-688 values per column; 1,930 customers affected |
| 9 | New feature `credit_utilization` = mean(`BILL_AMT1-6`) / `LIMIT_BAL` | Share of the limit in use; above 1 = over the limit | mean 0.373, max 5.364 |
| 10 | New feature `avg_payment_delay` = mean(`PAY_1-6`) | Average months late over 6 months | mean 0.281, max 6 |
| 11 | New feature `payment_to_bill_ratio` = total paid / total billed, limited to 0-1 | Share of the bills actually paid. 966 customers with total bill = 0 -> 1 (nothing owed). 2,938 values above 1 (paid more than billed, e.g. older balances) -> capped at 1 | mean 0.346 |
| 12 | New feature `months_delayed` = number of months with `PAY_` > 0 | How often the customer was late | mean 0.834 |
| 13 | New feature `max_delay` = max(`PAY_1-6`) | Worst delay in 6 months | mean 0.682 |
| 14 | Features created **before** capping outliers | A ratio of capped values would no longer be the true ratio | - |
| 15 | Cap money columns at `Q1 - 1.5*IQR` / `Q3 + 1.5*IQR` | Capping keeps every customer but limits extreme values. All lower limits were below 0, so only the upper side changed | `LIMIT_BAL` capped at 525,000 (167 rows); `BILL_AMT1-6` 2,395-2,724 rows each; `PAY_AMT1-6` 2,598-2,994 rows each |
| 16 | Do **not** cap `AGE` | Ages up to 79 are real customers, not errors. IQR would cap 272 customers at 60.5 | Unchanged |
| 17 | Add `SEX_label`, `EDUCATION_label`, `MARRIAGE_label` and save `cleaned_readable.csv` | EDA charts and Power BI need words, not codes, and real NT$ amounts | 30,000 x 33 |
| 18 | `SEX` -> `is_female` (1 = female, 0 = male) | Only two values, so label encoding is enough | - |
| 19 | One-hot encode `EDUCATION` and `MARRIAGE` (`drop_first=True`) | The codes are labels, not amounts. `drop_first` removes one redundant column per group (graduate and married are the baselines) | 5 new 0/1 columns |
| 20 | Keep `ID` in `cleaned.csv`, unscaled | Needed to match predicted risk tiers back to customers in Power BI; never used as a model feature | - |
| 21 | Standard-scale 25 numeric columns (`LIMIT_BAL`, `AGE`, `PAY_1-6`, `BILL_AMT1-6`, `PAY_AMT1-6`, 5 new features) | Very different ranges (NT$ hundreds of thousands vs. 0-8 months). Logistic regression is sensitive to scale | Verified mean = 0.0, std = 1.0 |

**No rows were removed.** All 30,000 customers are kept. The default rate is still 22.12%.

**Known limitation:** the scaler is fit on all 30,000 rows before the train/test split in notebook 04. Mean and standard deviation leak a tiny amount of test-set information. That is accepted here because the task asks for scaling in the cleaning step.
