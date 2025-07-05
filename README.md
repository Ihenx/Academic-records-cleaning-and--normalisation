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

* Create a Unique Primary Key
```

 -- add another column called ID
 begin;
 alter table academic_records
 add column id varchar(50)
 after student_id;
 commit; 
 
 -- Update the 'id' column in the 'academic_records' table
 -- It combines:
 -- 1. student_id (e.g. 1234)
 -- 2. first 2 letters of the first name (from student_name)
 -- 3. first 2 letters of the last name (from student_name)
 -- 4. first 2 letters of the course_code
 -- All concatenated together and converted to uppercase
 begin;
 UPDATE academic_records 
 SET 
     id = UPPER(CONCAT(student_id,
                     LEFT(student_name, 2),
                     LEFT(SUBSTRING_INDEX(student_name, ' ', - 1),
                         2),
                     LEFT(course_code, 2)));
 commit;
```
```
-- drop the previous student id since it contains duplicates values which violate the rule of Primary key
alter table academic_records
drop column student_id;

-- rename the  id column to student id
alter table academic_records
rename column id to student_id;

-- modify to primary key
alter table academic_records
add primary key(student_id);
```
Purpose: Creates a synthetic primary key from existing values.

 ## Clean Up Gender Values
``` 
begin;
update academic_records
set gender = 
		case when gender in ("MALE","M") then "Male"
        when gender = "F" then "Female"
        else "Others"
        end;
commit;
```
Purpose: Standardizes gender entries into consistent labels.ie , to change the values gender column from 'Mle' to 'Male' and 'Fmale' to 'Female'

## Calculate Age from Date of Birth
```
alter table academic_records
add column age int
after date_of_birth;


begin;
update academic_records
set age = timestampdiff(year,date_of_birth, curdate());

commit;
```
