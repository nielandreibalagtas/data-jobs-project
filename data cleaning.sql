-- NIEL BALAGTAS DATA CLEANING DS_JOBS 4/23/2026

SELECT *
FROM ds_jobs_raw;

-- CREATE STAGING TABLE
-- CHANGED DATA TYPE OF COLUMNS WITH THE APPROPRIATE DATA TYPE
CREATE TABLE ds_jobs_staging (
    `index` INT,
    `job_title` VARCHAR(100),
    `salary_estimate` VARCHAR(50),
    `job_description` TEXT,
    `rating` DOUBLE,
    `company_name` VARCHAR(100),
    `location` VARCHAR(50),
    `headquarters` VARCHAR(50),
    `size` VARCHAR(50),
    `founded` INT,
    `type_of_ownership` VARCHAR(50),
    `industry` VARCHAR(50),
    `sector` VARCHAR(50),
    `revenue` VARCHAR(50),
    `competitors` VARCHAR(150)
);
INSERT INTO ds_jobs_staging
SELECT *
FROM ds_jobs_raw;
	
SELECT *
FROM ds_jobs_staging;


-- REMOVE DUPLICATES
-- USED ROW NUMBER TO IDENTIFY RECORDS WITH DUPLICATES
WITH ds_duplicates AS
(
	SELECT *,
    ROW_NUMBER() OVER(PARTITION BY job_title, salary_estimate, rating, company_name, location, headquarters, size, founded, type_of_ownership, industry, sector, revenue, competitors) AS row_num
    FROM ds_jobs_staging
)
SELECT *
FROM ds_duplicates
WHERE row_num > 1;

-- DELETING DUPLICATE ROWS
DELETE
FROM ds_jobs_staging
WHERE `index` IN (
	SELECT `index`
    FROM (
		SELECT `index`,
        ROW_NUMBER() OVER(PARTITION BY job_title, salary_estimate, rating, company_name, location, headquarters, size, founded, type_of_ownership, industry, sector, revenue, competitors) AS row_num
		FROM ds_jobs_staging
    ) AS subquery 
	WHERE row_num > 1
);

-- END OF REMOVING DUPLICATE DATA


-- STANDARDIZE THE DATA 
-- JOB TITLES LIKE Analytics Manager AND Analytics Manager - Data Mart ARE SIMPLIFIED INTO ONE JOB TITLE
-- SAME PROCESS FOR ALL SIMILAR MAIN JOB TITLES BUT WITH DIFFERENT FIELDS
SELECT DISTINCT job_title
FROM ds_jobs_staging
ORDER BY job_title;

-- INSTEAD OF USING THIS QUERY I WILL CATEGORIZE THE JOB TITLES INTO SIMPLIFIED ONES
SELECT job_title, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(job_title,'/', 1), '-', 1)) AS job_title_cleaned
FROM ds_jobs_staging
;

-- SIMPLIFIED JOB TITLES USING CASE STATEMENT
-- I CAREFULLY ARRANGED THE CASE STATEMENTS SO THAT IT WILL RETURN THE APPROPRIATE SIMPLIFIED TITLE
-- FOR THE NEW CLEANED COLUMN
SELECT DISTINCT job_title,
CASE
	WHEN job_title LIKE '%Architect%' THEN 'Data Architect'
	WHEN job_title LIKE '%Director%' THEN 'Director Role'
	WHEN job_title LIKE '%VP%' OR job_title LIKE '%Vice President%' THEN 'Vice President Role'
    WHEN job_title LIKE '%Modeler%' THEN 'Data Modeler'
	WHEN job_title LIKE '%Manager%' THEN 'Data Manager'
    WHEN job_title LIKE '%Machine Learning%' THEN 'Machine Learning Engineer'
    WHEN job_title LIKE '%Engineer%' THEN 'Data Engineer'
    WHEN job_title LIKE '%Developer%' THEN 'Developer'
    WHEN job_title LIKE '%Analyst%' OR job_title LIKE '%Analytics%' THEN 'Data Analyst'
	WHEN job_title LIKE '%Scientist%' OR job_title LIKE '%Science%' THEN 'Data Scientist'
END AS cleaned_job_title
FROM ds_jobs_staging;
-- WHERE job_title LIKE '%Developer%';

-- CREATING A NEW COLUMN FOR STAGING TABLE AND INSERTING THE CLEANED VALUES
ALTER TABLE ds_jobs_staging
ADD COLUMN cleaned_job_title VARCHAR(50);

UPDATE ds_jobs_staging
SET cleaned_job_title = CASE
	WHEN job_title LIKE '%Architect%' THEN 'Data Architect'
	WHEN job_title LIKE '%Director%' THEN 'Director Role'
	WHEN job_title LIKE '%VP%' OR job_title LIKE '%Vice President%' THEN 'Vice President Role'
    WHEN job_title LIKE '%Modeler%' THEN 'Data Modeler'
	WHEN job_title LIKE '%Manager%' THEN 'Data Manager'
    WHEN job_title LIKE '%Machine Learning%' THEN 'Machine Learning Engineer'
    WHEN job_title LIKE '%Engineer%' THEN 'Data Engineer'
    WHEN job_title LIKE '%Developer%' THEN 'Developer'
    WHEN job_title LIKE '%Analyst%' OR job_title LIKE '%Analytics%' THEN 'Data Analyst'
	WHEN job_title LIKE '%Scientist%' OR job_title LIKE '%Science%' THEN 'Data Scientist'
END;

SELECT cleaned_job_title
FROM ds_jobs_staging;


-- SALARY ESTIMATE
-- SALARY ESTIMATE CONTAINS $137K-$171K (Glassdoor est.) AS VALUES
-- SEPARATING AND FINDING THE MIN AND MAX OF SALARIES AS WELL AS THEIR AVERAGE
-- ADDED COLUMNS FOR MIN ESTIMATE, MAX ESTIMATE AND AVERAGE SALARY
-- NOTE THAT SALARY IS IN 'K' FORMAT SO MULTIPLY BY 1000 ALWAYS
SELECT DISTINCT salary_estimate
FROM ds_jobs_staging;

-- CLEANING THE SALARY ESTIMATE (REMOVING UNNECESSARY CHARACTERS) AND FINDING THE MIN MAX OF ESTIMATES USING CTE AND SUBSTRING_INDEX
WITH cleaned_estimate_cte AS
(
SELECT salary_estimate, SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(salary_estimate, '(', 1),'K',1),'$',-1) AS cleaned_estimate_min,
SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(salary_estimate, '(', 1),'K',2),'$',-1) AS cleaned_estimate_max
FROM ds_jobs_staging
)
SELECT salary_estimate, SUBSTRING_INDEX(cleaned_estimate_min, '-', 1) AS min_estimate, SUBSTRING_INDEX(cleaned_estimate_max, '-', -1) AS max_estimate
FROM cleaned_estimate_cte;

ALTER TABLE ds_jobs_staging
ADD COLUMN min_salary_estimate INT;

UPDATE ds_jobs_staging
SET min_salary_estimate = SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(salary_estimate, '(', 1),'K',1),'$',-1),'-',1);

ALTER TABLE ds_jobs_staging
ADD COLUMN max_salary_estimate INT;

UPDATE ds_jobs_staging
SET max_salary_estimate = SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(salary_estimate, '(', 1),'K',2),'$',-1),'-',-1);

SELECT salary_estimate, min_salary_estimate, max_salary_estimate
FROM ds_jobs_staging;

-- FINDING THE AVERAGE OF ESTIMATES AND ROUNDING THEM TO 2 DECIMAL PLACES
SELECT (min_salary_estimate + max_salary_estimate) / 2
FROM ds_jobs_staging;

ALTER TABLE ds_jobs_staging
ADD COLUMN average_salary DECIMAL(10,2);

UPDATE ds_jobs_staging
SET average_salary = ROUND((min_salary_estimate + max_salary_estimate) / 2,2);

SELECT salary_estimate, min_salary_estimate, max_salary_estimate, average_salary
FROM ds_jobs_staging;

-- COMPANY NAME
-- ORIGINALY THE COMPANY NAME IS RECORDED LIKE THIS
-- "Healthfirst
-- 3.1"
-- BUT SINCE I USED AI TO MANUALLY IMPORT THE DATASET
-- THE FORMAT IS FIXED WHICH IS ALSO THE MAIN REASON WHY THE DATA WIZARD IMPORT IS NOT WORKING PROPERLY
-- REMOVING THE RATING RIGHT AFTER THE NAME
-- I FIGURED OUT A NEW FUNCTION REGEXP WHICH MATCHES PATTERNS IN STRINGS
-- I ALSO FOUND A WEIRD VALUE 'bioMÃ©rieux' IN THE COMPANY NAME, IM NOT SURE IF THIS IS THE REAL NAME OF THE COMPANY OR A IMPORT ERROR
-- A RECOMMENED FIX HERE IS TO REIMPORT THE DATASET AND FIX MY PROMPT TO MATCH THE FORMAT OF MYSQL
-- I'LL LEAVE THIS AS IS FOR THE SAKE OF THIS PROJECT
SELECT DISTINCT company_name
FROM ds_jobs_staging;

-- USED REPLACE AND SUBSTRING INDEX TO REMOVE THE RATING THEN A CASE STATEMENT TO KEEP COMPANIES THAT DOES NOT HAVE
-- RATINGS AFTER IN THE FIRST PLACE
SELECT DISTINCT company_name,
CASE
	WHEN company_name REGEXP '[0-9]$' THEN REPLACE(company_name, SUBSTRING_INDEX(company_name, ' ', -1),'')
    ELSE company_name
END AS cleaned_company_name
FROM ds_jobs_staging;

ALTER TABLE ds_jobs_staging
ADD COLUMN cleaned_company_name VARCHAR(100);

UPDATE ds_jobs_staging
SET cleaned_company_name = CASE
	WHEN company_name REGEXP '[0-9]$' THEN TRIM(REPLACE(company_name, SUBSTRING_INDEX(company_name, ' ', -1),''))
    ELSE company_name
END;

SELECT company_name, cleaned_company_name
FROM ds_jobs_staging;


-- LOCATION AND HEADQUARTERS
-- USED SUBSTRING INDEX TO SEPARATE THE CITY AND STATE OF LOCATIONS
-- A COMMA IS USED TO SEPARATE THE CITY AND STATE
-- SOME VALUES ARE THE STATE THEMSELVES AND THERE IS A VALUE THAT IS THE COUNTRY ITSELF (UNITED STATES),
-- I MADE IT NULL ALTHOUGH THIS IS DATA SCIENCE JOBS FROM US, SINCE THERE IS NO WAY OF KNOWING WHERE IS THAT LOCATED IN UNITED STATES
SELECT DISTINCT location, SUBSTRING_INDEX(location, ',', 1) AS CITY,
CASE
	WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'Remote' THEN 'Remote'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'United States' THEN NULL
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'Utah' THEN 'UT'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'New Jersey' THEN 'NJ'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'Texas' THEN 'TX'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'California' THEN 'CA'
    ELSE TRIM(SUBSTRING_INDEX(location, ',', -1))
END AS STATE
FROM ds_jobs_staging;
-- WHERE location NOT LIKE '%,%';

-- SAME PROCESS GOES FOR HEADQUARTERS
-- BUT THIS TIME IM KEEPING THE STATE VALUES AS IS TOO
-- THERE ARE ALSO NO VALUES THAT IS NOT SEPARATED WITH A COMMA
SELECT DISTINCT headquarters, SUBSTRING_INDEX(headquarters, ',', 1) AS CITY, TRIM(SUBSTRING_INDEX(headquarters, ',', -1)) AS STATE
FROM ds_jobs_staging;

-- UPDATING THE TABLE
ALTER TABLE ds_jobs_staging
ADD COLUMN location_city VARCHAR(70);

ALTER TABLE ds_jobs_staging
ADD COLUMN location_state VARCHAR(70);

ALTER TABLE ds_jobs_staging
ADD COLUMN headquarters_city VARCHAR(70);

ALTER TABLE ds_jobs_staging
ADD COLUMN headquarters_state VARCHAR(70);

-- UPDATE: I ALSO NULLED THE UNITED STATES IN THE LOCATION CITY
-- JUST LIKE IN LOCATION STATE, UNITED STATE IS NOT A CITY VALUE HENCE NULL
UPDATE ds_jobs_staging
SET location_city = CASE
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'United States' THEN NULL
    ELSE SUBSTRING_INDEX(location, ',', 1)
END;

SELECT location_city
FROM ds_jobs_staging
WHERE location_city = 'United States';

UPDATE ds_jobs_staging
SET location_state = CASE
	WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'Remote' THEN 'Remote'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'United States' THEN NULL
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'Utah' THEN 'UT'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'New Jersey' THEN 'NJ'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'Texas' THEN 'TX'
    WHEN TRIM(SUBSTRING_INDEX(location, ',', 1)) LIKE 'California' THEN 'CA'
    ELSE TRIM(SUBSTRING_INDEX(location, ',', -1))
END;

UPDATE ds_jobs_staging
SET headquarters_city = SUBSTRING_INDEX(headquarters, ',', 1);

UPDATE ds_jobs_staging
SET headquarters_state = TRIM(SUBSTRING_INDEX(headquarters, ',', -1));

-- NOTICED THAT THERE ARE SOME VALUES THAT CONTAINS 061 AS THEIR STATE FOR HEADQUARTERS 
-- KNOWING THAT THE CITY IS NEW YORK I WILL REPLACE ITS VALUE TO 'NY'
-- GOOD THING IS ONLY 2 ROWS ARE OVERLOOKED BUT FIXED IT IMMEDIATELY
UPDATE ds_jobs_staging
SET headquarters_state = 'NY'
WHERE headquarters_state = '061';

SELECT location, location_city, location_state, headquarters, headquarters_city, headquarters_state
FROM ds_jobs_staging;


-- END OF STANDARDIZATION


-- HANDLE NULL/MISSING VALUES
-- I DECIDED TO KEEP NULLS AND JUST FILTER IT IN THE EDA
-- I ALSO BELIEVE THAT REMOVING ROWS WILL MAKE THIS DATASET NOT ACCURATE


-- EXTRACTION OF SKILLS IN JOB DESCRIPTION
-- THIS WILL BE USED FOR INDENTIFYING WHAT SKILLSET IS REQUIRED FOR A JOB POSITION
SELECT
    job_description,
    CASE WHEN job_description LIKE '%Python%' THEN 'Yes' ELSE 'No' END AS python,
    CASE WHEN job_description LIKE '%R studio%' OR job_description LIKE '% R,%' OR job_description LIKE '% R %' THEN 'Yes' ELSE 'No' END AS r_skills,
    CASE WHEN job_description LIKE '%SQL%' THEN 'Yes' ELSE 'No' END AS `sql`,
    CASE WHEN job_description LIKE '%Spark%' THEN 'Yes' ELSE 'No' END AS spark,
    CASE WHEN job_description LIKE '%Hadoop%' THEN 'Yes' ELSE 'No' END AS hadoop,
    CASE WHEN job_description LIKE '%Tableau%' THEN 'Yes' ELSE 'No' END AS tableau,
    CASE WHEN job_description LIKE '%Excel%' THEN 'Yes' ELSE 'No' END AS excel,
    CASE WHEN job_description LIKE '%AWS%' THEN 'Yes' ELSE 'No' END AS aws,
    CASE WHEN job_description LIKE '%Azure%' THEN 'Yes' ELSE 'No' END AS azure,
    CASE WHEN job_description LIKE '%TensorFlow%' THEN 'Yes' ELSE 'No' END AS tensorflow,
    CASE WHEN job_description LIKE '%Keras%' THEN 'Yes' ELSE 'No' END AS keras,
    CASE WHEN job_description LIKE '%PyTorch%' THEN 'Yes' ELSE 'No' END AS pytorch,
    CASE WHEN job_description LIKE '%SAS%' THEN 'Yes' ELSE 'No' END AS sas
FROM ds_jobs_staging;

-- DECIDED TO KEEP THE NEW COLUMNS AS INTEGERS TO MAKE THEM ANALYSIS READY
ALTER TABLE ds_jobs_staging
    ADD COLUMN python INT,
    ADD COLUMN r_skills INT,
    ADD COLUMN sql_skills INT,
    ADD COLUMN spark INT,
    ADD COLUMN hadoop INT,
    ADD COLUMN tableau INT,
    ADD COLUMN excel INT,
    ADD COLUMN aws INT,
    ADD COLUMN azure INT,
    ADD COLUMN tensorflow INT,
    ADD COLUMN keras INT,
    ADD COLUMN pytorch INT,
    ADD COLUMN sas INT;

-- 1 FOR YES
-- 0 FOR NO
UPDATE ds_jobs_staging
SET
	python = CASE WHEN job_description LIKE '%Python%' THEN 1 ELSE 0 END,
    r_skills = CASE WHEN job_description LIKE '%R studio%' OR job_description LIKE '% R,%' OR job_description LIKE '% R %' THEN 1 ELSE 0 END,
    sql_skills = CASE WHEN job_description LIKE '%SQL%' THEN 1 ELSE 0 END,
    spark = CASE WHEN job_description LIKE '%Spark%' THEN 1 ELSE 0 END,
    hadoop = CASE WHEN job_description LIKE '%Hadoop%' THEN 1 ELSE 0 END,
    tableau = CASE WHEN job_description LIKE '%Tableau%' THEN 1 ELSE 0 END,
    excel = CASE WHEN job_description LIKE '%Excel%' THEN 1 ELSE 0 END,
    aws = CASE WHEN job_description LIKE '%AWS%' THEN 1 ELSE 0 END,
    azure = CASE WHEN job_description LIKE '%Azure%' THEN 1 ELSE 0 END,
    tensorflow = CASE WHEN job_description LIKE '%TensorFlow%' THEN 1 ELSE 0 END,
    keras = CASE WHEN job_description LIKE '%Keras%' THEN 1 ELSE 0 END,
    pytorch = CASE WHEN job_description LIKE '%PyTorch%' THEN 1 ELSE 0 END,
    sas = CASE WHEN job_description LIKE '%SAS%' THEN 1 ELSE 0 END;

-- CHECKING OF VALUES
SELECT python, r_skills, sql_skills, spark, hadoop
FROM ds_jobs_staging
LIMIT 5;

-- IDENTIFYING IF THE ROLE IS SENIOR OR NOT
-- SAME LOGIC 1 = YES/0 = NO
ALTER TABLE ds_jobs_staging
ADD COLUMN senior INT;

UPDATE ds_jobs_staging
SET senior = CASE WHEN job_title LIKE '%Senior%' OR job_title LIKE '%Sr%' OR job_title LIKE '%Lead%' OR job_title LIKE '%Principal%' THEN 1 ELSE 0 END;

-- IDENTIFYING IF THE STATE OF THE JOB POSTED IS SAME AS THE STATE OF THE HEADQUARTERS
-- SAME LOGIC 1 = YES/0 = NO
ALTER TABLE ds_jobs_staging
ADD COLUMN same_state INT;

UPDATE ds_jobs_staging
SET same_state = CASE WHEN location_state = headquarters_state THEN 1 ELSE 0 END;

-- REMOVE UNNECESARY COLUMNS
-- REMOVAL OF CLEANED COLUMNS
-- REMOVAL OF JOB DESCRIPTION COLUMN, I DECIDED TO REMOVE IT SINCE I DON'T THINK I WILL PROVIDE ANALYTICAL VALUE SINCE I ALREADY EXTRACTED SKILLS FROM IT
-- I WILL CREATE THE CLEANED TABLE HERE INCLUDING ONLY THE COLUMNS NEEDED AND I CLEANED
CREATE TABLE ds_jobs_cleaned AS
SELECT 
    `index`,
    cleaned_job_title,
    senior,
    min_salary_estimate,
    max_salary_estimate,
    average_salary,
    cleaned_company_name,
    rating,
    location_city,
    location_state,
    headquarters_city,
    headquarters_state,
    same_state,
    `size`,
    founded,
    type_of_ownership,
    industry,
    sector,
    revenue,
    python,
    r_skills,
    sql_skills,
    spark,
    hadoop,
    tableau,
    excel,
    aws,
    azure,
    tensorflow,
    keras,
    pytorch,
    sas
FROM ds_jobs_staging;

DESCRIBE ds_jobs_cleaned;

SELECT *
FROM ds_jobs_cleaned
LIMIT 5;


-- END OF DATA CLEANING 4/26/2026