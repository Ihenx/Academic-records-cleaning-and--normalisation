-- Use the 'academic_records' database
use academic_records;

-- View all records from the academic_record table
select *
from academic_records;

-- View the structure of the academic_records table (column names, types, etc.)
describe academic_records;


-- ============================
-- 1 DATA CLEANING OPERATIONS
-- ============================


alter table academic_records
add column created_at timestamp default current_timestamp,
add column updated_at timestamp on update current_timestamp;

-- Since the tacademic table does not not have a primary key. create one 

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

-- drop the previous student id since it contains duplicates values which violate the rule of Primary key
alter table academic_records
drop column student_id;

-- rename the  id column to student id
alter table academic_records
rename column id to student_id;

-- modify to primary key
alter table academic_records
add primary key(student_id);

-- Correct common gender entry typos: 'Mle' to 'Male' and 'Fmale' to 'Female'
select distinct gender
from academic_records;

begin;
update academic_records
set gender = 
		case when gender in ("MALE","M") then "Male"
        when gender = "F" then "Female"
        else "Others"
        end;
commit;

-- create age column
alter table academic_records
add column age int
after date_of_birth;


begin;
update academic_records
set age = timestampdiff(year,date_of_birth, curdate());

commit;

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
    
select distinct grade
from academic_records;

begin;
update academic_records
set grade =
	case when grade in ("50", "0", "Incomplete") then "F"
    else upper(grade)
    end;


begin;
update academic_records
set instructor_phone = replace(replace(instructor_phone,"x","-"),".","-");

select *
from academic_records;

-- ========================
-- DATA MODELING SECTION
-- ========================

CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(50)
);

CREATE TABLE courses (
    course_code VARCHAR(50) PRIMARY KEY,
    course_title VARCHAR(50),
    credit_unit INT,
    dept_id INT,
    FOREIGN KEY (dept_id)
        REFERENCES departments (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);




-- ==========================================
-- POPULATE DIMENSION TABLES FROM PATIENTS
-- ==========================================
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
    

-- ============================================
-- STEP 1: Add Foreign Key Columns to Patients
-- ============================================

alter table academic_records
add column dept_id int,


-- Define relationships with foreign key constraints

add constraint registration_course_id
foreign key(course_code) references courses(course_code)
on delete cascade
on update cascade,

add constraint registration_dept_id
foreign key(dept_id) references departments(id)
on delete cascade 
on update cascade;

-- =====================================
-- STEP 2: Populate Foreign Key Columns
-- =====================================

update academic_records a
join departments d
on a.department =d.dept_name
set a.dept_id = d.id;

-- ====================================
-- STEP 3: Drop Denormalized Columns
-- ====================================


alter table academic_records
drop column department,
drop column course_title,
drop column credit_unit;

-- ====================================
-- STEP 4: Indexing for Optimization
-- ====================================

create index id_course_code on academic_records(course_code);
create index id_dept_id on academic_records(dept_id);
    
    









