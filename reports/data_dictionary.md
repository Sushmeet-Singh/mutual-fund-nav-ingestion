# Data Dictionary - Bluestock MF Analytics


## dim_fund
Master reference for each scheme (fund + plan variant). Source: `01_fund_master.csv`.

| Column | Type | Business Definition |
|---|---|---|
| amfi_code | INTEGER (PK) | AMFI-issued unique scheme identifier |
| fund_house | TEXT | Asset management company (AMC) name |
| scheme_name | TEXT | Full scheme name incl. plan/option |
| category | TEXT | Broad asset category (Equity, Debt, Hybrid, etc.) |
| sub_category | TEXT | SEBI sub-category (e.g. Large Cap, Mid Cap) |
| plan | TEXT | Regular or Direct plan |
| launch_date | DATE | Scheme inception date |
| benchmark | TEXT | Benchmark index the scheme is measured against |
| expense_ratio_pct | REAL | Annual expense ratio, % of AUM |
| exit_load_pct | REAL | Exit load charged on early redemption, % |
| min_sip_amount | REAL | Minimum SIP installment (INR) |
| min_lumpsum_amount | REAL | Minimum lumpsum investment (INR) |
| fund_manager | TEXT | Current fund manager name |
| risk_category | TEXT | SEBI riskometer category |
| sebi_category_code | TEXT | SEBI scheme category code |

## dim_date
Calendar dimension covering every date present across fact tables.

| Column | Type | Business Definition |
|---|---|---|
| date_key | INTEGER (PK) | Date surrogate key, format YYYYMMDD |
| date | DATE | Calendar date |
| year | INTEGER | Calendar year |
| quarter | INTEGER | Calendar quarter (1–4) |
| month | INTEGER | Calendar month (1–12) |
| month_name | TEXT | Month name |
| day | INTEGER | Day of month |
| day_of_week | TEXT | Weekday name |
| is_weekend | INTEGER (0/1) | 1 if Saturday/Sunday |

## fact_nav
Daily NAV per scheme. Source: `02_nav_history.csv`, calendar-expanded and forward-filled for weekends/holidays.

| Column | Type | Business Definition |
|---|---|---|
| nav_id | INTEGER (PK) | Surrogate row key |
| amfi_code | INTEGER (FK → dim_fund) | Scheme identifier |
| date_key | INTEGER (FK → dim_date) | NAV date |
| nav | REAL | Net Asset Value per unit (INR); validated > 0 |

## fact_transactions
Individual investor transactions. Source: `08_investor_transactions.csv`.

| Column | Type | Business Definition |
|---|---|---|
| transaction_id | INTEGER (PK) | Surrogate row key |
| investor_id | TEXT | Investor identifier |
| date_key | INTEGER (FK → dim_date) | Transaction date |
| amfi_code | INTEGER (FK → dim_fund) | Scheme invested in / redeemed from |
| transaction_type | TEXT | Standardised: SIP, Lumpsum, or Redemption |
| amount_inr | REAL | Transaction amount (INR); validated > 0 |
| state | TEXT | Investor's state |
| city | TEXT | Investor's city |
| city_tier | TEXT | City tier classification (T30/B30 etc.) |
| age_group | TEXT | Investor age bracket |
| gender | TEXT | Investor gender |
| annual_income_lakh | REAL | Self-reported annual income, INR lakh |
| payment_mode | TEXT | Payment channel (UPI, Cheque, etc.) |
| kyc_status | TEXT | Standardised: Verified or Pending |

## fact_performance
Latest performance snapshot per scheme. Source: `07_scheme_performance.csv`.

| Column | Type | Business Definition |
|---|---|---|
| performance_id | INTEGER (PK) | Surrogate row key |
| amfi_code | INTEGER (FK → dim_fund) | Scheme identifier |
| return_1yr_pct / return_3yr_pct / return_5yr_pct | REAL | Trailing annualised returns |
| benchmark_3yr_pct | REAL | Benchmark's 3-year trailing return |
| alpha | REAL | Excess return vs benchmark, risk-adjusted |
| beta | REAL | Volatility relative to benchmark |
| sharpe_ratio | REAL | Risk-adjusted return (total risk) |
| sortino_ratio | REAL | Risk-adjusted return (downside risk) |
| std_dev_ann_pct | REAL | Annualised standard deviation of returns |
| max_drawdown_pct | REAL | Largest peak-to-trough decline |
| aum_crore | REAL | Scheme AUM, INR crore |
| expense_ratio_pct | REAL | Expense ratio, %; flagged if outside 0.1–2.5% band |
| morningstar_rating | INTEGER | Star rating (1–5) |
| risk_grade | TEXT | Qualitative risk grade |
| flag_return_anomaly | INTEGER (0/1) | 1 if any trailing return exceeds ±100% |
| flag_expense_out_of_range | INTEGER (0/1) | 1 if expense_ratio_pct outside 0.1–2.5% |

## fact_aum
Fund-house-level AUM snapshots over time. Source: `03_aum_by_fund_house.csv`.

| Column | Type | Business Definition |
|---|---|---|
| aum_id | INTEGER (PK) | Surrogate row key |
| date_key | INTEGER (FK → dim_date) | Snapshot date |
| fund_house | TEXT | AMC name |
| aum_lakh_crore | REAL | AUM in INR lakh-crore |
| aum_crore | REAL | AUM in INR crore |
| num_schemes | INTEGER | Number of schemes offered by the AMC |

---

## Supporting cleaned CSVs (not loaded into the star schema, kept in `data/processed/` for reference)

| File | Description |
|---|---|
| `04_monthly_sip_inflows_clean.csv` | Industry-wide monthly SIP inflow and account stats |
| `05_category_inflows_clean.csv` | Net inflows by fund category, monthly |
| `06_industry_folio_count_clean.csv` | Industry folio counts by asset class, monthly |
| `09_portfolio_holdings_clean.csv` | Scheme-level stock holdings (portfolio disclosure) |
| `10_benchmark_indices_clean.csv` | Daily benchmark index close values |

---

## Data Cleaning Rules Applied

1. **nav_history**: dates parsed to datetime; sorted by `amfi_code`+`date`; deduplicated on `(amfi_code, date)`; expanded to a full daily calendar per fund and forward-filled for weekends/holidays; all NAV values validated > 0.
2. **investor_transactions**: `transaction_type` standardised to `{SIP, Lumpsum, Redemption}` (case/whitespace normalised); `amount_inr` validated > 0; `transaction_date` parsed to datetime; `kyc_status` restricted to `{Verified, Pending}`; rows failing any check dropped.
3. **scheme_performance**: all return/ratio columns coerced to numeric (non-numeric → dropped); `flag_return_anomaly` raised when any trailing return exceeds ±100%; `flag_expense_out_of_range` raised when `expense_ratio_pct` falls outside 0.1%–2.5%.
4. Row counts between source CSVs and loaded SQLite tables were verified to match exactly after cleaning (see `pipeline.py` / `load_db.py` output).

## Source References
- Raw files: `raw/01_fund_master.csv` … `raw/10_benchmark_indices.csv` (uploaded dataset, AMFI/industry-style mutual fund data).
- Cleaning script: `pipeline.py`. Schema: `schema.sql`. Load + verification: `load_db.py`. Queries: `queries.sql`.
