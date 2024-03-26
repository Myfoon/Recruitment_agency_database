/*As a step 0 zero before running the script, please create database with following query:
 
CREATE DATABASE IF NOT EXISTS recruitment_agency;

Having database created, please create new connection*/ 
------------------------------------------------------------------------------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS recruitment_data;

/*Here I'd like to say a couple of words about the logical order of following sections. 
  My idea was to create tables in such a sequence that at the moment I need to assign FK in the new table I always have related table already created. 
  I can imagine that in case of real-life big databases such approach may be impossible because of complexity, but in my database I found it 
  more sensible than creating tables in some random order.
  It was a subject of discussion, but finally I decided to organize sections of CREATE-INSERT-ALTER queries for every table. But I think it can be 
  organized differently if needed (for example, we create all the tables and only after it we start populating them)  */

----------------------------------------------------------------------1.RECRUITERS----------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.recruiters (
  recruiter_id serial2 PRIMARY KEY,
  first_name VARCHAR(20) NOT NULL,
  last_name VARCHAR(20) NOT NULL,
  email VARCHAR(60) GENERATED ALWAYS AS (LOWER(first_name)||'.'||LOWER(last_name)||'@virecruitment.com') STORED NOT NULL UNIQUE,
  additional_service_provider BOOL NOT NULL
);

--As far as email is generated from first name and last name and has UNIQUE constraint, there is no need to check uniqueness of combination (first_name, last_name)


INSERT INTO recruitment_data.recruiters (first_name, last_name, additional_service_provider)
VALUES ('Jonas', 'Mekas', TRUE),
       ('Kate', 'Panter', FALSE)
ON CONFLICT DO NOTHING
RETURNING *;

ALTER TABLE recruitment_data.recruiters ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

---------------------------------------------------------------------2.ADDITIONAL_SERVICES----------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.additional_services (
  service_id serial2 PRIMARY KEY,
  service_name VARCHAR(40) NOT NULL UNIQUE,
  description TEXT NOT NULL UNIQUE,
  price INT2 NOT NULL CHECK(price > 0)                       --CHECK for inserted measured value that cannot be negative
);


INSERT INTO recruitment_data.additional_services (service_name, description, price)
VALUES ('Interview coaching', 'Interview preparation coaching provides candidate with constructive'||
                               'feedback and strategies to anticipate and perform well in a job interview', 20),
       ('CV creating', 'Helping candidate to create a job-winning CV', 10)
ON CONFLICT DO NOTHING
RETURNING *;

ALTER TABLE recruitment_data.additional_services ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

---------------------------------------------------------------------3.COUNTRY--------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.country (
  country_id SERIAL2 PRIMARY KEY,
  country VARCHAR(100) NOT NULL UNIQUE
);


INSERT INTO recruitment_data.country (country) 
VALUES ('Lithuania'),
       ('Denmark')
ON CONFLICT DO NOTHING
RETURNING *;

ALTER TABLE recruitment_data.country ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

--------------------------------------------------------------------4.CITY------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.city (
city_id serial4 PRIMARY KEY,
  city VARCHAR(100) NOT NULL,
  country_id INT2 NOT NULL REFERENCES recruitment_data.country      --Many-to-one relationship with table "country"
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_unq_city_city_country_id
ON recruitment_data.city(city, country_id);


INSERT INTO recruitment_data.city (city, country_id)
SELECT 'Kaunas',
(SELECT country_id
 FROM recruitment_data.country 
 WHERE UPPER(country) = 'LITHUANIA')
 
UNION ALL

SELECT 'Copenhagen',
(SELECT country_id 
 FROM recruitment_data.country 
 WHERE UPPER(country) = 'DENMARK')
ON CONFLICT DO NOTHING
RETURNING *;


ALTER TABLE recruitment_data.city ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

--------------------------------------------------------------------5.CANDIDATES--------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.candidates (
  candidate_id serial4 PRIMARY KEY,
  first_name VARCHAR(20) NOT NULL,
  last_name VARCHAR(20) NOT NULL,
  birth_date DATE NOT NULL,
  phone VARCHAR(12) NOT NULL UNIQUE,
  email VARCHAR(60) NOT NULL UNIQUE,
  city_id INT4 NOT NULL REFERENCES recruitment_data.city              --Many-to-one relationship with table "city"
);

/*We can use combination of (first_name, last_name, birth_date) as unique identifier of a candidate:*/

CREATE UNIQUE INDEX IF NOT EXISTS idx_unq_candidates_first_name_last_name_birth_date       
ON recruitment_data.candidates(first_name, last_name, birth_date);

INSERT INTO recruitment_data.candidates (first_name, last_name, birth_date, phone, email, city_id)
SELECT 'Nicolas',
'Cage',
'1964-01-07'::DATE,
'+18412431322',
'nick.cage@gmail.com',
(SELECT city_id 
 FROM recruitment_data.city 
 WHERE UPPER(city) = 'KAUNAS')
 
UNION ALL

SELECT 'Viacheslav',
'Ivanov',
'1991-10-15'::DATE,
'+37062183451',
'mafon.ff@gmail.com',
(SELECT city_id
 FROM recruitment_data.city 
 WHERE UPPER(city) = 'COPENHAGEN')
ON CONFLICT DO NOTHING
RETURNING *;

ALTER TABLE recruitment_data.candidates ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

----------------------------------------------------------------------------6.CANDIDATE_DETAILS---------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.candidate_details (
  candidate_details_id serial4 PRIMARY KEY,
  candidate_id INT4 NOT NULL UNIQUE REFERENCES recruitment_data.candidates,   --One-to-one relationship with table "candidates"
  education VARCHAR(100) NOT NULL,
  skills VARCHAR(200) NOT NULL,
  experience VARCHAR(200)
);

INSERT INTO
	recruitment_data.candidate_details (candidate_id, education, skills, experience)
SELECT
	(SELECT candidate_id
	FROM recruitment_data.candidates
	WHERE UPPER(first_name || ' ' || last_name || ' ' || birth_date) = 'VIACHESLAV IVANOV 1991-10-15'),
	'master of physics',
	'research; MATLAB; radiophysics',
	'research engineer (5 years)'

UNION ALL

SELECT 
    (SELECT candidate_id 
     FROM recruitment_data.candidates 
     WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'NICOLAS CAGE 1964-01-07'),
     'bachelor of computer science',
     'Python; SQL',
     NULL
ON CONFLICT DO NOTHING
RETURNING *;

ALTER TABLE recruitment_data.candidate_details ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

----------------------------------------------------------------------7.CANDIDATE_SERVICE_RECRUITER----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.candidate_service_recruiter (
  service_id INT2 NOT NULL REFERENCES recruitment_data.additional_services,                --Many-to-one relationship with table "additional_services"
  recruiter_id INT2 NOT NULL REFERENCES recruitment_data.recruiters,                       --Many-to-one relationship with table "recruiters"
  candidate_id INT4 NOT NULL REFERENCES recruitment_data.candidates,                        --Many-to-one relationship with table "candidates" 
  PRIMARY KEY (service_id, recruiter_id, candidate_id)
);


INSERT INTO recruitment_data.candidate_service_recruiter (service_id, recruiter_id, candidate_id)
SELECT
(SELECT service_id 
 FROM recruitment_data.additional_services 
 WHERE UPPER(service_name) = 'CV CREATING'),
(SELECT recruiter_id 
 FROM recruitment_data.recruiters 
 WHERE UPPER(first_name||' '||last_name) = 'JONAS MEKAS'),
(SELECT candidate_id 
FROM recruitment_data.candidates 
WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'VIACHESLAV IVANOV 1991-10-15')

UNION ALL

SELECT
(SELECT service_id 
 FROM recruitment_data.additional_services 
 WHERE UPPER(service_name) = 'CV CREATING'),
(SELECT recruiter_id 
 FROM recruitment_data.recruiters 
 WHERE UPPER(first_name||' '||last_name) = 'JONAS MEKAS'),
(SELECT candidate_id 
 FROM recruitment_data.candidates 
 WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'NICOLAS CAGE 1964-01-07')
ON CONFLICT DO NOTHING
RETURNING *;

ALTER TABLE recruitment_data.candidate_service_recruiter ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

-----------------------------------------------------------------------8.COMPANIES---------------------------------------------------------------------- 

CREATE TABLE IF NOT EXISTS recruitment_data.companies (
  company_id SERIAL4 PRIMARY KEY,
  company_name VARCHAR(200) NOT NULL UNIQUE
);

INSERT INTO recruitment_data.companies (company_name)
VALUES('EPAM'),
      ('SEB')
ON CONFLICT DO NOTHING      
RETURNING *;

ALTER TABLE recruitment_data.companies ADD COLUMN IF NOT EXISTS  record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

-----------------------------------------------------------------------9.SENIORITY_LEVEL----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.seniority_level (
  job_seniority_id SERIAL2 PRIMARY KEY,
  seniority_level VARCHAR(20) NOT NULL UNIQUE CHECK (seniority_level IN ('junior', 'middle', 'senior', 'intern'))       --CHECK of inserted value that can only be a specific value
);

INSERT INTO recruitment_data.seniority_level (seniority_level)
VALUES('junior'),
      ('middle')
ON CONFLICT DO NOTHING      
RETURNING *;

ALTER TABLE recruitment_data.seniority_level ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

------------------------------------------------------------------------10.JOB_CATEGORY-----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.job_category (
  job_category_id SERIAL2 PRIMARY KEY,
  job_category_name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO recruitment_data.job_category (job_category_name)
VALUES('Information technology'),
      ('Finance/banking')
ON CONFLICT DO NOTHING      
RETURNING *;

ALTER TABLE recruitment_data.job_category ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

------------------------------------------------------------------------11.APPLICATION_STATUS----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.application_status (
  application_status_id SERIAL2 PRIMARY KEY,
  status_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO recruitment_data.application_status (status_name)
VALUES('received'),
      ('offer was sent')
ON CONFLICT DO NOTHING      
RETURNING *;

ALTER TABLE recruitment_data.application_status ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

------------------------------------------------------------------------12.JOBS--------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.jobs (
  job_id SERIAL4 PRIMARY KEY,
  company_id INT4 NOT NULL REFERENCES recruitment_data.companies,                --Many-to-one relationship with table "companies"
  recruiter_id INT2 NOT NULL REFERENCES recruitment_data.recruiters,             --Many-to-one relationship with table "recruiters"
  job_category_id INT2 NOT NULL REFERENCES recruitment_data.job_category,        --Many-to-one relationship with table "job_category"
  job_name VARCHAR(200) NOT NULL,
  job_seniority_id INT2 NOT NULL REFERENCES recruitment_data.seniority_level,    --Many-to-one relationship with table "seniority_level" 
  valid_from DATE NOT NULL CHECK (valid_from > '2000-01-01'),                    --CHECK of date to be inserted, which must be greater than January 1, 2000
  valid_till DATE NOT NULL CHECK (valid_till > valid_from),
  city_id INT4 NOT NULL REFERENCES recruitment_data.city                          --Many-to-one relationship with table "city"
);

--My idea is that we can use combination (company_id, job_name, job_seniority_id) as a unique identifier of a job:
 
CREATE UNIQUE INDEX IF NOT EXISTS idx_unq_jobs_company_id_job_name_job_seniority_id
ON recruitment_data.jobs(company_id, job_name, job_seniority_id);

INSERT INTO recruitment_data.jobs(company_id, recruiter_id, job_category_id, job_name, job_seniority_id, valid_from, valid_till, city_id)
SELECT
(SELECT company_id 
 FROM recruitment_data.companies 
 WHERE UPPER(company_name) = 'EPAM'),
(SELECT recruiter_id 
 FROM recruitment_data.recruiters 
 WHERE UPPER(first_name||' '||last_name) = 'JONAS MEKAS'),
(SELECT job_category_id 
 FROM recruitment_data.job_category 
 WHERE UPPER(job_category_name) = 'INFORMATION TECHNOLOGY'),
'data analyst',
(SELECT job_seniority_id 
 FROM recruitment_data.seniority_level 
 WHERE UPPER(seniority_level) = 'MIDDLE'),
'2024-03-26'::DATE,
'2024-04-26'::DATE,
(SELECT city_id 
 FROM recruitment_data.city 
 WHERE UPPER(city) = 'KAUNAS')
 
UNION ALL

SELECT
(SELECT company_id 
 FROM recruitment_data.companies 
 WHERE UPPER(company_name) = 'SEB'),
(SELECT recruiter_id 
 FROM recruitment_data.recruiters 
 WHERE UPPER(first_name||' '||last_name) = 'KATE PANTER'),
(SELECT job_category_id
 FROM recruitment_data.job_category
 WHERE UPPER(job_category_name) = 'FINANCE/BANKING'),
'financial analyst',
(SELECT job_seniority_id
 FROM recruitment_data.seniority_level 
 WHERE UPPER(seniority_level) = 'JUNIOR'),
'2024-03-28'::DATE,
'2024-04-16'::DATE,
(SELECT city_id 
 FROM recruitment_data.city 
 WHERE UPPER(city) = 'COPENHAGEN')
ON CONFLICT DO NOTHING      
RETURNING *;

ALTER TABLE recruitment_data.jobs ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

------------------------------------------------------------------------13.JOB_DETAILS-----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.job_details (
  job_details_id SERIAL4 PRIMARY KEY,
  job_id INT4 NOT NULL UNIQUE REFERENCES recruitment_data.jobs,         --One-to-one relationship with table "jobs"
  description TEXT NOT NULL,
  requirements TEXT NOT NULL,
  compensation VARCHAR(20) NOT NULL
);


/*I decided to start using CTEs here, because otherwise SELECT expressions in INSERT become really big. 
 As I previously mentioned in previous JOBS section, set of (company_id, job_name, job_seniority_id) is enough to unambiguously define the job  */

WITH job_id_for_EPAM_MIDDLE_DATA_ANALYST AS                                      --Getting job_id for EPAM middle data analyst
(
SELECT job_id 
FROM recruitment_data.jobs 
WHERE company_id = (SELECT company_id 
                    FROM recruitment_data.companies
                    WHERE UPPER(company_name) = 'EPAM')
AND UPPER(job_name) = 'DATA ANALYST' 
AND recruitment_data.jobs.job_seniority_id  = (SELECT job_seniority_id 
                                               FROM recruitment_data.seniority_level 
                                               WHERE UPPER(seniority_level) = 'MIDDLE')
),

job_id_for_SEB_JUNIOR_FINANCIAL_ANALYST AS                                         --Getting job_id for SEB junior financial analyst
(
SELECT job_id 
FROM recruitment_data.jobs 
WHERE company_id = (SELECT company_id 
                    FROM recruitment_data.companies
                    WHERE UPPER(company_name) = 'SEB')
AND UPPER(job_name) = 'FINANCIAL ANALYST' 
AND recruitment_data.jobs.job_seniority_id  = (SELECT job_seniority_id 
                                               FROM recruitment_data.seniority_level 
                                               WHERE UPPER(seniority_level) = 'JUNIOR')
)

INSERT INTO recruitment_data.job_details (job_id, description, requirements, compensation)
SELECT
(SELECT job_id 
 FROM job_id_for_EPAM_MIDDLE_DATA_ANALYST),
'You will work in the best company with the best people! You will: prepare A/B test designs, as well as their monitoring and analysis;'||
'model and forecast key metrics, as well as the results of planned events; develop analytical dashboard',
'25+ years of experience; PhD in data science',
'800-1100'

UNION ALL

SELECT
(SELECT job_id 
 FROM job_id_for_SEB_JUNIOR_FINANCIAL_ANALYST),
'Decent job for decent money',
'1-2 years of experience, bachelor of economics',
'500-600'    
ON CONFLICT DO NOTHING      
RETURNING *;

ALTER TABLE recruitment_data.job_details ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

------------------------------------------------------------------------14.APPLICATIONS-----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.applications (
  application_id SERIAL4 PRIMARY KEY,
  candidate_id INT4 NOT NULL REFERENCES recruitment_data.candidates,                    --Many-to-one relationship with table "candidates"
  job_id INT4 NOT NULL REFERENCES recruitment_data.jobs,                                --Many-to-one relationship with table "jobs"
  application_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  application_status INT2 NOT NULL REFERENCES recruitment_data.application_status       --Many-to-one relationship with table "application_status"
);

--I think we can use combination (candidate_id, job_id) as a unique identifier of an application (one person can have only one application for certain job):
 
CREATE UNIQUE INDEX IF NOT EXISTS idx_unq_applications_candidate_id_job_id
ON recruitment_data.applications(candidate_id, job_id);

WITH job_id_for_EPAM_MIDDLE_DATA_ANALYST AS                  --Here I use the same CTEs from previous section JOB_DETAILS
(
SELECT job_id 
FROM recruitment_data.jobs 
WHERE company_id = (SELECT company_id 
                    FROM recruitment_data.companies
                    WHERE UPPER(company_name) = 'EPAM')
AND UPPER(job_name) = 'DATA ANALYST' 
AND recruitment_data.jobs.job_seniority_id  = (SELECT job_seniority_id 
                                               FROM recruitment_data.seniority_level 
                                               WHERE UPPER(seniority_level) = 'MIDDLE')
),

job_id_for_SEB_JUNIOR_FINANCIAL_ANALYST AS
(
SELECT job_id 
FROM recruitment_data.jobs 
WHERE company_id = (SELECT company_id 
                    FROM recruitment_data.companies
                    WHERE UPPER(company_name) = 'SEB')
AND UPPER(job_name) = 'FINANCIAL ANALYST' 
AND recruitment_data.jobs.job_seniority_id  = (SELECT job_seniority_id 
                                               FROM recruitment_data.seniority_level 
                                               WHERE UPPER(seniority_level) = 'JUNIOR')
)

INSERT INTO recruitment_data.applications (candidate_id, job_id, application_status)
SELECT
(SELECT candidate_id 
 FROM recruitment_data.candidates 
 WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'VIACHESLAV IVANOV 1991-10-15'),
(SELECT job_id 
 FROM job_id_for_SEB_JUNIOR_FINANCIAL_ANALYST),
(SELECT application_status_id 
 FROM recruitment_data.application_status 
 WHERE UPPER(status_name) = 'RECEIVED')
 
UNION ALL 

SELECT
(SELECT candidate_id 
 FROM recruitment_data.candidates 
 WHERE UPPER(first_name||' '||last_name||' '||birth_date) = 'NICOLAS CAGE 1964-01-07'),
(SELECT job_id 
 FROM job_id_for_EPAM_MIDDLE_DATA_ANALYST),
(SELECT application_status_id 
 FROM recruitment_data.application_status 
 WHERE UPPER(status_name) = 'OFFER WAS SENT')
ON CONFLICT DO NOTHING      
RETURNING *;

ALTER TABLE recruitment_data.applications ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

------------------------------------------------------------------------15.INTERVIEWS-----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.interviews (
  interview_id SERIAL4 PRIMARY KEY,
  recruiter_id INT4 NOT NULL REFERENCES recruitment_data.recruiters,               --Many-to-one relationship with table "recruiters"
  application_id INT4 NOT NULL UNIQUE REFERENCES recruitment_data.applications,    --One-to-one relationship with table "applications"
  interview_date DATE NOT NULL, 
  results TEXT NOT NULL
);

--We cannot have more than one interview corresponding certain application on one day:

CREATE UNIQUE INDEX IF NOT EXISTS idx_unq_interviews_application_id_interview_date
ON recruitment_data.interviews(application_id, interview_date);

/*In this and in following sections I decided to use JOINs in my CTE. Maybe it comes a little bit better in terms of readability*/

WITH recruiters_jobs_applications_companies_candidates_seniority_level AS (         --Just joining tables: recruiters_jobs, applications, companies, candidates, seniority_level
SELECT a.application_id AS application_id,
       r.recruiter_id AS recruiter_id,
       r.first_name AS recruiter_first_name,
       r.last_name AS recruiter_last_name,
       job_name,
       company_name,
       seniority_level,
       ca.first_name AS candidate_first_name,
       ca.last_name AS candidate_last_name,
       birth_date AS candidate_birth_date
FROM recruitment_data.recruiters r
JOIN recruitment_data.jobs j ON
r.recruiter_id = j.recruiter_id  
JOIN recruitment_data.applications a ON
a.job_id = j.job_id
JOIN recruitment_data.companies co ON
co.company_id = j.company_id
JOIN recruitment_data.candidates ca ON
ca.candidate_id = a.candidate_id
JOIN recruitment_data.seniority_level s ON
s.job_seniority_id = j.job_seniority_id 
)

INSERT INTO recruitment_data.interviews (recruiter_id, application_id, interview_date, results)
SELECT recruiter_id, 
       application_id,
       '2024-04-02'::DATE,
       'Technical interview assigned'
FROM recruiters_jobs_applications_companies_candidates_seniority_level 
WHERE UPPER(recruiter_first_name||' '||recruiter_last_name) = 'KATE PANTER'    /*As far as I have all the necessary information in my CTE, 
                                                                                 I can use filtering to get right recruiter_id and application_id*/
AND UPPER(job_name) = 'FINANCIAL ANALYST'
AND UPPER(company_name) = 'SEB'
AND UPPER(seniority_level) = 'JUNIOR'
AND UPPER(candidate_first_name||' '||candidate_last_name||' '||candidate_birth_date) = 'VIACHESLAV IVANOV 1991-10-15'

UNION ALL

SELECT recruiter_id,
       application_id,
       '2024-03-29'::DATE,
       'We can proceed with job offer, but have to propose the lowest possible salary for first 6 months due to candidate''s lack of experience in Power BI'
FROM recruiters_jobs_applications_companies_candidates_seniority_level 
WHERE UPPER(recruiter_first_name||' '||recruiter_last_name) = 'JONAS MEKAS'
AND UPPER(job_name) = 'DATA ANALYST'
AND UPPER(company_name) = 'EPAM'
AND UPPER(seniority_level) = 'MIDDLE'
AND UPPER(candidate_first_name||' '||candidate_last_name||' '||candidate_birth_date) = 'NICOLAS CAGE 1964-01-07'
ON CONFLICT DO NOTHING 
RETURNING *;

ALTER TABLE recruitment_data.interviews ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

------------------------------------------------------------------------16.OFFERS-----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS recruitment_data.offers (
  offer_id SERIAL4 PRIMARY KEY,
  interview_id INT4 NOT NULL UNIQUE REFERENCES recruitment_data.interviews,              --One-to-one relationship with table "interviews"
  final_compensation INT2 NOT NULL CHECK (final_compensation > 500),                     --Let's say we have some official minimum wage                                
  description TEXT NOT NULL,
  valid_till DATE NOT NULL
);

WITH recruiters_jobs_applications_companies_candidates_seniority_level AS (               --I use CTE from the previous section INTERVIEWS
SELECT a.application_id AS application_id,
       r.recruiter_id AS recruiter_id,
       r.first_name AS recruiter_first_name,
       r.last_name AS recruiter_last_name,
       job_name,
       company_name,
       seniority_level,
       ca.first_name AS candidate_first_name,
       ca.last_name AS candidate_last_name,
       birth_date AS candidate_birth_date
FROM recruitment_data.recruiters r
JOIN recruitment_data.jobs j ON
r.recruiter_id = j.recruiter_id  
JOIN recruitment_data.applications a ON
a.job_id = j.job_id
JOIN recruitment_data.companies co ON
co.company_id = j.company_id
JOIN recruitment_data.candidates ca ON
ca.candidate_id = a.candidate_id
JOIN recruitment_data.seniority_level s ON
s.job_seniority_id = j.job_seniority_id 
)

/*I decided to insert only one row here to demonstrate that not every interview gets its offer*/

INSERT INTO recruitment_data.offers (interview_id, final_compensation, description, valid_till)
SELECT interview_id, 
       800,
      'EPAM is offering a full-time position for you as data analyst. Your responsibilities will be: analyzing data;'|| 
      'creating dashboards; etc. As part of your compensation, we''re also offering health insurance and 10 extra days-off.',
      '2024-04-10'::DATE
FROM recruitment_data.interviews i
JOIN recruiters_jobs_applications_companies_candidates_seniority_level ON                           --As far as I need to get interview_id here, I add one more join to the CTE from previous section
recruiters_jobs_applications_companies_candidates_seniority_level.application_id = i.application_id
WHERE UPPER(recruiter_first_name||' '||recruiter_last_name) = 'JONAS MEKAS'
AND UPPER(job_name) = 'DATA ANALYST'
AND UPPER(company_name) = 'EPAM'
AND UPPER(seniority_level) = 'MIDDLE'
AND UPPER(candidate_first_name||' '||candidate_last_name||' '||candidate_birth_date) = 'NICOLAS CAGE 1964-01-07'
ON CONFLICT DO NOTHING  
RETURNING *;

ALTER TABLE recruitment_data.offers ADD COLUMN IF NOT EXISTS record_ts DATE DEFAULT CURRENT_DATE NOT NULL;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--This is how I decided to implement check to make sure the value of new column 'record_ts' has been set for the existing rows for every table. 
SELECT record_ts FROM recruitment_data.recruiters
UNION ALL
SELECT record_ts FROM recruitment_data.additional_services 
UNION ALL
SELECT record_ts FROM recruitment_data.country
UNION ALL
SELECT record_ts FROM recruitment_data.city
UNION ALL
SELECT record_ts FROM recruitment_data.candidates
UNION ALL
SELECT record_ts FROM recruitment_data.candidate_details
UNION ALL
SELECT record_ts FROM recruitment_data.candidate_service_recruiter
UNION ALL
SELECT record_ts FROM recruitment_data.companies
UNION ALL
SELECT record_ts FROM recruitment_data.seniority_level
UNION ALL
SELECT record_ts FROM recruitment_data.job_category
UNION ALL
SELECT record_ts FROM recruitment_data.application_status
UNION ALL
SELECT record_ts FROM recruitment_data.jobs
UNION ALL
SELECT record_ts FROM recruitment_data.job_details
UNION ALL
SELECT record_ts FROM recruitment_data.applications
UNION ALL
SELECT record_ts FROM recruitment_data.interviews
UNION ALL
SELECT record_ts FROM recruitment_data.offers;


