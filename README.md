 # Academic Records Data Cleaning & Normalization (MySQL)
 ## Overview
This project focuses on transforming a messy, denormalized academic records dataset into a clean, structured, and normalized relational database using MySQL. The goal is to demonstrate real-world data cleaning, schema design, normalization, and query optimization skills that are essential for roles in Data Analytics, Data Engineering, and Database Administration.

##  Data Cleaning Steps

*  Create Audit Columns
  
```
  ALTER TABLE academic_records
  ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN updated_at TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
```
Purpose: Adds timestamps to track when rows are created or updated.
