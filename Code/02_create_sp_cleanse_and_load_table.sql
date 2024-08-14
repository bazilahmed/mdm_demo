CREATE OR REPLACE PROCEDURE orders.cleanse_and_load_table(stg_table_name text, target_table_name text)
LANGUAGE plpgsql
AS $$
DECLARE
    col_name text;
    col_type text;
    query text;
BEGIN
--     Step 1: Create the target table if it does not exist
--    EXECUTE format(
--        'CREATE TABLE IF NOT EXISTS %I (LIKE %I INCLUDING ALL)',
--        target_table_name, stg_table_name
--    );
--
--     Step 2: Add the mdm_complete column if it does not exist
--    EXECUTE format(
--        'ALTER TABLE %I ADD COLUMN IF NOT EXISTS mdm_complete BOOLEAN DEFAULT FALSE',
--        target_table_name
--    );

    -- Step 3: Cleanse the data in the staging table
    FOR col_name, col_type IN
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = stg_table_name
        AND data_type IN ('character varying', 'varchar', 'text', 'char')
    LOOP
        -- Build the update query to cleanse the data
        query := format(
            'UPDATE orders.%I SET %I = NULLIF(
                    regexp_replace(
                        trim(%I),
                        E''[\\s\\t\\r\\n]+'',  -- Replace multiple spaces, tabs, carriage returns, and newlines with a single space
                        '' '', 
                        ''g''), '''')',  -- Replace blanks with NULL
            stg_table_name, col_name, col_name
        );

        -- Execute the update query
        EXECUTE query;
    END LOOP;

    -- Step 4: Insert cleansed data into the target table based on created_date and updated_date
    EXECUTE format(
        'INSERT INTO orders.%I
         SELECT *
         FROM orders.%I
         WHERE created_date > (SELECT COALESCE(MAX(created_date), ''1900-01-01'') FROM orders.%I)
         OR updated_date > (SELECT COALESCE(MAX(updated_date), ''1900-01-01'') FROM orders.%I)',
        target_table_name, stg_table_name, target_table_name, target_table_name
    );

    RAISE NOTICE 'Cleansing and loading completed for table: %', target_table_name;
END;
$$;
