
-- Bluestock MF Analytics — 10 Analytical Queries


-- 1. Top 5 funds by AUM (latest performance snapshot)
SELECT f.scheme_name, f.fund_house, p.aum_crore
FROM fact_performance p
JOIN dim_fund f ON f.amfi_code = p.amfi_code
ORDER BY p.aum_crore DESC
LIMIT 5;

-- 2. Average NAV per month, per fund
SELECT f.scheme_name, d.year, d.month,
       ROUND(AVG(n.nav), 4) AS avg_nav
FROM fact_nav n
JOIN dim_date d ON d.date_key = n.date_key
JOIN dim_fund f ON f.amfi_code = n.amfi_code
GROUP BY f.scheme_name, d.year, d.month
ORDER BY f.scheme_name, d.year, d.month;

-- 3. SIP YoY growth (total SIP inflow amount per calendar year, with YoY % change)
WITH sip_yearly AS (
    SELECT d.year, SUM(t.amount_inr) AS sip_total
    FROM fact_transactions t
    JOIN dim_date d ON d.date_key = t.date_key
    WHERE t.transaction_type = 'SIP'
    GROUP BY d.year
)
SELECT year, sip_total,
       ROUND(100.0 * (sip_total - LAG(sip_total) OVER (ORDER BY year)) /
             LAG(sip_total) OVER (ORDER BY year), 2) AS yoy_growth_pct
FROM sip_yearly
ORDER BY year;

-- 4. Transactions by state (count and total amount)
SELECT state,
       COUNT(*) AS num_transactions,
       ROUND(SUM(amount_inr), 2) AS total_amount_inr
FROM fact_transactions
GROUP BY state
ORDER BY total_amount_inr DESC;

-- 5. Funds with expense_ratio < 1%
SELECT f.scheme_name, f.fund_house, f.expense_ratio_pct
FROM dim_fund f
WHERE f.expense_ratio_pct < 1.0
ORDER BY f.expense_ratio_pct ASC;

-- 6. Top 5 funds by 3-year return
SELECT f.scheme_name, f.fund_house, p.return_3yr_pct
FROM fact_performance p
JOIN dim_fund f ON f.amfi_code = p.amfi_code
ORDER BY p.return_3yr_pct DESC
LIMIT 5;

-- 7. Investor transaction breakdown by KYC status and transaction type
SELECT kyc_status, transaction_type,
       COUNT(*) AS num_transactions,
       ROUND(SUM(amount_inr), 2) AS total_amount_inr
FROM fact_transactions
GROUP BY kyc_status, transaction_type
ORDER BY kyc_status, transaction_type;

-- 8. Monthly SIP vs Lumpsum vs Redemption volume trend
SELECT d.year, d.month, t.transaction_type,
       COUNT(*) AS num_transactions,
       ROUND(SUM(t.amount_inr), 2) AS total_amount_inr
FROM fact_transactions t
JOIN dim_date d ON d.date_key = t.date_key
GROUP BY d.year, d.month, t.transaction_type
ORDER BY d.year, d.month, t.transaction_type;

-- 9. Fund house-level AUM trend over time (latest 5 snapshot dates)
SELECT d.date, a.fund_house, a.aum_crore, a.num_schemes
FROM fact_aum a
JOIN dim_date d ON d.date_key = a.date_key
WHERE d.date_key IN (SELECT DISTINCT date_key FROM fact_aum ORDER BY date_key DESC LIMIT 5)
ORDER BY d.date DESC, a.aum_crore DESC;

-- 10. Average transaction size by age group and city tier
SELECT age_group, city_tier,
       COUNT(*) AS num_transactions,
       ROUND(AVG(amount_inr), 2) AS avg_transaction_amount
FROM fact_transactions
GROUP BY age_group, city_tier
ORDER BY age_group, city_tier;
