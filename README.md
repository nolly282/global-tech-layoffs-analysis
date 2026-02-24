# Global Tech Layoffs Analysis 2020–2025

An end-to-end data analysis project: from raw, messy CSV → SQL cleaning & feature engineering → interactive Tableau dashboard.

This project explores one question:
What really happened during the global tech layoff wave, and who was hit hardest?

## Overview
- **Dataset**: Kaggle (layoffs.fyi via ulrikeherold/tech-layoffs-2020-2025)  
  - Raw rows: 2,412  
  - Cleaned rows: 1,644 complete events (duplicates removed, industries standardized, nulls filtered)  
  - Total laid off: ~747,000 employees  
  - Date range: March 12, 2020 – December 28, 2025  

- **Focus**: Explore layoff trends, severity, timing, industries, company stages, funding levels, and geography.

## Tools Used
- PostgreSQL + pgAdmin -> cleaning, feature engineering, insights  
- Tableau Public -> visualization & dashboard  
- VS Code -> scripting -> quick dataset exploration 

## Data Cleaning Philosophy
- Instead of “fixing” missing data with assumptions, I chose: No imputation. Only complete events.
**That meant** 
- Filtering out rows with NULL values in critical columns   
- Removed ~8–10 duplicate rows  
- Standardized industries labels  
- Grouping rare industries into "Other / Rare"
- Final dataset: 1,644 clean, consistent, analysis-ready events.

## Feature Engineering
**To move beyond basic counts, I engineered 7 analytical features:**
- Layoff severity buckets
- Percentage reduction buckets
- Time features (year, month extraction)
- Calculated percentage validation
- Verified Percentage column (99.6% match within 0.5%, 1 outlier noted)
- Company stage simplification
- Funding size buckets
- Large layoff flag (>200 employees)

## Key Findings
- Large layoffs (>200 people) = ~15% of events but ~80–85% of total job losses  
- Peak year: 2023 (highest total laid off)  
- January often shows elevated activity (annual planning/budget resets)  
- Public companies drove majority of headcount reduction  
- Top industries by volume: AI, RETAIL (AI had deeper relative cuts)  
- High-funded companies (> $200M) still accounted for significant layoffs  
- USA: ~75% of total laid off despite ~60% of events

## Interactive Dashboard
Live version (Tableau Public):  
[Global Tech Layoffs Analysis 2020–2025](https://public.tableau.com/views/[PASTE-YOUR-LINK-HERE])



## Folder Structure (at completion)
global-tech-layoffs-analysis/
├── data/
│   ├── raw/
│   │   └── tech_layoffs_til_2025.csv
│   └── cleaned/
│       └── tech_layoffs_analysis_ready.csv
├── sql/
│   ├── 00_setup_database.sql
│   ├── 01_create_raw_table.sql
│   ├── 02_explore_raw_data.sql
│   ├── 03_clean_data.sql
│   ├── 04_prepare_features.sql
│   └── 05_insights.sql
├── viz/
│   ├── tech_layoffs_analysis.twb
│   └── screenshots/          # dashboard images
├── PROCESS.md                # development log
└── README.md

## How to Reproduce
1. Clone the repo:
   ```bash
   git clone https://github.com/yourusername/global-tech-layoffs-analysis.git
