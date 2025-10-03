/****************************************************************************************
	- HUMAN RESOURCE PERFORMANCE DATA ANALYSIS 
	- FLAT CSV FILE PARSE DATA IMPORT
    
	=====================================================================================
		HUMAN RESOURCE PERFORMANCE DATA CLEANSING  
    =====================================================================================
*/

SELECT * FROM hr_data_analysis.`human resources`;
SELECT COUNT(*) FROM hr_data_analysis.`human resources`; -- Dataset 22214 records
-- NOTE : termdate is null represent active employees while age > 18 illigible workforce
 
/* CREATE TABLE `human resources` (
  `ï»¿id` text,
  `first_name` text,
  `last_name` text,
  `birthdate` text,
  `gender` text,
  `race` text,
  `department` text,
  `jobtitle` text,
  `location` text,
  `hire_date` text,
  `termdate` text,
  `location_city` text,
  `location_state` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
*/

-- Cheking duplicates
WITH duplicate_check AS
(
SELECT *, 
	ROW_NUMBER() OVER(PARTITION BY employee_id,first_name,last_name,gender,race,department,
    jobtitle,location,location_city,location_state) AS duplicates_row
FROM `human resources`
)
SELECT *
FROM duplicate_check
WHERE duplicates_row > 1 ; -- There are no duplicate rows

-- Changing the column ï»¿id to employee_id
ALTER TABLE `human resources`
CHANGE COLUMN `ï»¿id` employee_id VARCHAR(20) NULL;

-- Checking the data type for the column 
DESCRIBE `human resources`; 

-- Converting the birthdate format to DATE 
SELECT birthdate FROM `human resources`; 

UPDATE `human resources`
SET birthdate = 
CASE 
	WHEN birthdate LIKE '%/%' THEN DATE_FORMAT (STR_TO_DATE (birthdate, '%m/%d/%Y'),'%Y-%m-%d')
    WHEN birthdate LIKE '%-%' THEN DATE_FORMAT (STR_TO_DATE (birthdate, '%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL 
END ;

-- SET SQL_SAFE_UPDATES = 0; 
-- SELECT birthdate FROM `human resources`; 

ALTER TABLE `human resources`
MODIFY COLUMN birthdate DATE;

-- Converting the hire_date format to DATE
SELECT hire_date FROM `human resources`; 

UPDATE `human resources`
SET hire_date = 
CASE 
	WHEN hire_date LIKE '%/%' THEN DATE_FORMAT (STR_TO_DATE (hire_date, '%m/%d/%Y'),'%Y-%m-%d')
    WHEN hire_date LIKE '%-%' THEN DATE_FORMAT (STR_TO_DATE (hire_date, '%m-%d-%Y'),'%Y-%m-%d')
    ELSE NULL 
END ;

ALTER TABLE `human resources`
MODIFY COLUMN hire_date DATE;

-- Converting termdate format to DATE
SELECT termdate FROM `human resources`;

-- 
UPDATE `human resources`
SET termdate = DATE(STR_TO_DATE(termdate, '%Y-%m-%d %H:%i:%s UTC'))
WHERE termdate IS NOT NULL AND termdate != ''; 

-- Note that: when termdate is null or empty, the employee is still working at the company  
-- Set null all the records that are empty 
UPDATE `human resources`
SET termdate = NULL 
WHERE termdate = '';

ALTER TABLE `human resources`
MODIFY COLUMN termdate DATE;

DESCRIBE `human resources`;
SELECT * FROM `human resources`;

-- Inspecting and filtering the data 

SELECT * FROM `human resources`;
-- Create age column 
ALTER TABLE `human resources`
ADD COLUMN age INT ;  

-- Populate age column by calculting the difference between birthdate and current date
UPDATE `human resources`
SET age = TIMESTAMPDIFF(YEAR, birthdate, CURDATE());

-- Min age and max age
SELECT 
	MIN(age) AS youngest,
    MAX(age) AS oldest
FROM `human resources`;

-- Chenking age value that < 18 to be retrieved from analysis
SELECT COUNT(*) 
FROM `human resources`
WHERE age < 18 ;

-- Count the records after cleansing 
	SELECT COUNT(*)
	FROM `human resources`
	WHERE age > 18 AND termdate IS NULL; -- 17482 cleaned records 

-- Create view hr to filter data (only for active employees)   
CREATE VIEW hr AS
SELECT *
FROM `human resources`
WHERE age > 18 AND termdate IS NULL;

-- Create view hr to filter data (for terminated employees)
CREATE VIEW hr_terminated AS
SELECT *
FROM `human resources`
WHERE age > 18 AND termdate IS NOT NULL; -- 3765 records of terminated employees


-- The end of the data cleaning

/*
	=====================================================================================
		HUMAN RESOURCE PERFORMANCE DATA EXPLORATORY
    =====================================================================================
*/
-- The view will we used for the exploratory analysis 
SELECT * FROM hr;

-- 1. WHAT IS THE GENDER BREAKDOWN OF THE EMPLOYEES ?
SELECT 
	gender, COUNT(*)
FROM hr
GROUP BY gender
ORDER BY 2 DESC;

-- 2. WHAT IS THE RACE ETHNICITY BREAKDOWN OF THE EMPLOYEES ?  
SELECT 
	race, COUNT(*)
FROM hr
GROUP BY race
ORDER BY 2 DESC;

-- 3.WHAT IS THE AGE DISTRIBUTION OF THE EMPLOYEES ?

SELECT 
	MIN(age) AS youngest,
    MAX(age) AS oldest
FROM hr; -- The 

SELECT
    CASE
		WHEN age >= 18 AND age < 31 THEN 'junior'
        WHEN age >= 31 AND age < 46 THEN 'senior'
        WHEN age >= 46 AND age < 60 THEN 'senior+'
        ELSE 'senior++'
    END AS group_age ,
    COUNT(*) AS Group_Count
FROM hr
GROUP BY 1
ORDER BY 2 DESC; 

-- 3.1. WHAT IS THE GENDER DISTRIBUTION OF THE EMPLOYEES BY AGE GROUP ?
SELECT
	CASE
		WHEN age >= 18 AND age < 31 THEN 'junior'
		WHEN age >= 31 AND age < 46 THEN 'senior'
		WHEN age >= 46 AND age < 60 THEN 'senior+'
		ELSE 'senior++'
	END AS group_age , 
    gender,
    COUNT(*)
FROM hr 
GROUP BY 1,2
ORDER BY 1 DESC;

-- 4. WHAT HOW MANY EMPLOYEES WORK AT THE HEADQUARTER VERSUS REMOTE LOCATION ?
SELECT 
	location, COUNT(*)
FROM hr
GROUP BY 1
ORDER BY 2 DESC;

-- 5. WHAT IS THE EVERAGE LENGHT OF EMPLOYEMENT FOR THE EMPLOYEES WHO HAVE BEEN TERMINATED?
SELECT
	ROUND(AVG(year_lenght),1) AS years,
    ROUND(AVG(month_lenght),1) AS months,
    ROUND(AVG(day_lenght),1) AS days
FROM(
SELECT 
	-- DATEDIFF(hire_date, termdate)/365 AS year_lenght, Another possibility is to use datediff function
	TIMESTAMPDIFF(YEAR, hire_date, termdate) AS year_lenght,
    TIMESTAMPDIFF(MONTH, hire_date, termdate) AS month_lenght,
    TIMESTAMPDIFF(DAY, hire_date, termdate) AS day_lenght
FROM hr_terminated) AS employees_lenght ;

-- 6. HOW DOES THE GENDER DISTRIBUTION VARY ACROSS DEPARTMENT AND JOB TITLE ?
SELECT 
	department, 
    gender, COUNT(*) AS distribution
FROM hr
GROUP BY 1,2
ORDER BY 1,3 DESC ; 
-- 
SELECT 
	department,jobtitle, 
    gender, COUNT(*) AS distribution
FROM hr
GROUP BY 1,2,3
ORDER BY 1,2,4 DESC ; 

-- 
SELECT 
	department, 
    COUNT(*) AS distribution
FROM hr
GROUP BY 1
ORDER BY 2 DESC ; 
 
SELECT COUNT(DISTINCT department) FROM hr;
SELECT COUNT(DISTINCT jobtitle) FROM hr;

-- 7. WHAT IS THE DISTRIBUTION OF JOBTITLE ACROSS THE COMPANY
SELECT 
	jobtitle, 
    COUNT(*) AS distribution
FROM hr
GROUP BY 1
ORDER BY 2 DESC ; 

-- 8. WHICH DEPARTMENT HAS THE HIGHEST TURN OVER RATE ?
-- TOTAL NUMBER OF EMPLOYEES WHO LEFT THE DEPT DIVIDED BY TOTAL NUMBER OF EMPLOYEES DEPT
SELECT
	department, total_depart, left_depart,
	ROUND((left_depart/total_depart) * 100,0) AS turnover_rate
FROM(
	SELECT 
		department, COUNT(*) AS total_depart, SUM(CASE
		WHEN termdate IS NOT NULL THEN 1 ELSE 0 END) AS left_depart
	FROM `human resources`
	WHERE age > 18 
	GROUP BY department) AS turnover 
ORDER BY 4 DESC;

-- 9. WHAT IS THE DISTRIBUTION OF EMPLOYEES ACROSS CITY AND STATE ?
SELECT 
	location_city,
    COUNT(*) AS distribution
FROM hr
GROUP BY 1
ORDER BY 2 DESC ; 

-- 
SELECT 
	location_state,
    COUNT(*) AS distribution
FROM hr
GROUP BY 1
ORDER BY 2 DESC ;

-- 10. HOW IS THE EMPLOYEES COUNT CHANGED OVER TIME BASED ON THE HIGHER DATES ? 
SELECT 
	years, hires,terminates,
    hires - terminates AS net_change,
    ROUND((hires - terminates)/hires * 100,2) AS count_change
FROM(
	SELECT
		YEAR(hire_date) AS years,
		COUNT(*) AS hires,
		SUM(CASE WHEN termdate IS NOT NULL THEN 1 ELSE 0 END) AS terminates
	FROM `human resources`
	GROUP BY 1) change_in_employees
ORDER BY 1 ASC;

-- 11. WHAT IS THE TENURE DISTRIBUTION FOR EACH DEPARTMENT OF TERMINATED EMPLOYEES?
SELECT
	department,
    ROUND(AVG(DATEDIFF(termdate, hire_date)/365),0) AS avg_tenure
FROM hr_terminated 
GROUP BY 1;

-- CREATE VIEW REPORT FOR POWER BI IMPORT
SELECT *
FROM `human resources`
WHERE age > 18 ; -- 21247 records of employees (active and terminated) 

/*
	=====================================================================================
		HUMAN RESOURCE KEY PERFORMANCE INDEX (KPI)  
    =====================================================================================
*/

-- KPI : TOTAL ACTIVE NUMBER OF EMPLOYEES
SELECT 
	COUNT(*) AS total_active_employees
FROM hr; 

-- KPI : GENDER DISTRIBUTION OF ACTIVE EMPLOYEES
SELECT 
	gender, COUNT(*) AS gender_distribution
FROM hr
GROUP BY 1 
ORDER BY 2 DESC; 

-- KPI : AVERAGE AGE OF WORKFORCE  
SELECT ROUND(AVG(age)) AS avg_age_employees 
FROM hr ; 

-- KPI : TURNOVER RATE 
SELECT
	(left_employees/total_employees) AS turnover_rate
FROM(
	SELECT 
		COUNT(*) AS total_employees,
		SUM(CASE WHEN termdate IS NOT NULL THEN 1 ELSE 0 END) AS left_employees
	FROM `human resources`
	WHERE age > 18) rate;
    


