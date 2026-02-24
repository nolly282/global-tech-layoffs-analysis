-- 02_explore_raw_data.sql
-- This file explores the raw data after importing the CSV.
-- Goal: Get a complete picture of the dataset.

-- -- 1. How many rows did we actually load?
-- SELECT COUNT(*) AS total_rows_loaded
-- FROM raw_layoffs;

-- -- 2. view the first and last 10 rows — to see the actual data
-- -- first 10
-- SELECT *
-- FROM raw_layoffs
-- LIMIT 10;

-- -- last 10
-- SELECT * FROM raw_layoffs
-- ORDER BY "Nr" DESC
-- LIMIT 10;

-- -- 3. Missing values for EVERY column
-- SELECT 
--     COUNT(*) AS total_rows,
--     COUNT("Nr")                  AS Nr_filled,
--     COUNT("Company")             AS Company_filled,
--     COUNT("Location_HQ")         AS Location_HQ_filled,
--     COUNT("Region")              AS Region_filled,
--     COUNT("USState")             AS USState_filled,
--     COUNT("Country")             AS Country_filled,
--     COUNT("Continent")           AS Continent_filled,
--     COUNT("Laid_Off")            AS Laid_Off_filled,
--     COUNT("Date_layoffs")        AS Date_filled,
--     COUNT("Percentage")          AS Percentage_filled,
--     COUNT("Company_Size_before_Layoffs") AS Size_before_filled,
--     COUNT("Company_Size_after_layoffs")  AS Size_after_filled,
--     COUNT("Industry")            AS Industry_filled,
--     COUNT("Stage")               AS Stage_filled,
--     COUNT("Money_Raised_in__mil") AS Funding_filled,
--     COUNT("Year")                AS Year_filled,
--     COUNT("latitude")            AS Latitude_filled,
--     COUNT("longitude")           AS Longitude_filled
-- FROM raw_layoffs;


-- 4. Thorough check of Industry values — find all variations / typos / casing issues
-- Goal: See the real distribution before deciding how to group them

-- A. All unique industry values + count (sorted by frequency)
SELECT 
    "Industry" AS original_industry,
    TRIM(UPPER("Industry")) AS cleaned_upper,
    COUNT(*) AS row_count
FROM raw_layoffs
GROUP BY "Industry", TRIM(UPPER("Industry"))
ORDER BY row_count DESC;

-- -- B. Top 30 most common industries (quick overview)
-- SELECT 
--     TRIM(UPPER("Industry")) AS industry_upper,
--     COUNT(*) AS count,
--     STRING_AGG(DISTINCT "Industry", ' | ') AS original_variations
-- FROM raw_layoffs
-- GROUP BY TRIM(UPPER("Industry"))
-- ORDER BY count DESC
-- LIMIT 30;

-- C. Industries that appear only once or twice (possible typos / rare entries)
SELECT 
    "Industry",
    COUNT(*) AS count
FROM raw_layoffs
GROUP BY "Industry"
HAVING COUNT(*) <= 2
ORDER BY count DESC;



/*
SUMMARY OF INITIAL DATA EXPLORATION

- Total rows loaded: 2412
- All rows have: Nr, Company, Location_HQ, Region, Continent, Laid_Off (wait no), Date_layoffs, Industry, Year, latitude, longitude
- Almost complete: USState (2411/2412 — only 1 missing)
- Significant missing values:
  - Laid_Off:        2040 filled → 372 rows missing (15.4%)
  - Percentage:      1963 filled → 449 rows missing (18.6%)
  - Company_Size_before_Layoffs: 1769 filled → 643 missing (26.7%)
  - Company_Size_after_layoffs:  1857 filled → 555 missing (23.0%)
  - Money_Raised_in__mil (funding): 2048 filled → 364 missing (15.1%)
  - Stage:           2248 filled → 164 missing (6.8%)

Key observations:
- Missing Laid_Off means we cannot calculate total impact for ~15% of records. we will decide how to handle (exclude, impute, flag)
- Percentage is missing more often than Laid_Off -> probably only calculated when both before/after size are known
- Company size before/after are missing the most -> this limits our ability to calculate actual % laid off in many cases
- Funding and Stage are reasonably complete —> 
- Location data is almost perfect — excellent for geographic visualizations later

Next step: Cleaning
We should:
1. Convert Date_layoffs to proper DATE type
2. Decide how to handle missing Laid_Off 
3. Standardize Industry names (many variations likely)
4. Possibly create derived columns 
5. Create a clean view or table for analysis

This exploration shows the data is usable but needs thoughtful cleaning.
*/
