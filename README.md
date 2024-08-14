MDM Solution that is built on purely SQL on Postgresql database. Enjoy a working solution!



## SQL Scripts Overview

This project contains several SQL scripts to set up and manage the Master Data Management (MDM) process. Below is a summary of each script:

1. **01_create_tables_and_views.sql**: Creates all necessary tables and views for the MDM project.
2. **02_create_sp_cleanse_and_load_table.sql**: Defines a stored procedure to cleanse and load data from staging tables into production tables.
3. **03_create_sp_find_potential_matches_customer.sql**: Implements a stored procedure to identify potential matches of customer records based on defined matching rules. 
4. **04_create_sp_flag_to_be_merged_false.sql**: Provides a stored procedure to flag records as not to be merged in the MDM process using manual review and approval/rejection. 
5. **05_create_sp_apply_survivorship_rules.sql**: Defines a stored procedure to apply survivorship rules and generate the "golden" customer record.
6. **06_create_sp_run_survivorship_for_all.sql**: Creates a stored procedure to run survivorship rules across all potential matches in customer table.
7. **07_create_sp_populate_sales_post_mdm.sql**: Implements a stored procedure to populate and update the `sales_post_mdm` table, linking sales data to master customer records.

### Execution Order

It is recommended to execute the scripts in the following order:
1. `01_create_tables_and_views.sql`
2. `02_create_sp_cleanse_and_load_table.sql`
3. `03_create_sp_find_potential_matches_customer.sql`
4. `04_create_sp_flag_to_be_merged_false.sql`
5. `05_create_sp_apply_survivorship_rules.sql`
6. `06_create_sp_run_survivorship_for_all.sql`
7. `07_create_sp_populate_sales_post_mdm.sql`

Ensure that the database schema is properly set up by running the first script before executing the stored procedures.
