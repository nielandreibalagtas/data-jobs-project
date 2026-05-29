-- NIEL BALAGTAS EDA ds_jobs 4/26/2026

SELECT *
FROM ds_jobs_cleaned;

-- 1. MOST POPULAR DATA SCIENCE JOB POSTING IN THIS DATASET
-- MOST POPULAR: DATA SCIENTIST WITH 458 POSTINGS
SELECT cleaned_job_title, COUNT(cleaned_job_title) AS number_of_instances
FROM ds_jobs_cleaned
GROUP BY cleaned_job_title
ORDER BY number_of_instances DESC;
-- VERIFICATION THAT THERE ARE NO NULLS
SELECT cleaned_job_title
FROM ds_jobs_cleaned
WHERE cleaned_job_title IS NULL;


-- 2. AVERAGE SALARY OF EACH JOB TITLE
-- HIGHEST AVERAGE SALARY: DATA ARCHITECT WITH 164500 AVERAGE SALARY
SELECT cleaned_job_title, ROUND(AVG(average_salary) * 1000,0) AS average_salary_job_title
FROM ds_jobs_cleaned
GROUP BY cleaned_job_title
ORDER BY average_salary_job_title DESC;


-- 3. COMPANY THAT NEEDED THE MOST POSITIONS
-- MOST POSTINGS: MAXAR TECHNOLOGIES WITH 12 JOB POSTINGS
SELECT cleaned_company_name, COUNT(cleaned_job_title) AS number_of_posting
FROM ds_jobs_cleaned
GROUP BY cleaned_company_name
ORDER BY number_of_posting DESC;
-- FOLLOW UP: COMPANIES WITH HIGH SAME JOB POSTINGS: GROWTH OR RED FLAG
-- WE CAN SEE HERE THAT COMPANIES WITH THE MOST SAME JOB POSTINGS HAS THE BUDGET TO SPEND ON POSITIONS
-- BUT WE CAN ALSO SEE THAT THERE ARE UNKNOWN VALUES WHICH CAN BE A RED FLAG WHEN FINDING A JOB BECAUSE WE DONT KNOW IF
-- THEY CAN SUSTAIN A EMPLOYEE WELL
SELECT cleaned_company_name, COUNT(cleaned_job_title) AS number_of_posting, cleaned_job_title, MAX(revenue) AS max_revenue_recorded
FROM ds_jobs_cleaned
GROUP BY cleaned_company_name, cleaned_job_title
ORDER BY number_of_posting DESC;


-- 4. HIGHEST RATED COMPANIES VS LOWEST RATED COMPANIES COMPARING THEIR ESTIMATED SALARIES
-- THERE ARE 25 COMPANIES THAT ARE RATED AS 5 AND ONLY 1 COMPANY RATED AS 2 (WHICH IS THE LOWEST IN THIS DATASET/ NULL COMES AFTER 2/ THERE IS NO 1 RATING VALUE)
-- EXPLAINING WHY THE AVERAGE SALARY OF LOWEST RATED COMPANIES IS LARGER THAN THE AVERAGE OF HIGHEST RATED COMPANIES
-- RATHER THAN ADJUSTING THE RANGE OF LOWEST RATED I KEPT IT AS IS TO MAINTAIN THE INTEGRITY OF DATA RATHER THAN MANIPULATING IT THAT MIGHT RESULT INTO LYING ABOUT THE INSIGHT OR DATA
WITH highest_rating_companies AS
(
SELECT cleaned_company_name, MAX(rating) AS max_rating_of_companies, AVG(average_salary) AS average_salary_rating
FROM ds_jobs_cleaned
GROUP BY cleaned_company_name
HAVING MAX(rating) = 5
ORDER BY MAX(rating) DESC
), lowest_rating_companies AS
(
SELECT cleaned_company_name, MIN(rating) AS min_rating_of_companies, AVG(average_salary) AS average_salary_rating
FROM ds_jobs_cleaned
GROUP BY cleaned_company_name
HAVING MIN(rating) <= 2 AND MIN(rating) IS NOT NULL
ORDER BY MIN(rating) ASC
)
SELECT 'Average salary of companies with the highest ratings (5)' AS `DESCRIPTION`, ROUND(AVG(average_salary_rating*1000),2) AS average_salary, COUNT(cleaned_company_name) AS number_of_companies
FROM highest_rating_companies
UNION ALL
SELECT 'Average salary of companies with the lowest ratings (2)' AS `DESCRIPTION`, ROUND(AVG(average_salary_rating*1000),2) AS average_salary, COUNT(cleaned_company_name) AS number_of_companies
FROM lowest_rating_companies;


-- 5. HOTSPOT OF JOB POSTING LOCATIONS IN THIS DATASET
-- HOTSPOT: SAN FRANCISCO CA WITH 58 POSTINGS
SELECT location_city, location_state, COUNT(*) AS number_of_posting
FROM ds_jobs_cleaned
WHERE location_city IS NOT NULL AND location_state IS NOT NULL
GROUP BY location_city, location_state
ORDER BY number_of_posting DESC;


-- 6. INTERNATIONAL COMPANIES VS US LOCAL COMPANIES
-- WE CAN SEE THAT US LOCAL COMPANIES HAS MORE JOB POSTINGS RATHER THAN INTERNATIONAL ONES
-- ALTHOUGH WE CAN SEE THAT INTERNATIONAL COMPANIES PAY MORE, IT DOESN'T MEAN THAT INTERNATIONAL IS BETTER
-- THE NUMBER OF JOB POSTINGS CAN AFFECT THE AVERAGE SINCE THERE ARE 596 LOCAL JOB POSTINGS AND ONLY 43 INTERNATIONAL JOB POSTINGS IN THIS DATASET
WITH hq_cte AS
(
SELECT
CASE
	WHEN LENGTH(headquarters_state) = 2 THEN 'US Local Company'
	ELSE 'International Company'
END AS company_category,
(average_salary * 1000) AS full_salary
FROM ds_jobs_cleaned
WHERE headquarters_state IS NOT NULL
)
SELECT company_category, ROUND(AVG(full_salary),2) AS average_salary, COUNT(*) job_postings
FROM hq_cte
GROUP BY company_category;


-- SIZE OF COMPANY, REVENUE AND TYPE OF OWNERSHIP IN RELATION TO SALARIES
-- 7. SIZE
-- BASED ON THE OUTPUT I SEE NO CLEAR PATTERN THAT WILL AFFECT SALARY
-- MEANING SIZE OF A COMPANY DOES NOT STRONGLY INFLUENCE SALARY IN THIS DATASET
SELECT `size`, ROUND(AVG(average_salary*1000),2) AS salary_average, COUNT(*) AS job_postings
FROM ds_jobs_cleaned
WHERE `size` IS NOT NULL AND `size` != 'Unknown'
GROUP BY `size`
ORDER BY CASE `size`
	WHEN '1 to 50 employees' THEN 1
    WHEN '51 to 200 employees' THEN 2
    WHEN '201 to 500 employees' THEN 3
    WHEN '501 to 1000 employees' THEN 4
    WHEN '1001 to 5000 employees' THEN 5
    WHEN '5001 to 10000 employees' THEN 6
    WHEN '10000+ employees' THEN 7
END ASC;

-- 8. REVENUE
-- REVENUE DOES NOT SEEM TO INFLUENCE SALARIES GREATLY
-- ONE OUTLIER COMES OUT WITH ONLY 97816.67 FOR SALARY AVERAGE AND THAT IS THE $50 to $100 million (USD)
-- THERE IS NO WAY TO KNOW WHY IN THIS DATASET SO I'LL BE LEAVING THIS AS IS
SELECT revenue, ROUND(AVG(average_salary*1000),2) AS salary_average, COUNT(*) AS job_postings
FROM ds_jobs_cleaned
WHERE revenue IS NOT NULL AND revenue NOT LIKE '%Unknown%'
GROUP BY revenue
ORDER BY CASE revenue
	WHEN 'Less than $1 million (USD)' THEN 1
    WHEN '$1 to $5 million (USD)' THEN 2
    WHEN '$5 to $10 million (USD)' THEN 3
    WHEN '$10 to $25 million (USD)' THEN 4
    WHEN '$25 to $50 million (USD)' THEN 5
    WHEN '$50 to $100 million (USD)' THEN 6
    WHEN '$100 to $500 million (USD)' THEN 7
    WHEN '$500 million to $1 billion (USD)' THEN 8
    WHEN '$1 to $2 billion (USD)' THEN 9
    WHEN '$2 to $5 billion (USD)' THEN 10
    WHEN '$5 to $10 billion (USD)' THEN 11
    WHEN '$10+ billion (USD)' THEN 12
END ASC;

-- 9. TYPE OF OWNERSHIP
-- TYPE OF OWNERSHIP DOES NOT INFLUENCE SALARY GREATLY ALSO
SELECT type_of_ownership, ROUND(AVG(average_salary*1000),2) AS salary_average, COUNT(*) AS job_postings
FROM ds_jobs_cleaned
WHERE type_of_ownership IS NOT NULL AND type_of_ownership NOT LIKE '%Unknown%'
GROUP BY type_of_ownership
ORDER BY salary_average DESC;


-- 10. DOES THE YEAR OF A COMPANY WAS FOUNDED AFFECTS SALARIES
-- UPON CHECKING THE RESULTS, IT DOES NOT MATTER EVEN COMPANIES THAT ARE ESTABLISHED AT AN OLDER DATE
-- PAYS THEIR EMPLOYEES THE SAME AS NEWER COMPANIES
SELECT DISTINCT founded
FROM ds_jobs_cleaned
ORDER BY founded ASC;

SELECT CASE
	WHEN founded < 1800 THEN 'Below 1800'
    WHEN founded BETWEEN 1800 AND 1899 THEN '1800 - 1899'
    WHEN founded BETWEEN 1900 AND 1999 THEN '1900 - 1999'
    WHEN founded >= 2000 THEN 'Above or equal 2000'
END AS year_bins,
ROUND(AVG(average_salary*1000),2) AS average_salary,
COUNT(*) AS number_of_posting
FROM ds_jobs_cleaned
WHERE founded IS NOT NULL AND founded > 0
GROUP BY year_bins
ORDER BY CASE
	WHEN year_bins = 'Below 1800' THEN 1
	WHEN year_bins = '1800 - 1899' THEN 2
    WHEN year_bins = '1900 - 1999' THEN 3
    WHEN year_bins = 'Above or equal 2000' THEN 4
END ASC;


-- 11. WHICH SECTOR HAS THE HIGHEST DEMAND AND HIGHEST PAYING JOBS
-- WE CAN SEE THAT THE SECTOR THAT HAS THE HIGHEST DEMAND IS INFORMATION TECHNOLOGY
-- AS FOR SALARY THE HIGHEST AVERAGE SALARY COMES FROM AEROSPACE & DEFENCE WHICH HAS 46 JOB LISTINGS WHICH MAKES IT
-- MORE ACCURATE THAN SECTORS WITH LOWER JOB POSTINGS
SELECT sector, COUNT(*) AS number_of_job_postings, ROUND(AVG(average_salary*1000),2) AS average_salary
FROM ds_jobs_cleaned
WHERE sector IS NOT NULL
GROUP BY sector
ORDER BY number_of_job_postings DESC;


-- 12. WHAT TYPE OF COMPANY IS BETTER TO WORK FOR
-- BETTER HERE IS DEFINED AS AVERAGE RATING AND AVERAGE SALARY AND THE HIGHEST RATING WE COULD FIND IS FROM A HOSPITAL WITH ONLY 1 JOB POSTING
-- MEANING THAT THE HOSPITAL RECORD MIGHT NOT BE ACCURATE
-- INSTEAD WE HAVE COMPANY-PRIVATE WITH THE HIGHEST AMOUNT OF JOB POSTINGS WITH AN AVERAGE OF 4 RATING AND 121868.35 AS FOR AVERAGE SALARY
SELECT DISTINCT type_of_ownership
FROM ds_jobs_cleaned;

SELECT type_of_ownership, ROUND(AVG(rating),1) AS avg_rating, ROUND(AVG(average_salary*1000),2) AS average_salary, COUNT(*) AS number_of_posting
FROM ds_jobs_cleaned
WHERE type_of_ownership IS NOT NULL AND type_of_ownership NOT LIKE '%Unknown%'
GROUP BY type_of_ownership
ORDER BY avg_rating DESC;

-- 13. DOES SENIOR ROLES PAY MORE
-- BASED ON THIS DATASET, BEING A SENIOR IN A ROLE HAS NO INCREASE IN SALARY AS WE CAN SEE IN THE AVERAGE SALARIES LISTED
SELECT senior, ROUND(AVG(average_salary*1000),2) AS average_salary, COUNT(*) AS job_postings
FROM ds_jobs_cleaned
GROUP BY senior;

-- 14. DO COMPANIES THAT HIRE IN THE SAME STATE AS THEIR HQ PAYS DIFFERENTLY
-- SAME STATE COMPANIES PAYS A LITTLE LESS THAN COMPANIES WITH DIFFERENT HQ WITH A DIFFERENCE OF $10,206.98 IN THEIR AVERAGE SALARY
SELECT same_state, ROUND(AVG(average_salary*1000),2) AS average_salary, COUNT(*) AS job_postings
FROM ds_jobs_cleaned
GROUP BY same_state;


-- END OF EDA ds_jobs 4/26/2026