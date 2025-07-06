 # Academic Records Data Cleaning & Normalization (MySQL)

![ERD for Academic Record](https://github.com/user-attachments/assets/65ee4bad-dd2f-4bc1-9e72-0ce030d456e1)



 
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
Purpose:Derives an age column from date_of_birth.

* Fix Semester and Grade Values
 ```
  -- Correct common semester entry typos: ' 2023 Spring' to 'Spring 2023' and 'Fall2022' to 'Fall 2022'
select distinct semester
from academic_records

begin;
update academic_records
set semester =
	case when semester = "2023 Spring" then "Spring 2023"
    when semester = "Fall2022" then  "Fall 2022"
    else "Summer 2023"
    end;
```
```
begin;
update academic_records
set grade =
	case when grade in ("50", "0", "Incomplete") then "F"
    else upper(grade)
    end;
```
* Fix Instructor Phone Format
  ```
  	begin;
	update academic_records
	set instructor_phone = replace(replace(instructor_phone,"x","-"),".","-");
  ```

Purpose: Cleans and formats phone numbers.

### Data Cleaning Summary
Data Cleaning Steps
* Removed inconsistent and invalid values in gender, grade, and semester.

* Generated a unique student_id using string functions.

* Created a derived age column using TIMESTAMPDIFF().

* Standardized formats for phone numbers and email addresses.

* Introduced audit columns (created_at, updated_at).

## Database Normalization & Modeling
* Create Lookup Tables
  ```
	  -- create department table
	CREATE TABLE departments (
	    id INT PRIMARY KEY AUTO_INCREMENT,
	    dept_name VARCHAR(50)
	);
	
	-- create course table
	CREATE TABLE courses (
	    course_code VARCHAR(50) PRIMARY KEY,
	    course_title VARCHAR(50),
	    credit_unit INT,
	    dept_id INT,
	    FOREIGN KEY (dept_id)
	        REFERENCES departments (id)
	        ON DELETE CASCADE ON UPDATE CASCADE
	);
  ```
* Populate Them
  ```
	  	insert into departments(dept_name)
	 SELECT DISTINCT
	    department
	FROM
	    academic_records;
	    
	    
	insert into courses(course_code, course_title, credit_unit,dept_id)
	SELECT DISTINCT
	    course_code, course_title, credit_unit, d.id
	FROM
	    academic_records a
	        JOIN
	    departments d ON a.department = d.dept_name;
    ```
* Link Foreign Keys
  ```
	-- Define relationships with foreign key constraints
	alter table academic_records
	add constraint registration_course_id
	foreign key(course_code) references courses(course_code)
	on delete cascade
	on update cascade,
	
	add constraint registration_dept_id
	foreign key(dept_id) references departments(id)
	on delete cascade 
	on update cascade;
   ```
* Drop Redundant Columns
  ```
	  alter table academic_records
	drop column department,
	drop column course_title,
	drop column credit_unit;
	```
* Performance Optimization
  ```
	create index id_course_code on academic_records(course_code);
	create index id_dept_id on academic_records(dept_id);
	```
### Data Modeling Summary

* Normalized flat data into:

	* `departments`
	
	* `courses`
	
	* `academic_records`

* Added foreign keys to enforce referential integrity.
* Dropped redundant Columns

*Created indexes for faster query performance.

## Author
Godspower Iheanacho <br>
Data Analyst | SQL Enthusiast | BI Developer <br>
[LinkedIn](https://www.linkedin.com/in/godspower-iheanacho-a71829217/)



	

