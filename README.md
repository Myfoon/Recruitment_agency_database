# Recruitment_agency_database
Implementation physical database model based on presented logical model.

Create a physical database with a separate database and schema and give it an appropriate domain-related name. Use the relational model you've created while studying DB Basics module. Task 2 (designing a logical data model on the chosen topic). Make sure you have made any changes to your model after your mentor's comments.
Your database must be in 3NF
Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
Create relationships between tables using primary and foreign keys.
Apply five check constraints across the tables to restrict certain values, including
date to be inserted, which must be greater than January 1, 2000
inserted measured value that cannot be negative
inserted value that can only be a specific value (as an example of gender)
unique
not null

Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has been set for the existing rows.



