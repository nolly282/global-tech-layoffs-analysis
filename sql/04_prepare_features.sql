/*
04_prepare_features.sql
In this script we want to add new derived columns for more insight  

Base view: v_clean_layoffs_complete (1644 rows, all key columns non-null)

Selected features (7 total):
1. Layoff severity bucket (small/medium/large)
2. Percentage laid off bucket (low/medium/high/very high)
3. Time features (month, quarter, year-month) - for trends over time
4. Calculated percentage laid off - to verify source % and handle edge cases
5. Company stage simplified (early/late/public/other) - for lifecycle analysis
6. Funding bucket (low/medium/high) - for funding vs layoff correlation
7. Layoff impact flag (is_large_layoff) - quick filter for large events

We'll add them step by step, test each one, and build a final analysis-ready view.
*/


-- 1: Layoff severity bucket
-- We categorizes the absolute scale of layoffs for easy grouping in analysis 
DROP VIEW IF EXISTS v_features_severity;
CREATE VIEW v_features_severity AS
SELECT
*,
CASE
WHEN "Laid_Off" <= 50 THEN 'Small'
WHEN "Laid_Off" <= 200 THEN 'Medium'
ELSE 'Large'
END AS layoff_severity_bucket
FROM v_clean_layoffs_complete;




-- 2: Percentage laid off bucket
-- here we bucket the relative impact using existing "Percentage" (as Low, Medium, High)
DROP VIEW IF EXISTS v_features_severity_pct;
CREATE VIEW v_features_severity_pct AS
SELECT
*,
CASE
WHEN "Percentage" <= 10 THEN 'Low (≤10%)'
WHEN "Percentage" <= 25 THEN 'Medium (11–25%)'
WHEN "Percentage" <= 50 THEN 'High (26–50%)'
ELSE 'Very High (>50%)'
END AS pct_laid_off_bucket
FROM v_features_severity;




-- 3: Time features (layoff_month, layoff_quarter, year_month)
-- this will enable time-series analysis (we'll find out trends by month/quarter/year, seasonality in layoffs).
DROP VIEW IF EXISTS v_features_time;
CREATE VIEW v_features_time AS
SELECT
*,
TO_CHAR("layoff_date", 'YYYY-MM') AS layoff_month,  
CASE
WHEN EXTRACT(MONTH FROM "layoff_date") BETWEEN 1 AND 3 THEN 'Q1'
WHEN EXTRACT(MONTH FROM "layoff_date") BETWEEN 4 AND 6 THEN 'Q2'
WHEN EXTRACT(MONTH FROM "layoff_date") BETWEEN 7 AND 9 THEN 'Q3'
ELSE 'Q4'
END AS layoff_quarter,  
CONCAT("Year", '-', LPAD(EXTRACT(MONTH FROM "layoff_date")::TEXT, 2, '0')) AS year_month  
FROM v_features_severity_pct;




-- 4: Calculated percentage laid off
-- Percentage already exists in the original data, but we'll recalculate it as a way to check data quality.
DROP VIEW IF EXISTS v_features_calc_pct;

CREATE VIEW v_features_calc_pct AS
SELECT
    *,
    CASE
        WHEN "Company_Size_before_Layoffs" = 0 THEN NULL  -- Avoid div by zero (though filtered)
        ELSE ROUND( 
            CAST( ("Laid_Off" / "Company_Size_before_Layoffs") * 100 AS NUMERIC), 
            1 
        )
    END AS calculated_pct_laid_off
FROM v_features_time;


SELECT 
    "Company",
    "Laid_Off",
    "Company_Size_before_Layoffs",
    "Percentage"                  AS original_pct,
    calculated_pct_laid_off       AS calc_pct,
    "Percentage" - calculated_pct_laid_off AS diff
FROM v_features_calc_pct
ORDER BY ABS("Percentage" - calculated_pct_laid_off) DESC  -- biggest differences first
LIMIT 20;

-- the difference is very tiny, except for "Arrival" which is nearly 7% apart.
-- let's check if there are more like it

SELECT 
    CASE 
        WHEN diff = 0                  THEN 'Exact match (0.0)'
        WHEN ABS(diff) <= 0.1          THEN 'Tiny (<= 0.1) - likely rounding'
        WHEN ABS(diff) <= 0.5          THEN 'Small (<= 0.5)'
        WHEN ABS(diff) <= 1.0          THEN 'Moderate (<= 1.0)'
        WHEN ABS(diff) <= 5.0          THEN 'Large (<= 5.0)'
        ELSE                            'Very large (> 5.0)'
    END AS difference_category,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM v_features_calc_pct), 2) AS pct_of_total
FROM (
    SELECT "Percentage" - calculated_pct_laid_off AS diff
    FROM v_features_calc_pct
    WHERE calculated_pct_laid_off IS NOT NULL
) sub
GROUP BY difference_category
ORDER BY MAX(ABS(diff)) DESC;


-- The dataset is good, no cause for alarm.




-- 5: Company stage simplified
-- We groups detailed "Stage" values into meaningful lifecycle categories for easier analysis
--       (e.g. early startups vs mature public companies)
DROP VIEW IF EXISTS v_features_stage;

CREATE VIEW v_features_stage AS
SELECT 
    *,
    CASE 
        WHEN "Stage" IN ('Seed', 'Series A', 'Series B') 
            THEN 'Early Stage'
        WHEN "Stage" IN ('Series C', 'Series D', 'Series E', 'Series F+', 'Private Equity') 
            THEN 'Late Stage'
        WHEN "Stage" = 'Post-IPO' OR "Stage" ILIKE '%IPO%' OR "Stage" ILIKE '%Public%'
            THEN 'Public'
        WHEN "Stage" IN ('Unknown', 'Other', '') OR "Stage" IS NULL 
            THEN 'Unknown / Other'
        ELSE 'Other / Mid-Stage'  -- catch Series whatever not covered
    END AS company_stage_simplified
FROM v_features_calc_pct;   -- or from v_features_time if you skip calc_pct





-- 6: Funding bucket
-- We Groups total funding raised ("Money_Raised_in__mil") into buckets to analyze 
--      patterns like: Do highly funded companies still have large layoffs? 
--      Or are smaller-funded startups more aggressive with cuts?
-- Buckets: Low (<$50M), Medium ($50–200M), High (>$200M)
-- Note: Values are in millions USD (e.g. 10700 = $10.7B)

DROP VIEW IF EXISTS v_features_funding;

CREATE VIEW v_features_funding AS
SELECT 
    *,
    CASE 
        WHEN "Money_Raised_in__mil" < 50 OR "Money_Raised_in__mil" IS NULL THEN 'Low (<$50M)'
        WHEN "Money_Raised_in__mil" <= 200 THEN 'Medium ($50–200M)'
        ELSE 'High (>$200M)'
    END AS funding_bucket
FROM v_features_stage;  





-- 7: Layoff impact flag
-- Why: Creates a simple 1/0 flag for events where Laid_Off > 200
--      Makes it easy to filter, sum, or calculate proportions of "significant" layoffs
--      (e.g. large layoffs account for X% of total events but Y% of total people laid off)

DROP VIEW IF EXISTS v_analysis_ready;

CREATE VIEW v_analysis_ready AS
SELECT 
    *,
    CASE 
        WHEN "Laid_Off" > 200 THEN 1
        ELSE 0
    END AS is_large_layoff
FROM v_features_funding;   




-- DROP VIEW IF EXISTS v_analysis_ready;



-- DROP VIEW IF EXISTS v_features_stage;




/*
 * ────────────────────────────────────────────────────────────────
 *
 *  a little reminder about what we cooked up in this file:
 *
 * Started from our super-clean base view (v_clean_layoffs_complete – 1644 solid rows, 
 * no missing key values, total laid off ~746k people).
 *
 * Step-by-step, we built 7 new derived columns/features one view at a time – 
 * chaining them nicely so we could test each addition without breaking anything.
 *
 * The 7 features we added:
 * 1. layoff_severity_bucket     → Small (≤50) / Medium (51–200) / Large (201+)
 * 2. pct_laid_off_bucket        → Low (≤10%) / Medium (11–25%) / High (26–50%) / Very High (>50%)
 * 3. Time breakdowns            → layoff_month (YYYY-MM), layoff_quarter (Q1–Q4), year_month
 * 4. calculated_pct_laid_off    → Recomputed percentage to double-check the original column 
 *                                 (matched 99.6% of rows within 0.5%, only 1 outlier ~7% off – data is trustworthy!)
 * 5. company_stage_simplified   → Early Stage / Late Stage / Public / Other
 * 6. funding_bucket             → Low (<$50M) / Medium ($50–200M) / High (>$200M)
 * 7. is_large_layoff            → 1 if Laid_Off > 200, else 0 (quick flag for big-impact events)
 *
 * Final output: v_analysis_ready – our one-stop analysis-ready view with 
 * ALL original columns + the 7 new features, zero NULLs in key places, ready for insights & viz.
 
 * Next up: 05_insights.sql – time to find the juicy stories in the numbers 
 */



