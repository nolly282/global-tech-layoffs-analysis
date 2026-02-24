-- create_raw_table.sql

-- This file creates the table that will hold the raw CSV data.

DROP TABLE IF EXISTS raw_layoffs; -- make t safe to rerun this file safely without getting "table already exists" errors.

-- we create an empty table with the column names and datatypes
CREATE TABLE raw_layoffs (
    "Nr"                           INTEGER,
    "Company"                      TEXT,
    "Location_HQ"                  TEXT,
    "Region"                       TEXT,
    "USState"                      TEXT,
    "Country"                      TEXT,
    "Continent"                    TEXT,
    "Laid_Off"                     DOUBLE PRECISION,
    "Date_layoffs"                 TEXT,          -- we'll turn this into real DATE later
    "Percentage"                   DOUBLE PRECISION,
    "Company_Size_before_Layoffs"  DOUBLE PRECISION,
    "Company_Size_after_layoffs"   DOUBLE PRECISION,
    "Industry"                     TEXT,
    "Stage"                        TEXT,
    "Money_Raised_in__mil"         DOUBLE PRECISION,
    "Year"                         INTEGER,
    "latitude"                     DOUBLE PRECISION,
    "longitude"                    DOUBLE PRECISION
);

