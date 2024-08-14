A working MDM Solution that is built purely using SQL on Postgresql database. Hope it helps!

Who is [Bazil Ahmed](https://www.linkedin.com/in/bazil-ahmed)? _(right-click and open in a new tab)_

## Data Model Summary for MDM Solution
The Master Data Management (MDM) solution is built around a logical data model that integrates key entities such as customers, sales transactions, products, and suppliers. This mock data has been generated to serve the purpose of building a real-world MDM solution.  

The ER diagram visually represents the relationships between these entities, showing how they interact to support the MDM processes. 

![image](https://github.com/user-attachments/assets/a4138bc6-c3ea-4c76-bc1e-72d85781b06b)

Note: The solution focuses on the customer and sales tables for simplicity, so you'll notice the code is tailored specifically to these tables.

## Data Flow and MDM Process Description

The Master Data Management (MDM) process for the Orders system is designed to cleanse, match, and consolidate customer and sales data to ensure a single, accurate view of customer information. The process is broken down into several key steps, each supported by specific stored procedures and data flows, as depicted in the flowchart.

![image](https://github.com/user-attachments/assets/d085202e-db06-4ace-804d-01c5fc6feafd)


### 1. Data Import and Initial Cleansing
- **Staging Tables**: Data is initially loaded into staging tables (`stg_customer`, `stg_product`, `stg_sales`, `stg_supplier`) using the database’s native import functionality.
- **Cleansing Process**: The `cleanse_and_load_table` stored procedure is invoked to clean the data in the staging tables. This procedure removes unnecessary spaces, standardizes formats, and prepares the data for further processing. Cleansed data is then loaded into the corresponding production tables (`customer`, `product`, `sales`, `supplier`) with the `mdm_complete` flag set to `FALSE`.

### 2. Matching Process
- **Finding Potential Matches**: The `find_potential_matches_customer` stored procedure is executed to identify potential duplicate customer records. This process uses predefined matching rules, including exact matches and fuzzy matches, and stores the results in the `potential_matches_customer` table.
- **Manual Review and Exclusion**: The `potential_matches_customer_vw` view provides a user-friendly interface for reviewing potential matches. If certain records are found to be incorrect matches, the `flag_to_be_merged_false` procedure can be used to flag them as `to_be_merged = FALSE`, excluding them from the merging process.

### 3. Merging Process
- **Applying Survivorship Rules**: The `run_survivorship_for_all` stored procedure iterates through all identified matches, applying survivorship rules via the `apply_survivorship_rules` procedure. These rules determine the "golden" customer record, which is then stored in the `customer_master` table.
- **Finalizing Records**: The procedure also inserts any unmatched customer records directly into the `customer_master` table and updates the `mdm_complete` flag in the `customer` table to `TRUE` for all processed records.

### 4. Post-MDM Sales Data Integration
- **Sales Data Update**: The `populate_sales_post_mdm` stored procedure is executed to update the `sales_post_mdm` table. This procedure links the sales data to the correct customer records using the `customer_master` table. The `mdm_complete` flag in the `sales` table is then set to `TRUE` for all processed records, ensuring that they are not reprocessed in future MDM runs.

---

The MDM process for the Orders system involves a systematic approach to cleansing, matching, merging, and integrating customer and sales data. The flowchart provides a clear visual representation of how data moves through the system, from initial import to final consolidation in the master records. Each stored procedure plays a critical role in ensuring data accuracy and consistency, resulting in a unified and reliable view of customer information across the organization.


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

### Steps

Prerequisite: Postgresql database is installed and the server is running locally. [Download and installation details](https://www.postgresql.org/download/) _(right-click and open in a new tab)_

I faced a server issue on my Mac (ARM version) and this [post](https://stackoverflow.com/questions/39710384/cannot-connect-to-postgres-server-running-through-brew-services) _(right-click and open in a new tab)_ helped me fix it.

**Step 0:** Connect to this locally running Postgres server using any Database Management Tool of your choice. Create a database `mdm_demo` and connect to it. 

**Step 1:** Run all SQL scripts in sequence

**Step 2:** Import mock data from ./Data folder into respective staging tables using database native import feature

**Step 3:** Run `cleanse_and_load_table` stored proc for `stg_customer` and `stg_sales` tables

**Step 4:** Run `find_potential_matches_customer` stored proc 

**Step 5:** View results from `potential_matces_customer_vw` for manual review

**Step 6:** Run `flag_to_be_merged_false` stored proc for specific records that you do not want to be merged

**Step 7:** Run `run_survivorship_for_all` stored proc

**Step 8:** Review updated `customer_master` table

**Step 9:** Run `populate_sales_post_mdm` stored proc

**Step 10:** Review results in `sales_post_mdm` table

**Step 11 (Optional)**: You can manually insert new records into `stg_customer` and `stg_sales` tables and repeat all the steps to see how the MDM process works with delta load.

---

### SQL Scripts Description

This project contains several SQL scripts designed to set up and manage the Master Data Management (MDM) process. Below is a summary of each script:

---

**1. `01_create_tables_and_views.sql`**

**Purpose:**  
This script is responsible for setting up the initial database schema, including the creation of all necessary tables and views for the project. Run this script first to ensure that all required database objects are created before executing any stored procedures. There are special considerations to accommodate delta load logics and the cyclic nature of the MDM process. For example, almost all tables have `created_date` and `updated_date` columns, which are used for delta load logic. Boolean flag columns like `mdm_complete` and `to_be_merged` are added to address special scenarios and edge cases. Although only the `customer` and `sales` tables are used to implement the MDM process, this script serves as an example for implementing similar logic for `product` and `supplier` tables.

**Contents:**  
- Creates tables: `stg_customer`, `stg_product`, `stg_supplier`, `stg_sales`, `customer`, `product`, `supplier`, `sales`, `potential_matches_customer`, `customer_master`, `sales_post_mdm`.
- Defines view `potential_matches_customer_vw` to facilitate the MDM process.

---

**2. `02_create_sp_cleanse_and_load_table.sql`**

**Purpose:**  
This script creates a stored procedure that cleanses data in staging tables and loads it into the target tables. The procedure ensures data consistency by removing unnecessary spaces and new lines and replacing blank values with `NULL` values. This serves as a placeholder where additional rules for cleansing and standardization can be added.

**Contents:**  
- Creates the `cleanse_and_load_table` stored procedure.
- The procedure accepts staging and target table names as parameters and performs data cleansing operations before inserting the cleansed data into the target table. It also sets the default value of `mdm_complete` to `FALSE` for each entry into the cleansed table. The table names should be provided without the schema, as the schema is already added to the stored procedure.  
  **Example:** `CALL cleanse_and_load_table('stg_customer', 'customer');`

---

**3. `03_create_sp_find_potential_matches_customer.sql`**

**Purpose:**  
This script creates a stored procedure that identifies potential matching customer records based on predefined matching rules. Only four rules have been defined in this procedure for simplicity. Additional rules can be added in a similar fashion. The results are stored in the `potential_matches_customer` table, which serves as a cross-reference and historical record as new entries are added each cycle.

**Contents:**  
- Creates the `find_potential_matches_customer` stored procedure.
- Implements several matching rules (e.g., exact matches, as well as fuzzy matches) to find duplicate or similar records in the customer data. While only the `customer` table is used as an entity table in this MDM process, the same logic can be applied to the `supplier` and `product` tables.  
  **Example:** `CALL find_potential_matches_customer();`

---

**4. `04_create_sp_flag_to_be_merged_false.sql`**

**Purpose:**  
This script creates a stored procedure that flags specific records in the `potential_matches_customer` table as `to_be_merged = FALSE`, effectively excluding them from the merging process. The default value for each entry in the `potential_matches_customer` table is set to `TRUE` for execution speed. However, this stored procedure can be called to deselect certain records that are not a good match based on manual review. This manual review is performed using the `potential_matches_customer_vw` view, which is designed to enhance readability and assist in manual intervention on incorrect matches.

**Contents:**  
- Creates the `flag_to_be_merged_false` stored procedure.
- The procedure accepts `reference_id`, `matched_id`, and `rule_number` as parameters and updates the `to_be_merged` flag accordingly.  
  **Example:** `CALL flag_to_be_merged_false(15, 102, 3);`

---

**5. `05_create_sp_apply_survivorship_rules.sql`**

**Purpose:**  
This script creates a stored procedure that applies survivorship rules to determine the "golden" customer record when merging matching records. The survivorship rules have been carefully designed for each attribute to mimic real-world scenarios. The final record is stored in the `customer_master` table after being enriched with matching records. This procedure currently covers only the `customer` entity.  
  **Example:** `CALL apply_survivorship_rules(15);`

**Contents:**  
- Creates the `apply_survivorship_rules` stored procedure.
- The procedure evaluates potential duplicate records, applies predefined rules, and updates or inserts the final "golden" record into the `customer_master` table.

---

**6. `06_create_sp_run_survivorship_for_all.sql`**

**Purpose:**  
This script creates a stored procedure that iterates through all identified matching records and applies the survivorship rules to merge them. Additionally, it inserts remaining customer records that don't have any potential matches into the `customer_master` table, ensuring that all records—both merged and unmerged—are included. It also updates the `mdm_complete = TRUE` flag for all customer records in the `customer` table, preventing them from being reprocessed in subsequent MDM runs.

**Contents:**  
- Creates the `run_survivorship_for_all` stored procedure.
- The procedure loops through all distinct `reference_id` values, calls the `apply_survivorship_rules` procedure for each one, and then updates the `mdm_complete` flag.  
  **Usage:** Execute this procedure to perform a full MDM cycle, applying survivorship rules across all potential duplicates.

---

**7. `07_create_sp_populate_sales_post_mdm.sql`**

**Purpose:**  
This script creates a stored procedure that populates or updates the `sales_post_mdm` table by linking sales data to the correct customer records after the MDM process. It also updates the `mdm_complete` flag in the `sales` table. Initially, only the `customer` table was processed as an entity. This stored procedure ensures that the transaction tables reflect the changes and use the enriched master data by updating the `sales_post_mdm` table with correct references to the master customer data.  
  **Example:** `CALL populate_sales_post_mdm();`

**Contents:**  
- Creates the `populate_sales_post_mdm` stored procedure.
- The procedure inserts or updates records in the `sales_post_mdm` table and marks the corresponding sales records as complete by setting the `mdm_complete` flag to `TRUE`.

