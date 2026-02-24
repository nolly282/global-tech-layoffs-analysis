/*
 * 05_insights.sql
 * ────────────────────────────────────────────────────────────────
 * Purpose:
 *   Extract key business insights and patterns from the analysis-ready view
 *   (v_analysis_ready – 1644 rows with all features engineered).
 *
 *   This file contains only SELECT queries — no CREATE VIEW, no UPDATE, no new tables.
 *   Goal: Surface trends, rankings, breakdowns, and correlations that tell a story
 *   about tech layoffs 2020–2025.
 *
 *   Insights focus areas:
 *     1. Overall scale & impact of layoffs
 *     2. Trends over time (year, quarter, month)
 *     3. Top companies (volume & frequency)
 *     4. Industry impact (hardest-hit sectors)
 *     5. Company lifecycle / stage analysis
 *     6. Correlation with funding raised
 *     7. Severity & percentage distribution
 *     8. Quick geography view (USA vs rest)
 *
 *   Results from these queries will be:
 *     - Used to populate README.md tables
 *     - Guide dashboard design in Tableau Public
 *     - Highlighted in project summary / Upwork portfolio
 *
 *   Execution order: Run queries top to bottom; each is standalone.
 *   ────────────────────────────────────────────────────────────────
 */


-- -- ────────────────────────────────────────────────────────────────
-- -- 1. Overall scale & impact
-- -- ────────────────────────────────────────────────────────────────

-- -- Total overview
-- SELECT 
--     COUNT(*) AS total_events,
--     SUM("Laid_Off") AS total_laid_off,
--     ROUND( AVG("Percentage")::numeric , 1 ) AS avg_percentage_laid_off,
--     MIN("layoff_date") AS earliest_date,
--     MAX("layoff_date") AS latest_date
-- FROM v_analysis_ready;

-- -- Proportion from large layoffs
-- SELECT 
--     is_large_layoff,
--     COUNT(*) AS events,
--     ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_events,
--     SUM("Laid_Off") AS total_laid_off,
--     ROUND( 
--         (100.0 * SUM("Laid_Off") / SUM(SUM("Laid_Off")) OVER ())::numeric , 
--         1
--     ) AS pct_of_total_laid_off
-- FROM v_analysis_ready
-- GROUP BY is_large_layoff
-- ORDER BY is_large_layoff DESC;

-- -- ────────────────────────────────────────────────────────────────
-- -- 2. Trends over time
-- -- ────────────────────────────────────────────────────────────────

-- -- By year
-- SELECT 
--     "Year",
--     COUNT(*) AS events,
--     SUM("Laid_Off") AS total_laid_off,
--     ROUND( AVG("Percentage")::numeric , 1 ) AS avg_pct
-- FROM v_analysis_ready
-- GROUP BY "Year"
-- ORDER BY "Year";

-- -- By quarter
-- SELECT 
--     layoff_quarter,
--     COUNT(*) AS events,
--     SUM("Laid_Off") AS total_laid_off,
--     ROUND( AVG("Percentage")::numeric , 1 ) AS avg_pct
-- FROM v_analysis_ready
-- GROUP BY layoff_quarter
-- ORDER BY layoff_quarter;

-- -- By month (recent focus: last 24 months or so)
-- SELECT 
--     layoff_month,
--     COUNT(*) AS events,
--     SUM("Laid_Off") AS total_laid_off
-- FROM v_analysis_ready
-- WHERE layoff_month >= '2024-01'  -- adjust if needed
-- GROUP BY layoff_month
-- ORDER BY layoff_month;

-- -- ────────────────────────────────────────────────────────────────
-- -- 3. Top companies
-- -- ────────────────────────────────────────────────────────────────

-- -- Top 10 by total laid off
-- SELECT 
--     "Company",
--     SUM("Laid_Off") AS total_laid_off,
--     COUNT(*) AS num_events,
--     ROUND( AVG("Percentage")::numeric , 1 ) AS avg_pct
-- FROM v_analysis_ready
-- GROUP BY "Company"
-- ORDER BY total_laid_off DESC
-- LIMIT 10;

-- -- Companies with highest single-event percentage
-- SELECT 
--     "Company",
--     "layoff_date",
--     "Laid_Off",
--     "Percentage",
--     layoff_severity_bucket
-- FROM v_analysis_ready
-- ORDER BY "Percentage" DESC
-- LIMIT 10;

-- -- ────────────────────────────────────────────────────────────────
-- -- 4. Industry impact
-- -- ────────────────────────────────────────────────────────────────

-- -- Top industries by total laid off
-- SELECT 
--     industry_grouped,
--     COUNT(*) AS events,
--     SUM("Laid_Off") AS total_laid_off,
--     ROUND( AVG("Percentage")::numeric , 1 ) AS avg_pct
-- FROM v_analysis_ready
-- GROUP BY industry_grouped
-- ORDER BY total_laid_off DESC
-- LIMIT 10;

-- -- Severity distribution per industry (top 5 industries)
-- SELECT 
--     industry_grouped,
--     layoff_severity_bucket,
--     COUNT(*) AS events
-- FROM v_analysis_ready
-- WHERE industry_grouped IN (
--     SELECT industry_grouped 
--     FROM v_analysis_ready 
--     GROUP BY industry_grouped 
--     ORDER BY SUM("Laid_Off") DESC 
--     LIMIT 5
-- )
-- GROUP BY industry_grouped, layoff_severity_bucket
-- ORDER BY industry_grouped, events DESC;

-- ────────────────────────────────────────────────────────────────
-- 5. Company stage analysis
-- ────────────────────────────────────────────────────────────────

-- SELECT *
-- FROM v_features_stage
-- LIMIT 20;


-- Laid off by stage
SELECT 
    company_stage_simplified,
    COUNT(*) AS events,
    SUM("Laid_Off") AS total_laid_off,
    ROUND( AVG("Percentage")::numeric , 1 ) AS avg_pct,
    ROUND( 
        (100.0 * SUM("Laid_Off") / (SELECT SUM("Laid_Off") FROM v_analysis_ready))::numeric , 
        1
    ) AS pct_of_total_laid_off
FROM v_analysis_ready
GROUP BY company_stage_simplified
ORDER BY total_laid_off DESC;

-- High % cuts by stage
SELECT 
    company_stage_simplified,
    pct_laid_off_bucket,
    COUNT(*) AS events
FROM v_analysis_ready
GROUP BY company_stage_simplified, pct_laid_off_bucket
ORDER BY company_stage_simplified, events DESC;

-- ────────────────────────────────────────────────────────────────
-- 6. Funding correlation
-- ────────────────────────────────────────────────────────────────

-- Laid off by funding bucket
SELECT 
    funding_bucket,
    COUNT(*) AS events,
    SUM("Laid_Off") AS total_laid_off,
    ROUND( AVG("Percentage")::numeric , 1 ) AS avg_pct
FROM v_analysis_ready
GROUP BY funding_bucket
ORDER BY total_laid_off DESC;

-- Large layoffs by funding level
SELECT 
    funding_bucket,
    is_large_layoff,
    COUNT(*) AS events,
    SUM("Laid_Off") AS total_laid_off
FROM v_analysis_ready
GROUP BY funding_bucket, is_large_layoff
ORDER BY funding_bucket, is_large_layoff DESC;

-- ────────────────────────────────────────────────────────────────
-- 7. Severity & percentage distribution
-- ────────────────────────────────────────────────────────────────

-- Severity bucket distribution
SELECT 
    layoff_severity_bucket,
    COUNT(*) AS events,
    SUM("Laid_Off") AS total_laid_off,
    ROUND( 
        (100.0 * SUM("Laid_Off") / (SELECT SUM("Laid_Off") FROM v_analysis_ready))::numeric , 
        1
    ) AS pct_of_total
FROM v_analysis_ready
GROUP BY layoff_severity_bucket
ORDER BY total_laid_off DESC;

-- Percentage bucket distribution
SELECT 
    pct_laid_off_bucket,
    COUNT(*) AS events,
    SUM("Laid_Off") AS total_laid_off
FROM v_analysis_ready
GROUP BY pct_laid_off_bucket
ORDER BY total_laid_off DESC;

-- ────────────────────────────────────────────────────────────────
-- 8. Quick geography view
-- ────────────────────────────────────────────────────────────────

-- USA vs rest of world
SELECT 
    CASE WHEN "Country" = 'USA' THEN 'USA' ELSE 'Non-USA' END AS region_group,
    COUNT(*) AS events,
    SUM("Laid_Off") AS total_laid_off,
    ROUND( 
        (100.0 * SUM("Laid_Off") / (SELECT SUM("Laid_Off") FROM v_analysis_ready))::numeric , 
        1
    ) AS pct_of_total
FROM v_analysis_ready
GROUP BY region_group
ORDER BY total_laid_off DESC;



COPY (SELECT * FROM v_analysis_ready)
TO 'C:\Users\Chukwunomunso\Desktop\global-tech-layoffs-analysis\data\cleaned\tech_layoffs_analysis_ready.csv'
CSV HEADER;