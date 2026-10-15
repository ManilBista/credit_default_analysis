# Insights - Credit Card Default

Source: `notebooks/03_eda.ipynb`, run on `data/cleaned_readable.csv`  
Population: **30,000 customers** (Taiwan, April-September 2005)  
Overall default rate: **22.12%** (6,636 customers)

Every number below is printed by the notebook.

## 1. Payment history is by far the strongest signal

| Months late in September (`PAY_1`) | Customers | Default rate |
|---|---|---|
| 0 (on time) | 23,182 | 13.83% |
| 1 | 3,688 | 33.95% |
| 2 | 2,667 | 69.14% |
| 3 | 322 | 75.78% |

| Late months out of the last 6 | Customers | Default rate |
|---|---|---|
| 0 | 19,931 | 11.71% |
| 1 | 4,426 | 29.82% |
| 3 | 1,154 | 50.87% |
| 6 | 1,341 | 70.32% |

- Highest correlations with default: `months_delayed` (0.398), `PAY_1` (0.396), `avg_payment_delay` (0.376), `max_delay` (0.370).

**So what:** one month of delay more than doubles the risk (13.83% to 33.95%). Two months of delay mean roughly a 7 in 10 chance of default.

## 2. Lower credit limits mean higher risk

| Credit limit | Customers | Default rate |
|---|---|---|
| < NT$50K | 4,311 | 36.07% |
| NT$50K-100K | 7,139 | 26.01% |
| NT$100K-200K | 7,400 | 20.77% |
| NT$200K-500K | 10,222 | 15.49% |
| NT$500K+ | 928 | 11.21% |

- t-test: defaulters average NT$129,886 vs NT$177,500 for non-defaulters (t = -29.0, p ≈ 8.8e-179).
- Correlation with default: -0.154.

## 3. Utilization up, payments down: more risk

- Mean credit utilization: **0.450** for defaulters vs 0.352 for non-defaulters (t = 19.39, p ≈ 2.7e-82).
- `payment_to_bill_ratio` correlates negatively with default (-0.091), and so does the September payment amount (-0.143).

## 4. Demographics matter, but much less

| Group | Default rate |
|---|---|
| Male / Female | 24.17% / 20.78% |
| Graduate school / University / High school | 19.23% / 23.73% / 25.16% |
| Married / Single | 23.47% / 20.93% |

- All three chi-square tests are significant (see table below), but the gaps are only 2.5-6 percentage points.
- The "Others" education group (468 customers, including the recoded 0/5/6 codes) defaults only 7.05% of the time.

## 5. Age alone is almost useless

- Age has a U-shape: lowest at 31-40 (20.43%), highest at 61+ (26.84%, only 272 customers).
- Mean age: 35.73 (defaulters) vs 35.42 (non-defaulters). The t-test is technically significant (p = 0.020) because the sample is large, but the gap is 0.3 years.
- Correlation with default: 0.014.

## Hypothesis test summary (alpha = 0.05)

| # | Test | Variables | Statistic | p-value | Result |
|---|---|---|---|---|---|
| 1 | Chi-square | Sex vs default | χ² = 47.71 | 4.9e-12 | Significant |
| 2 | Chi-square | Education vs default | χ² = 160.41 | 1.5e-34 | Significant |
| 3 | Chi-square | Marital status vs default | χ² = 28.13 | 7.8e-07 | Significant |
| 4 | Welch t-test | `LIMIT_BAL` | t = -29.00 | 8.8e-179 | Significant |
| 5 | Welch t-test | `credit_utilization` | t = 19.39 | 2.7e-82 | Significant |
| 6 | Welch t-test | `AGE` | t = 2.32 | 0.020 | Significant, but tiny effect |

**Caution:** with 30,000 customers even tiny differences become significant. Effect sizes (the rate gaps above) matter more than p-values.

**For modeling:** the delay features are strongly correlated with each other (up to 0.94), so their individual logistic regression coefficients should be read with care.
