# 📊 Data Science Jobs Analysis — SQL & Power BI

A full end-to-end data analysis project using a real-world Glassdoor dataset of data science job postings across the United States. The project covers data importing, cleaning, exploratory data analysis (EDA), and dashboard creation.

---

## 📁 Table of Contents

- [About the Dataset](#about-the-dataset)
- [Project Overview](#project-overview)
- [Project Structure](#project-structure)
- [Data Cleaning](#data-cleaning)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Dashboard](#dashboard)
- [Key Findings](#key-findings)
- [Tools Used](#tools-used)

---

## 📌 About the Dataset

- **Source:** [Kaggle — Data Science Job Posting on Glassdoor](https://www.kaggle.com/datasets/rashikrahmanpritom/data-science-job-posting-on-glassdoor)
- **Description:** Real job postings scraped from Glassdoor representing data science and data-related job listings across the United States.
- **Raw columns include:** `job_title`, `salary_estimate`, `job_description`, `rating`, `company_name`, `location`, `headquarters`, `size`, `founded`, `type_of_ownership`, `industry`, `sector`, `revenue`, `competitors`

---

## 🗺️ Project Overview

The project was completed in three stages:

1. **Data Cleaning** — Fixing, standardizing, and enriching the raw dataset in SQL to make it analysis-ready.
2. **Exploratory Data Analysis (EDA)** — Querying the cleaned dataset to uncover patterns and insights useful for job seekers and recruiters.
3. **Dashboard** — Visualizing the findings in Power BI as an interactive "Data Related Jobs Search Guide."

---

## 🗂️ Project Structure

```
├── import_dataset.sql         # Script to import the raw dataset into MySQL
├── data_cleaning.sql          # Full data cleaning pipeline (staging → cleaned table)
├── EDA.sql                    # All EDA queries with comments and findings
├── DS_Jobs_Documentation.pdf  # Written documentation of the full project
└── README.md
```

> The Power BI `.pbix` dashboard file is referenced in the documentation.

---

## 🧹 Data Cleaning

**File:** `data_cleaning.sql`

Starting from the raw table `ds_jobs_raw`, a staging table `ds_jobs_staging` was created to preserve the original records. The following transformations were applied:

### Duplicate Removal
- Used `ROW_NUMBER()` with `PARTITION BY` across all relevant columns to identify and delete duplicate rows.

### Job Title Standardization
- The original titles were overly specific (e.g., *Analytics Manager - Data Mart*).
- A `CASE` statement with carefully ordered conditions categorized all titles into **10 simplified categories:**
  - Data Architect, Director Role, Vice President Role, Data Modeler, Data Manager, Machine Learning Engineer, Data Engineer, Developer, Data Analyst, Data Scientist

### Salary Estimate Parsing
- Original format: `$137K-$171K (Glassdoor est.)`
- Used nested `SUBSTRING_INDEX()` to extract `min_salary_estimate` and `max_salary_estimate` as integers.
- Computed `average_salary` as the midpoint, rounded to 2 decimal places.
- Note: salary values are in `K` format — multiply by 1000 for full values.

### Company Name Cleaning
- Glassdoor ratings were appended to company names (e.g., *Healthfirst 3.1*).
- Used `REGEXP` to detect trailing numbers and `SUBSTRING_INDEX` + `REPLACE` to strip them.
- Known issue: one company name (`bioMérieux`) has a character encoding error from the import process and was left as-is to maintain data integrity.

### Location & Headquarters Splitting
- Both columns stored city and state together (e.g., `San Francisco, CA`).
- Split into separate `_city` and `_state` columns using `SUBSTRING_INDEX` with a comma delimiter.
- Full state names (e.g., `Utah`, `New Jersey`) were converted to 2-letter abbreviations.
- Values of `United States` were set to `NULL` since no specific city/state could be determined.
- Corrected 2 headquarters records with an erroneous state code of `061` → `NY`.

### Skill Extraction from Job Descriptions
- Used `LIKE` pattern matching to flag 13 skills from the `job_description` column.
- Stored as integers (`1` = required, `0` = not mentioned) for easier aggregation.
- Skills extracted: `python`, `r_skills`, `sql_skills`, `spark`, `hadoop`, `tableau`, `excel`, `aws`, `azure`, `tensorflow`, `keras`, `pytorch`, `sas`

### Engineered Columns
- **`senior`** — flags whether the role is senior-level (`Senior`, `Sr`, `Lead`, `Principal` in job title).
- **`same_state`** — flags whether the job's location state matches the company's headquarters state.

### Final Table
- A clean table `ds_jobs_cleaned` was created, dropping the raw `job_description` column (skills already extracted) and all original uncleaned columns.

---

## 🔍 Exploratory Data Analysis

**File:** `EDA.sql`

All queries were run against `ds_jobs_cleaned`. Key questions answered:

| # | Question |
|---|----------|
| 1 | Most popular data science job posting in this dataset |
| 2 | Average salary per job title |
| 3 | Company with the most job postings |
| 4 | Highest vs. lowest rated companies — salary comparison |
| 5 | Job posting hotspot by city |
| 6 | International vs. US local companies — postings and salary |
| 7 | Company size vs. salary |
| 8 | Company revenue vs. salary |
| 9 | Type of ownership vs. salary |
| 10 | Company founding year vs. salary |
| 11 | Sector with highest demand and highest paying jobs |
| 12 | Best type of company to work for (rating + salary) |
| 13 | Do senior roles pay more? |
| 14 | Do companies hiring outside their HQ state pay differently? |

---

## 📈 Dashboard

Built in **Power BI** with 3 pages, themed as a *Data Related Jobs Search Guide*.

**Page 1 — Salary & Demand Overview**
- Average salary per job title (bar chart)
- Average salary per sector (bar chart)
- Average rating by type of ownership (bar chart)
- Top states with the highest average salary (bar chart)
- Filters: State, Job Title

**Page 2 — Salary vs. Demand Scatter**
- Scatter plot: average salary (Y-axis) vs. job postings (X-axis) per job title
- KPI cards: Most popular job, salary of most popular job, highest salary job, highest salary value
- Filters: State, Job Title

**Page 3 — Skills & Senior Analysis**
- In-demand skills (bar chart — count of job postings requiring each skill)
- Skills required by job position (dot matrix / heatmap)
- Senior vs. non-senior salary comparison per job title (grouped bar chart)
- Filters: State, Job Title, Skill

---

## 💡 Key Findings

- **Most posted role:** Data Scientist (458 postings)
- **Highest average salary:** Data Architect ($164,500)
- **Lowest average salary:** Vice President Role ($101,500)
- **Top hiring company:** Maxar Technologies (12 postings)
- **Job posting hotspot:** San Francisco, CA (58 postings); California leads at the state level (155 postings)
- **Highest average salary by state:** New York ($136,000), followed by Virginia ($127,000)
- **Highest paying sector:** Aerospace & Defense ($132,700 avg, 46 postings)
- **Highest demand sector:** Information Technology
- **Best company type (rating + salary):** Company - Private (4.0 avg rating, $121,868 avg salary)
- **Most in-demand skills:** Python, SQL, Excel
- **Senior roles do NOT consistently pay more** — some roles (e.g., Director Role, Data Scientist) show higher average salaries for non-senior positions
- **Company size, revenue, type of ownership, and founding year show no strong influence on salary**
- **International companies pay slightly more on average**, but the sample size (43 vs. 596 US local postings) makes this less reliable
- **Jobs hiring outside the company's home state pay ~$10,207 more** on average than same-state postings

---

## 🛠️ Tools Used

- **MySQL** — Data importing, cleaning, and EDA
- **Power Query (Power BI)** — Additional data transformation
- **Power BI Desktop** — Dashboard creation and visualization

---

## 👤 Author

**Niel Andrei Balagtas**
- 📧 nielandreibalagtas@gmail.com
- 💼 [LinkedIn](https://www.linkedin.com/in/niel-andrei-balagtas-360442379/)
- 🐙 [GitHub](https://github.com/nielandreibalagtas)

---

*Project by Niel Andrei Balagtas — May 2026*
