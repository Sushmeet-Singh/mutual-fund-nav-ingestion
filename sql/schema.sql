
-- Bluestock MF Analytics — SQLite Star Schema

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS fact_aum;
DROP TABLE IF EXISTS fact_performance;
DROP TABLE IF EXISTS fact_transactions;
DROP TABLE IF EXISTS fact_nav;
DROP TABLE IF EXISTS dim_fund;
DROP TABLE IF EXISTS dim_date;

-- ---------------- Dimension: Fund ----------------
CREATE TABLE dim_fund (
    amfi_code           INTEGER PRIMARY KEY,
    fund_house          TEXT NOT NULL,
    scheme_name         TEXT NOT NULL,
    category            TEXT,
    sub_category        TEXT,
    plan                TEXT,
    launch_date         DATE,
    benchmark           TEXT,
    expense_ratio_pct   REAL,
    exit_load_pct       REAL,
    min_sip_amount      REAL,
    min_lumpsum_amount  REAL,
    fund_manager        TEXT,
    risk_category       TEXT,
    sebi_category_code  TEXT
);

-- ---------------- Dimension: Date ----------------
CREATE TABLE dim_date (
    date_key      INTEGER PRIMARY KEY,   -- YYYYMMDD
    date          DATE NOT NULL,
    year          INTEGER,
    quarter       INTEGER,
    month         INTEGER,
    month_name    TEXT,
    day           INTEGER,
    day_of_week   TEXT,
    is_weekend    INTEGER
);

-- ---------------- Fact: NAV history ----------------
CREATE TABLE fact_nav (
    nav_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    amfi_code   INTEGER NOT NULL,
    date_key    INTEGER NOT NULL,
    nav         REAL NOT NULL CHECK (nav > 0),
    FOREIGN KEY (amfi_code) REFERENCES dim_fund(amfi_code),
    FOREIGN KEY (date_key)  REFERENCES dim_date(date_key),
    UNIQUE (amfi_code, date_key)
);

-- ---------------- Fact: Investor transactions ----------------
CREATE TABLE fact_transactions (
    transaction_id       INTEGER PRIMARY KEY AUTOINCREMENT,
    investor_id          TEXT NOT NULL,
    date_key             INTEGER NOT NULL,
    amfi_code            INTEGER NOT NULL,
    transaction_type     TEXT NOT NULL CHECK (transaction_type IN ('SIP','Lumpsum','Redemption')),
    amount_inr           REAL NOT NULL CHECK (amount_inr > 0),
    state                TEXT,
    city                 TEXT,
    city_tier            TEXT,
    age_group            TEXT,
    gender               TEXT,
    annual_income_lakh   REAL,
    payment_mode         TEXT,
    kyc_status           TEXT NOT NULL CHECK (kyc_status IN ('Verified','Pending')),
    FOREIGN KEY (amfi_code) REFERENCES dim_fund(amfi_code),
    FOREIGN KEY (date_key)  REFERENCES dim_date(date_key)
);

-- ---------------- Fact: Scheme performance (snapshot) ----------------
CREATE TABLE fact_performance (
    performance_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    amfi_code             INTEGER NOT NULL,
    return_1yr_pct        REAL,
    return_3yr_pct        REAL,
    return_5yr_pct        REAL,
    benchmark_3yr_pct     REAL,
    alpha                 REAL,
    beta                  REAL,
    sharpe_ratio          REAL,
    sortino_ratio         REAL,
    std_dev_ann_pct       REAL,
    max_drawdown_pct      REAL,
    aum_crore             REAL,
    expense_ratio_pct     REAL CHECK (expense_ratio_pct BETWEEN 0.1 AND 2.5 OR flag_expense_out_of_range = 1),
    morningstar_rating    INTEGER,
    risk_grade            TEXT,
    flag_return_anomaly   INTEGER DEFAULT 0,
    flag_expense_out_of_range INTEGER DEFAULT 0,
    FOREIGN KEY (amfi_code) REFERENCES dim_fund(amfi_code)
);

-- ---------------- Fact: AUM by fund house ----------------
CREATE TABLE fact_aum (
    aum_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    date_key          INTEGER NOT NULL,
    fund_house        TEXT NOT NULL,
    aum_lakh_crore    REAL,
    aum_crore         REAL,
    num_schemes       INTEGER,
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);

CREATE INDEX idx_fact_nav_fund ON fact_nav(amfi_code);
CREATE INDEX idx_fact_nav_date ON fact_nav(date_key);
CREATE INDEX idx_fact_txn_fund ON fact_transactions(amfi_code);
CREATE INDEX idx_fact_txn_date ON fact_transactions(date_key);
CREATE INDEX idx_fact_txn_state ON fact_transactions(state);
CREATE INDEX idx_fact_perf_fund ON fact_performance(amfi_code);
CREATE INDEX idx_fact_aum_date ON fact_aum(date_key);
CREATE INDEX idx_fact_aum_house ON fact_aum(fund_house);
