CREATE OR REPLACE PROCEDURE orders.apply_survivorship_rules(IN ref_id int4)
LANGUAGE plpgsql
AS $$
DECLARE
    master_record RECORD;
    reference_record RECORD;
    recent_transaction RECORD;
    current_master_id int4;
    potential_match RECORD;  -- Declare the loop variable as RECORD
BEGIN
    -- Step 1: Check if the reference_id exists in the potential_matches_customer_vw view
    SELECT *
    INTO reference_record
    FROM orders.potential_matches_customer_vw
    WHERE reference_id = ref_id
	AND matched_id is null
    LIMIT 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No records found for reference_id %', ref_id;
        RETURN;
    END IF;

    -- Step 2: Check if the master record exists in customer_master
    SELECT *
    INTO master_record
    FROM orders.customer_master
    WHERE reference_id = ref_id
    LIMIT 1;

    IF NOT FOUND THEN
        -- Insert the initial master record
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
        VALUES (
            ref_id,  -- Reference ID
            CAST(ref_id AS varchar),  -- Start with the reference ID
            (SELECT STRING_AGG(CAST(pmc.matched_with_rule AS varchar), ',') FROM orders.potential_matches_customer_vw pmc WHERE pmc.reference_id = ref_id),  -- Initialize merged_with_rules with all relevant rules
            reference_record.first_name,
            reference_record.last_name,
            reference_record.email_address,
            reference_record.phone_number,
            reference_record.address,
            reference_record.date_of_birth,
            reference_record.account_status,
            reference_record.country,
            'MDM',  -- Hard-code source_system to 'MDM'
            CURRENT_TIMESTAMP,  -- created_date
            CURRENT_TIMESTAMP   -- updated_date
        )
        RETURNING customer_master.reference_id INTO current_master_id;
    ELSE
        -- Use the existing master record's master_id
        current_master_id := master_record.reference_id;
    END IF;

    -- Step 3: Iterate through potential matches and apply survivorship rules using the master record from customer_master
    FOR potential_match IN
        SELECT 
            pmc.matched_id,
            pmc.matched_with_rule,
            c.first_name,
            c.last_name,
            c.email_address,
            c.phone_number,
            c.address,
            c.date_of_birth,
            c.account_status,
            c.country,
            c.source_system,
            c.created_date,
            c.updated_date
        FROM 
            orders.potential_matches_customer_vw pmc
        JOIN 
            orders.customer c ON c.id = pmc.matched_id
        WHERE 
            pmc.reference_id = ref_id
    LOOP
        -- Re-fetch the latest master record from customer_master before applying rules
        SELECT *
        INTO master_record
        FROM orders.customer_master
        WHERE reference_id = current_master_id
        LIMIT 1;

        -- Apply survivorship rules for each attribute

        -- First Name
        master_record.first_name := COALESCE(
            CASE WHEN potential_match.source_system = 'CRM' THEN potential_match.first_name ELSE NULL END,
            master_record.first_name
        );

        -- Last Name
        master_record.last_name := COALESCE(
            CASE WHEN potential_match.source_system = 'CRM' THEN potential_match.last_name ELSE NULL END,
            master_record.last_name
        );

        -- Email Address
        master_record.email_address := COALESCE(
            CASE WHEN potential_match.source_system = 'CRM' THEN potential_match.email_address ELSE NULL END,
            CASE WHEN potential_match.email_address ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$' THEN potential_match.email_address ELSE NULL END,
            master_record.email_address
        );

        -- Phone Number
        master_record.phone_number := COALESCE(
            CASE WHEN potential_match.source_system = 'CRM' THEN potential_match.phone_number ELSE NULL END,
            CASE WHEN potential_match.phone_number ~* '^\+?[1-9]\d{1,14}$' THEN potential_match.phone_number ELSE NULL END,
            master_record.phone_number
        );

        -- Address
        master_record.address := COALESCE(
            potential_match.address,
            master_record.address
        );

        -- Date of Birth
        master_record.date_of_birth := COALESCE(
            potential_match.date_of_birth,
            master_record.date_of_birth
        );

        -- Account Status
        master_record.account_status := COALESCE(
            CASE WHEN potential_match.source_system = 'CRM' THEN potential_match.account_status ELSE NULL END,
            master_record.account_status
        );

        -- Country
        master_record.country := COALESCE(
            CASE WHEN potential_match.source_system = 'CRM' THEN potential_match.country ELSE NULL END,
            master_record.country
        );

        -- Step 4: Update the master record in the customer_master table
        UPDATE orders.customer_master
        SET 
            merged_ids = orders.customer_master.merged_ids || ',' || CAST(potential_match.matched_id AS varchar),
            merged_with_rules = orders.customer_master.merged_with_rules || ',' || CAST(potential_match.matched_with_rule AS varchar),
            first_name = master_record.first_name,
            last_name = master_record.last_name,
            email_address = master_record.email_address,
            phone_number = master_record.phone_number,
            address = master_record.address,
            date_of_birth = master_record.date_of_birth,
            account_status = master_record.account_status,
            country = master_record.country,
            updated_date = CURRENT_TIMESTAMP
        WHERE 
            customer_master.reference_id = current_master_id;
    END LOOP;

    -- Step 5: Flag the matches as processed
    UPDATE orders.potential_matches_customer
    SET to_be_merged = FALSE
    WHERE matched_id_1 = ref_id OR matched_id_2 = ref_id;
    
    RAISE NOTICE 'Survivorship rules applied and master record updated for reference_id %', ref_id;
END;
$$;
