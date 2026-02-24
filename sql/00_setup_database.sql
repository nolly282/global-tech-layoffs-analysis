-- 00_setup_database.sql
-- This is the setup file. 
-- It creates the database we'll use for the whole project.

-- We put this in its own file because:
-- - CREATE DATABASE will throw an error if you try to run it again 
--   (once the database already exists).
-- - So we run this only once, then never touch it again.

-- Run this script when connected to your default PostgreSQL database 
-- (usually called 'postgres').

CREATE DATABASE tech_layoffs_analysis;
