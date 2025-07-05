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



--  1. Create a View: Student Academic Summary

CREATE OR REPLACE VIEW v_student_academic_summary AS
    SELECT 
        ar.student_id,
        ar.student_name,
        ar.gender,
        c.course_code,
        c.course_title,
        c.credit_unit,
        d.dept_name AS department,
        ar.instructor_name,
        ar.grade,
        ar.semester,
        ar.session
    FROM
        academic_records ar
            JOIN
        courses c ON ar.course_code = c.course_code
            JOIN
        departments d ON d.id = c.dept_id;
        
        
select *
from v_student_academic_summary;

-- 2. View: GPA Summary per Department
create or replace view v_dept_gpa_summary as
SELECT 
    d.dept_name AS departments,
    AVG(CASE
        WHEN grade = 'A' THEN 5
        WHEN grade = 'B' THEN 4
        WHEN grade = 'C' THEN 3
        WHEN grade = 'D' THEN 2
        ELSE 0
    END) AS avg_gpa,
    COUNT(ar.student_id) num_of_student
FROM
    academic_records ar
        JOIN
    courses c  
    on ar.course_code = c.course_code
join departments d 
on c.dept_id = d.id
GROUP BY d.dept_name
ORDER BY avg_gpa DESC;


select *
from v_dept_gpa_summary;


-- 3. Stored Procedure: Student Performance by Course

delimiter //

create procedure sp_get_student_academic_performance(in sp_student_id varchar(50))
begin

select 
  ar.student_id,
        ar.student_name,
        ar.gender,
        c.course_code,
        c.course_title,
        c.credit_unit,
        d.dept_name AS department,
        ar.grade,
        ar.semester,
        ar.session
from  academic_records ar
join courses c 
on ar.course_code = c.course_code
join departments d 
on c.dept_id = d.id
where ar.student_id = sp_student_id;

end //

delimiter ;

call sp_get_student_academic_performance('1021SEJOCS');
call sp_get_student_academic_performance('1026DOGUEC');


-- ✅ 4. Stored Procedure: Course Performance Summary

delimiter $$
create procedure sp_get_course_performance( in sp_course_title varchar(50))
begin

select 
  ar.student_id,
        ar.student_name,
        ar.gender,
        c.course_code,
        c.course_title,
        c.credit_unit,
        d.dept_name AS department,
        ar.grade,
        ar.semester,
        ar.session
from  academic_records ar
join courses c 
on ar.course_code = c.course_code
join departments d 
on d.id =c.dept_id
where c.course_title = sp_course_title;

end$$
delimiter ;

call sp_get_course_performance('Macroeconomics');

-- ✅ 5. Stored Procedure: Departmental Enrollment Count

delimiter //
create procedure sp_dept_enrollment_count(in sp_session varchar(50))
begin
SELECT 
    d.dept_name as department, COUNT(ar.student_id) num_student
FROM
    academic_records ar
        JOIN
    courses c ON ar.course_code = c.course_code
        JOIN
    departments d ON d.id = c.dept_id
WHERE
    session = sp_session
GROUP BY d.dept_name;
end//
delimiter ;

call sp_dept_enrollment_count('2022/2023');



    









