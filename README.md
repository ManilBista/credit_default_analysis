# Credit Card Default Risk Analysis

**Internship Project 2 of 2** · BSc CSIT, 8th semester (Tribhuvan University)

Which credit card customers will miss next month's payment, and how can a bank sort them into risk groups?
This project cleans six months of payment history for 30,000 customers in Taiwan (April-September 2005), explores what drives default, tests the findings statistically, builds a logistic regression model with low / medium / high risk tiers, and prepares the data for a Power BI dashboard.

**Stack:** Python (pandas, NumPy, Matplotlib, Seaborn, SciPy, scikit-learn), MySQL, Git, Power BI

---

## Dataset

- **Name:** Default of Credit Card Clients
- **Source:** UCI Machine Learning Repository: https://archive.ics.uci.edu/dataset/350/default+of+credit+card+clients
- **File:** `default of credit card clients.xls` (30,000 customers x 25 columns). The real header is on the **second row** (`header=1`).
- **Target:** `default payment next month` (1 = default, 0 = no default)
- **Paper:** Yeh, I. C. & Lien, C. H. (2009). *The comparisons of data mining techniques for the predictive accuracy of probability of default of credit card clients.* Expert Systems with Applications, 36(2).

---

## Setup (Windows)

```bash
# 1. go into the project folder
cd credit-default-analysis

# 2. create and activate a virtual environment
python -m venv venv
venv\Scripts\activate

# 3. install the libraries (xlrd is needed to read the .xls file)
pip install -r requirements.txt

# 4. download the dataset zip from the UCI link above and put
#    "default of credit card clients.xls" directly inside data/

# 5. open the notebooks and run them in order (01 -> 05)
jupyter notebook
```

**Optional (SQL part):**

```bash
mysql -u root -p < sql/schema.sql      # creates the database and table
python sql/load_data.py                # edit DB_URL (user/password) at the top first
```

Then run the queries in `sql/queries.sql` in MySQL Workbench.

---

## Folder Structure

```
credit-default-analysis/
├── data/
│   ├── default of credit card clients.xls   # raw data (not in Git, download from UCI)
│   ├── cleaned_readable.csv     # cleaned, real NT$ amounts + labels (EDA, Power BI)
│   ├── cleaned.csv              # cleaned, encoded + scaled (modeling)
│   ├── customer_scores.csv      # predicted probability + risk tier per customer (notebook 04)
│   ├── risk_tier_summary.csv    # actual default rate per tier, test set (notebook 04)
│   ├── model_metrics.csv        # model scores (notebook 04)
│   ├── model_coefficients.csv   # logistic regression coefficients (notebook 04)
│   └── powerbi/                 # tidy CSVs for the dashboard (notebook 05)
├── notebooks/
│   ├── 01_exploration.ipynb     # first look: shape, types, default rate, odd codes and bills
│   ├── 02_cleaning.ipynb        # fix codes, negative bills, IQR, new features, encoding, scaling
│   ├── 03_eda.ipynb             # statistics, charts, correlation, hypothesis tests
│   ├── 04_modeling.ipynb        # logistic regression + risk tiers
│   └── 05_dashboard_prep.ipynb  # export tidy CSVs for Power BI
├── sql/
│   ├── schema.sql               # MySQL table
│   ├── load_data.py             # loads the Excel file into MySQL
│   └── queries.sql              # 15 analysis queries
├── docs/
│   ├── cleaning_log.md          # every cleaning decision and its reason
│   ├── insights.md              # EDA findings and hypothesis tests
│   ├── dashboard_plan.md        # 3-page Power BI plan
│   └── work_log.md              # internship hours
├── requirements.txt
├── .gitignore
└── README.md
```

---

## Process

1. **Exploration:** 30,000 customers, no missing values, default rate 22.12%. Found undocumented codes (`EDUCATION` 0/5/6 = 345 rows, `MARRIAGE` 0 = 54 rows, `PAY_` -2/0) and 1,930 customers with negative bills.
2. **SQL:** MySQL schema plus 15 queries (default rate by limit band, age group, education, marital status, payment delay, utilization, ...).
3. **Cleaning:** codes fixed, `PAY_0` renamed to `PAY_1`, negative bills set to 0, money columns capped with IQR, 5 new features (`credit_utilization`, `avg_payment_delay`, `payment_to_bill_ratio`, `months_delayed`, `max_delay`). No rows removed. Every decision is in `docs/cleaning_log.md`.
4. **EDA:** distributions, default rate by group, correlation heatmap, 3 chi-square tests and 3 t-tests.
5. **Modeling:** Logistic Regression on an 80/20 stratified split, a balanced-weight version for comparison, and risk tiers from the predicted probability.
6. **Dashboard prep:** tidy CSVs (including a long month-by-month table) and a 3-page Power BI plan.

---

## Key Findings

All numbers come from the notebooks (30,000 customers; overall default rate **22.12%**).

1. **Payment delay is the strongest signal.** Customers on time in September default **13.83%** of the time, vs **33.95%** if 1 month late and **69.14%** if 2 months late. Customers late in all 6 months default **70.32%** of the time, vs 11.71% for those never late.
2. **Lower credit limits mean higher risk:** 36.07% below NT$50K vs 11.21% at NT$500K+. Defaulters' average limit is about NT$129,886 vs NT$177,500 (t-test p ≈ 8.8e-179).
3. **Higher utilization means higher risk:** average utilization 0.450 for defaulters vs 0.352 (p ≈ 2.7e-82).
4. **Demographics matter less:** men 24.17% vs women 20.78%; high school 25.16% vs graduate school 19.23%; married 23.47% vs single 20.93%. All are significant, but the gaps are small.
5. **Age alone is almost useless:** correlation with default 0.014, average age difference 0.3 years.
6. **Model results (test set, 6,000 customers):**

| Model | Accuracy | Precision | Recall | ROC-AUC |
|---|---|---|---|---|
| Logistic Regression | 0.815 | 0.652 | 0.348 | **0.758** |
| Logistic Regression (balanced) | 0.749 | 0.448 | 0.584 | 0.761 |

Balanced class weights catch more defaulters (recall 0.348 to 0.584) at the cost of more false alarms (precision 0.652 to 0.448).

7. **Risk tiers work.** Customers are grouped by predicted probability: Low < 0.30, Medium 0.30-0.60, High > 0.60.

| Tier | Test customers | Actual default rate | Share of all defaulters |
|---|---|---|---|
| Low | 4,612 (76.87%) | **13.38%** | 46.5% |
| Medium | 972 (16.20%) | **43.83%** | 32.1% |
| High | 416 (6.93%) | **68.27%** | 21.4% |

The High tier is only 6.93% of customers but holds 21.4% of all defaulters, a clear place to start collection or credit-limit reviews.

---

## Limitations

- The scaler is fit before the train/test split (the task asks for scaling in the cleaning step), so a tiny amount of test-set information leaks into the model. See `docs/cleaning_log.md`.
- The payment-delay features are strongly correlated with each other (up to 0.94), so their individual coefficients should not be read one by one.
- Money columns are IQR-capped in the cleaned files, so dashboard totals are slightly below the raw values.
- Data is from one Taiwanese bank in 2005; patterns may differ elsewhere and today.
