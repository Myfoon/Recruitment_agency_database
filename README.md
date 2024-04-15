# Recruitment_agency_database
## PART 1: Designing a logical data model.
Recruitment Agency manages job listing, candidate registration, application tracking, matches between candidates
and job listening based on criteria like skills, experience, location and preferences, interviews, and placements.
Moreover agency offer additional services like resume writing, interview coaching, and skills development to help
candidates improve their job prospects.

-The model should be in 3rd normal form (3NF).  
-Your model should include 10-15 tables (relations).  
-Your model should include at least one many-to-many relationship (think about how to implement this relationship).  
-All relationships  should be graphically indicated on the diagram  
-Сheck that the visualization of relationship matches the logic  
-The correct data types should be specified.  
-Keys and other constraints should be specified.  
-The names of the tables and columns should be clear (adhere to the coding standards).

## PART 2: Creating a physical database.
You have to implement a physical database based on the logical model presented earlier. This involves creating the necessary database objects, such as tables and indexes, and defining their properties and relationships to reflect the logical model.


1. Create a physical database with a separate database and schema and give it an appropriate domain-related name. Use the relational model you've created while studying DB Basics module. Task 2 (designing a logical data model on the chosen topic). Make sure you have made any changes to your model after your mentor's comments.
2. Your database must be in 3NF
3. Use appropriate data types for each column and apply DEFAULT values, and GENERATED ALWAYS AS columns as required.
4. Create relationships between tables using primary and foreign keys.
5. Apply five check constraints across the tables to restrict certain values, including:

   -date to be inserted, which must be greater than January 1, 2000
   
   -inserted measured value that cannot be negative
   
   -inserted value that can only be a specific value (as an example of gender)
   
   -unique
   
   -not null
7. Populate the tables with the sample data generated, ensuring each table has at least two rows (for a total of 20+ rows in all the tables).
8. Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date, and check to make sure the value has been set for the existing rows.





