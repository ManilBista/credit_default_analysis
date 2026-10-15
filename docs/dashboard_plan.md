# Power BI Dashboard Plan - Credit Card Default Risk

Data folder: `data/powerbi/` (created by `notebooks/05_dashboard_prep.ipynb`)

| File | Rows | One row = | Key columns |
|------|------|-----------|-------------|
| `customers.csv` | 30,000 | one customer | `ID`, `default` (0/1), `LIMIT_BAL`, `limit_band`, `sex`, `education`, `marital_status`, `AGE`, `age_group`, `sept_status`, `credit_utilization`, `utilization_band`, `avg_payment_delay`, `payment_to_bill_ratio`, `months_delayed`, `max_delay`, `default_probability`, `risk_tier`, `split` |
| `monthly_payments.csv` | 180,000 | one customer x one month | `ID`, `month` (2005-04 ... 2005-09), `months_late`, `bill_amount`, `payment_amount`, `default` |
| `default_by_group.csv` | 40 | one group of one variable | `variable`, `group`, `customers`, `defaulters`, `default_rate_pct` |
| `risk_tier_summary.csv` | 3 | one risk tier (test set, 6,000 customers) | `risk_tier`, `customers`, `defaulters`, `avg_predicted_prob`, `actual_default_rate_pct`, `share_of_customers_pct`, `share_of_all_defaulters_pct` |
| `model_metrics.csv` | 8 | one model x one metric | `model`, `metric`, `value` |
| `model_coefficients.csv` | 31 | one feature | `feature`, `coefficient` |

**Relationship:** `customers[ID]` 1 -> * `monthly_payments[ID]` (single direction). Then slicers on `customers` also filter the monthly trend.

**Note:** money columns are IQR-capped and negative bills are set to 0 (see `docs/cleaning_log.md`), so totals are slightly below the raw file.

## DAX measures (create on the `customers` table)

```
Customers        = COUNTROWS(customers)
Defaulters       = SUM(customers[default])
Default Rate %   = DIVIDE([Defaulters], [Customers]) * 100
Avg Limit        = AVERAGE(customers[LIMIT_BAL])
Avg Utilization  = AVERAGE(customers[credit_utilization])
Avg Risk Score   = AVERAGE(customers[default_probability])
```

**Sort order:** set `risk_tier` to Low, Medium, High (create a small column `tier_order` = 1/2/3 and use "Sort by column"). Do the same for `limit_band` and `utilization_band` if Power BI sorts them alphabetically.

---

## Page 1 - Portfolio Overview: "Who defaults?"

| # | Visual | Columns used | Purpose |
|---|--------|--------------|---------|
| 1 | Card x 4 | `[Customers]`, `[Defaulters]`, `[Default Rate %]`, `[Avg Limit]` | Headline numbers (30,000 / 6,636 / 22.12%) |
| 2 | Clustered column | Axis: `limit_band`. Values: `[Default Rate %]`. Tooltip: `[Customers]` | Lower limits mean higher risk (36.07% to 11.21%) |
| 3 | Clustered column | Axis: `age_group`. Values: `[Default Rate %]` | U-shaped age pattern |
| 4 | Clustered bar | Axis: `education`. Values: `[Default Rate %]` | Education gap |
| 5 | Clustered column | Axis: `marital_status`. Legend: `sex`. Values: `[Default Rate %]` | Marital status and sex together |
| 6 | Slicers | `sex`, `education`, `marital_status`, `age_group` | Filter the page |

## Page 2 - Payment Behaviour: "How do defaulters pay?"

| # | Visual | Columns used | Purpose |
|---|--------|--------------|---------|
| 1 | Clustered column | Axis: `months_delayed`. Values: `[Default Rate %]` (`customers`) | Strongest signal: 11.71% (never late) to 70.32% (late all 6 months) |
| 2 | Clustered bar | Axis: `sept_status`. Values: `[Default Rate %]`. Tooltip: `[Customers]` (`customers`) | September status: on time 13.83%, 2 months late 69.14% |
| 3 | Line chart | Axis: `month`. Values: average of `bill_amount` and average of `payment_amount`. Legend: `default` (`monthly_payments`) | 6-month trend of bills vs payments, defaulters vs non-defaulters |
| 4 | Line chart | Axis: `month`. Values: average of `months_late`. Legend: `default` (`monthly_payments`) | Delay builds up over time for defaulters |
| 5 | Clustered column | Axis: `utilization_band`. Values: `[Default Rate %]` (`customers`) | Higher utilization means higher risk |
| 6 | Scatter chart | X: `credit_utilization`. Y: `payment_to_bill_ratio`. Legend: `default`. Details: `ID` (`customers`) | Defaulters sit at high utilization and low payment ratio |

## Page 3 - Risk Tiers & Model: "Who should the bank watch?"

| # | Visual | Columns used | Purpose |
|---|--------|--------------|---------|
| 1 | Clustered column | Axis: `risk_tier`. Values: `actual_default_rate_pct` (`risk_tier_summary`) | Validation: Low 13.38%, Medium 43.83%, High 68.27% on unseen test customers |
| 2 | Clustered column | Axis: `risk_tier`. Values: `share_of_customers_pct` and `share_of_all_defaulters_pct` (`risk_tier_summary`) | High tier = 6.93% of customers but 21.4% of defaulters |
| 3 | Donut chart | Legend: `risk_tier`. Values: `[Customers]` (`customers`) | Size of each tier across all 30,000 customers |
| 4 | Clustered column | Axis: `metric`. Legend: `model`. Values: `value` (`model_metrics`) | Plain vs balanced logistic regression: accuracy, precision, recall, ROC-AUC |
| 5 | Clustered bar (Top N = 10 by absolute value) | Axis: `feature`. Values: `coefficient` (`model_coefficients`) | What drives the risk score (delay features on top) |
| 6 | Table | `ID`, `LIMIT_BAL`, `sept_status`, `months_delayed`, `default_probability`, `risk_tier`. Filter: `risk_tier = High`. Sort: `default_probability` descending (`customers`) | Watch list of the highest-risk customers |
| 7 | Slicer | `split` (train / test) | Show only test customers for an honest view |

## Design notes

- Green / orange / red for Low / Medium / High on every tier visual.
- Add the overall default rate (22.12%) as a constant line on the rate charts (Analytics pane -> Constant line).
- In the text box on page 3, explain that the tier summary uses only the 6,000 test customers the model never saw.
