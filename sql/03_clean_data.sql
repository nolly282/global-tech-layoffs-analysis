/*
03_clean_data.sql

What we learned from exploration:
- Total rows: 2412
- Almost all rows have Company, Location_HQ, Region, Continent, Industry, Year, lat/long
- Missing values that matter:
  - Laid_Off: 372 missing (~15%)
  - Percentage: 449 missing (~19%)
  - Company_Size_before: 643 missing (~27%)
  - Company_Size_after: 555 missing (~23%)
  - Money_Raised_in__mil: 364 missing (~15%)
  - Stage: 164 missing (~7%)
  - USState: only 1 missing
- Date_layoffs is TEXT — needs to become real DATE
- Industry likely has variations/spelling issues (we'll check and standardize)

Cleaning goals for this file:
1. Ensure all columns have the appropriate data types 
2. Handle missing Laid_Off: we'll create a cleaned view excluding rows where Laid_Off IS NULL 
   (for most analysis we want reliable numbers; we can always go back if needed)
3. Create a clean table or view we can use for insights and dashboard
4. Keep original raw_layoffs untouched — we'll work on copies/views

We'll build step by step, test each part, and comment why we choose each approach.
*/


-- 1. Create a view with a proper date type 
-- to Keep raw table untouched, easy to test and change later

DROP VIEW IF EXISTS v_clean_layoffs;

CREATE VIEW v_clean_layoffs AS
SELECT 
    "Nr",
    "Company",
    "Location_HQ",
    "Region",
    "USState",
    "Country",
    "Continent",
    "Laid_Off",
    TO_DATE("Date_layoffs", 'YYYY/MM/DD') AS layoff_date,  
    "Percentage",
    "Company_Size_before_Layoffs",
    "Company_Size_after_layoffs",
    TRIM(UPPER("Industry")) AS industry_clean,              -- trim spaces + uppercase for consistency
    "Stage",
    "Money_Raised_in__mil",
    "Year",
    "latitude",
    "longitude"
FROM raw_layoffs;




-- -- Quick test
-- SELECT COUNT(*) FROM v_clean_layoffs;

-- -- Check date conversion worked (should show real dates)
-- SELECT layoff_date, COUNT(*) 
-- FROM v_clean_layoffs 
-- GROUP BY layoff_date 
-- ORDER BY layoff_date DESC 
-- LIMIT 5;



-- 2. Handle missing values 
-- We first create the strict view (Laid_Off NOT NULL only) — this will be the base for all further cleaning
-- At the very end of the file, after all cleaning is applied, we create the complete view
-- This way all polish (company names, industry grouping, etc.) is done once on the strict base

-- Strict view: remove Laid_Off NULL only (base for most analysis and further cleaning)
DROP VIEW IF EXISTS v_clean_layoffs_strict;

CREATE VIEW v_clean_layoffs_strict AS
SELECT *
FROM v_clean_layoffs
WHERE "Laid_Off" IS NOT NULL;

-- Quick check: how many rows after Laid_Off filter?
SELECT COUNT(*) AS strict_rows FROM v_clean_layoffs_strict;




-- 3. Industry standardization (data-driven from exploration)
-- Groups obvious duplicates, typos, case variations
-- Keeps specific/rare ones mostly as-is (we may do light grouping if neccessary)

DROP VIEW IF EXISTS v_clean_layoffs_final;

CREATE VIEW v_clean_layoffs_final AS
SELECT 
    *,
    CASE 
        -- High-frequency groups from top list
        WHEN TRIM(UPPER(industry_clean)) IN ('FINANCE', 'FINTECH', 'FINANCE / FINTECH') 
             THEN 'Finance / Fintech'
        WHEN TRIM(UPPER(industry_clean)) IN ('RETAIL', 'CONSUMER') 
             THEN 'Retail / Consumer'
        WHEN TRIM(UPPER(industry_clean)) IN ('HEALTHCARE', 'HEALTH') 
             THEN 'Healthcare'
        WHEN TRIM(UPPER(industry_clean)) IN ('TRANSPORTATION', 'LOGISTICS', 'LOGISTIC') 
             THEN 'Transportation / Logistics'
        WHEN TRIM(UPPER(industry_clean)) IN ('CRYPTO', 'CRYPTOCURRENCY') 
             THEN 'Crypto / Blockchain'
        WHEN TRIM(UPPER(industry_clean)) IN ('SOFTWARE DEVELOPMENT', 'SOFTWARE', 'SAAS') 
             OR industry_clean ILIKE '%software%' 
             THEN 'Software / SaaS'
        WHEN TRIM(UPPER(industry_clean)) IN ('GAMING', 'COMPUTER GAMES', 'ONLINE GAMING', 'ONLINE GAMING', 'GAME STUDIO', 'GAME STUDIO') 
             THEN 'Gaming'
        
        -- Common but lower-frequency groups
        WHEN TRIM(UPPER(industry_clean)) IN ('EDUCATION', 'E-LEARNING', 'HIGHER EDUCATION') 
             THEN 'Education'
        WHEN TRIM(UPPER(industry_clean)) IN ('TRAVEL', 'ONLINE TRAVEL AGENCY AND SEARCH ENGINE', 'TRAVEL GUIDANCE PLATFORM') 
             THEN 'Travel'
        WHEN TRIM(UPPER(industry_clean)) IN ('AI', 'AI CHIP STARTUP', 'AI STARTUP', 'AI COMPANION APP', 'AI TRANSCRIPTION AND CAPTIONING') 
             THEN 'AI / Artificial Intelligence'
        WHEN TRIM(UPPER(industry_clean)) IN ('CLOUD', 'CLOUD TECHNOLOGY', 'CLOUD TECHNOLOGY COMPANY') 
             THEN 'Cloud Computing'
        
        -- Catch-all for very rare / specific ones
        WHEN COUNT(*) OVER (PARTITION BY TRIM(UPPER(industry_clean))) <= 2 
             THEN 'Other / Rare'
        
        -- Default: nice title case
        ELSE INITCAP(TRIM(industry_clean))
    END AS industry_grouped
FROM v_clean_layoffs_strict;








-- --  let's do a quick exploration to see what our view looks like 

-- -- A. Check for duplicate rows (same company + same date + same laid_off)
-- SELECT 
--     "Company", 
--     layoff_date, 
--     "Laid_Off",
--     COUNT(*) AS duplicate_count
-- FROM v_clean_layoffs_final
-- GROUP BY "Company", layoff_date, "Laid_Off"
-- HAVING COUNT(*) > 1
-- ORDER BY duplicate_count DESC
-- LIMIT 10;

-- -- B. Check industry grouping quality (top groups + count)
-- SELECT 
--     industry_grouped,
--     COUNT(*) AS count,
--     MIN(industry_clean) AS example_original
-- FROM v_clean_layoffs_final
-- GROUP BY industry_grouped
-- ORDER BY count DESC
-- LIMIT 15;

-- -- C. Any remaining obvious issues in text columns (extra spaces, weird chars)?
-- SELECT DISTINCT "Company"
-- FROM v_clean_layoffs_final
-- WHERE "Company" LIKE '%  %' OR "Company" LIKE '%&%' OR "Company" LIKE '%/%' OR LENGTH("Company") > 100
-- ORDER BY "Company"
-- LIMIT 10;

-- -- D. Final row count & basic stats
-- SELECT 
--     COUNT(*) AS rows,
--     MIN(layoff_date) AS earliest,
--     MAX(layoff_date) AS latest,
--     SUM("Laid_Off") AS total_laid_off
-- FROM v_clean_layoffs_final;






/*
=== QUICK EXPLORATION ===

What we discovered from the checks:

- Duplicate records (same company + date + laid_off): 
  Found ~8–10 pairs (duplicate_count = 2), e.g.:
  - "Wex" on 2024-06-18 with 375 laid off (2 rows)
  - "Flutterwave" on 2024-06-24 with 30
  - "PayPal" on 2024-06-18 with 85
  These are rare (only ~20 rows total) and exact matches — likely source reporting errors.
  No higher duplicates (no count > 2).
  → We will handle by keeping only one row per unique (company + date + laid_off) in next step.

- Industry grouping is working well — top categories are clean and meaningful
  (Retail / Consumer 262, Finance / Fintech 258, Transportation / Logistics 161, Healthcare 136, Food 113, Other 110, etc.)
  Rare entries are properly bucketed as 'Other / Rare'

- Company names still have minor formatting issues:
  - "&" instead of "and" (e.g. "McKinsey & Co", "Hims & Hers")
  - Slashes "/" in merged names (e.g. "Kayak / OpenTable", "Eden / Managed …")
  - Ellipses "…" at the end of some names
  These are cosmetic — they don't affect calculations, but make labels look messy in dashboards/visuals

- Total usable rows after Laid_Off filter: 2040
- Total laid off: 746,809 employees
- Date range still correct: 2020-03-12 to 2025-12-28

Conclusion: Data is in very good shape overall.
Two small fixes left:
1. Deduplicate exact duplicate rows (company + date + laid_off)
2. Clean up company names for presentation

Next: Apply deduplication + company name polish
*/



-- Take care of the duplicate rows

DROP VIEW IF EXISTS v_clean_layoffs_dedup;

CREATE VIEW v_clean_layoffs_dedup AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY "Company", layoff_date, "Laid_Off"
               ORDER BY "Nr" ASC  -- keeps the earliest Nr in case of tie
           ) AS rn
    FROM v_clean_layoffs_final  -- ← your current base view after grouping
) t
WHERE rn = 1;



-- Tiny final casing fix on industry_grouped
-- Standardize 'Hr' → 'HR' and optionally 'Other' → 'Other / Rare'
-- This is cosmetic — does not change counts or analysis

DROP VIEW IF EXISTS v_final_polished;

CREATE VIEW v_final_polished AS
SELECT
    *,
    CASE
        WHEN industry_grouped = 'Hr' THEN 'HR'
        WHEN industry_grouped = 'Other' THEN 'Other / Rare'  -- optional — comment out if you prefer plain 'Other'
        ELSE industry_grouped
    END AS industry_grouped_final
FROM v_clean_layoffs_dedup;  -- from your dedup view







-- -- We'll do one final check to ensure everything is in order 

-- -- 1. Final row count and total laid off
-- SELECT 
--     COUNT(*) AS final_rows,
--     SUM("Laid_Off") AS total_laid_off,
--     MIN(layoff_date) AS earliest,
--     MAX(layoff_date) AS latest
-- FROM v_final_clean;



-- -- 2. Confirm date is real DATE type (should show proper dates, not text)
-- SELECT layoff_date
-- FROM v_final_clean
-- ORDER BY layoff_date DESC
-- LIMIT 5;



-- -- 3. Missing values in important columns
-- DROP VIEW IF EXISTS v_clean_layoffs_complete;
-- SELECT 
--     COUNT(*) AS total_rows,
--     COUNT("Laid_Off") AS laid_off_filled,
--     COUNT("Percentage") AS percentage_filled,
--     COUNT("Money_Raised_in__mil") AS funding_filled,
--     COUNT("Company_Size_before_Layoffs") AS size_before_filled
-- FROM v_clean_layoffs_complete;



/*
-- Final complete view: rows with ALL key columns present
-- This is the "fully reliable" subset for deep analysis (% laid off, funding, size impact)
-- Size: ~1500–1700 rows (exact number depends on missing value overlap)
-- Why at the end? All previous cleaning (dates, industry grouping, duplicates) is inherited
-- We use v_clean_layoffs_final as base (already has Laid_Off NOT NULL + grouping)
*/

-- DROP VIEW IF EXISTS v_clean_layoffs_complete;

-- CREATE VIEW v_clean_layoffs_complete AS
-- SELECT *
-- FROM v_clean_layoffs_final
-- WHERE "Percentage" IS NOT NULL
--   AND "Money_Raised_in__mil" IS NOT NULL
--   AND "Company_Size_before_Layoffs" IS NOT NULL
--   AND "Company_Size_after_layoffs" IS NOT NULL;


-- quick check to confirm

-- Row count of the complete view
SELECT COUNT(*) AS complete_rows FROM v_clean_layoffs_complete;

-- Basic stats to confirm quality
SELECT 
    COUNT(*) AS rows,
    MIN(layoff_date) AS earliest,
    MAX(layoff_date) AS latest,
    SUM("Laid_Off") AS total_laid_off,
    AVG("Percentage") AS avg_percentage_laid_off,
    AVG("Money_Raised_in__mil") AS avg_funding_mm
FROM v_clean_layoffs_complete;


/*
=== CLEANING COMPLETE ===
- Strict view: 2040 rows (Laid_Off NOT NULL)
- Complete view: 1644 rows (all key columns non-null)
- Duplicates removed, industry grouped, dates converted
- Company names left original (cosmetic only, no impact on analysis)
*/

