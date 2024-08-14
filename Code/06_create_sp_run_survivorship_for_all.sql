--Stored procedure that will loop through all distinct reference_id values and apply the apply_survivorship_rules procedure for each one
CREATE OR REPLACE PROCEDURE orders.run_survivorship_for_all()
LANGUAGE plpgsql
AS $$
DECLARE
    ref_id int;
BEGIN
    -- Step 1: Loop through all distinct reference_id values in the potential_matches_customer_vw view
    FOR ref_id IN
        SELECT DISTINCT reference_id
        FROM orders.potential_matches_customer_vw
    LOOP
        -- Call the apply_survivorship_rules procedure for each reference_id
        BEGIN
            CALL orders.apply_survivorship_rules(ref_id);
        EXCEPTION
            WHEN OTHERS THEN
                -- Handle any exceptions that occur during the procedure execution
                RAISE NOTICE 'An error occurred while processing reference_id %: %', ref_id, SQLERRM;
        END;
    END LOOP;

	-- Step 2: Insert remaining customer records into customer_master
    INSERT INTO orders.customer_master (
        reference_id,
        merged_ids, 
        merged_with_rules, 
        first_name, 
        last_name, 
        email_address, 
        phone_number, 
        address, 
        date_of_birth, 
        account_status, 
        country, 
        source_system, 
        created_date, 
        updated_date
    )
    SELECT 
        c.id AS reference_id,
        NULL AS merged_ids, 
        NULL AS merged_with_rules, 
        c.first_name, 
        c.last_name, 
        c.email_address, 
        c.phone_number, 
        c.address, 
        c.date_of_birth, 
        c.account_status, 
        c.country, 
        'MDM' AS source_system, 
        CURRENT_TIMESTAMP AS created_date, 
        CURRENT_TIMESTAMP AS updated_date
    FROM 
        orders.customer c
    WHERE 
        c.id NOT IN (
            SELECT reference_id FROM orders.customer_master
            UNION
            SELECT unnest(string_to_array(merged_ids, ',')::int[]) FROM orders.customer_master
        );

	-- Step 3: Flip the mdm_complete to TRUE for the customer records which made it to customer_master table
	UPDATE orders.customer 
		SET mdm_complete = TRUE
	WHERE id IN (
			SELECT reference_id from orders.customer_master
			UNION
			SELECT unnest(string_to_array(merged_ids, ',')::int[]) FROM orders.customer_master);


    RAISE NOTICE 'Survivorship processing completed for all reference_ids';
END;
$$;
