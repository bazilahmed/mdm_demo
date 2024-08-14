CREATE OR REPLACE PROCEDURE orders.find_potential_matches_customer()
LANGUAGE plpgsql
AS $$
DECLARE
    is_first_iteration BOOLEAN;
BEGIN
    -- Check if this is the first iteration by seeing if customer_master is empty
    SELECT COUNT(*) = 0 INTO is_first_iteration FROM orders.customer_master;

    IF is_first_iteration THEN
        -- First Iteration: Use self-join on the customer table
        RAISE NOTICE 'First iteration: Performing self-join on customer table';

        -- Rule 1: (EXACT first_name AND EXACT last_name) AND EXACT email_address
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT a.id, b.id, 1
            FROM orders.customer a
            JOIN orders.customer b
            ON a.id < b.id  -- Prevent cyclic references
            AND a.first_name = b.first_name
            AND a.last_name = b.last_name
            AND a.email_address = b.email_address;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 1: %', SQLERRM;
        END;

        -- Rule 2: (EXACT first_name OR EXACT last_name) AND (EXACT email_address OR EXACT date_of_birth)
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT a.id, b.id, 2
            FROM orders.customer a
            JOIN orders.customer b
            ON a.id < b.id  -- Prevent cyclic references
            AND (
                a.first_name = b.first_name
                OR a.last_name = b.last_name
            )
            AND (
                a.email_address = b.email_address
                OR a.date_of_birth = b.date_of_birth
            );
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 2: %', SQLERRM;
        END;

        -- Rule 3: EXACT first_name AND (EXACT phone_number OR EXACT address)
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT a.id, b.id, 3
            FROM orders.customer a
            JOIN orders.customer b
            ON a.id < b.id  -- Prevent cyclic references
            AND a.first_name = b.first_name
            AND (
                a.phone_number = b.phone_number
                OR a.address = b.address
            );
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 3: %', SQLERRM;
        END;

        -- Rule 4: Fuzzy match first_name and last_name with a threshold of 80%
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT a.id, b.id, 4
            FROM orders.customer a
            JOIN orders.customer b
            ON a.id < b.id  -- Prevent cyclic references
            AND similarity(a.first_name, b.first_name) >= 0.8
            AND similarity(a.last_name, b.last_name) >= 0.8;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 4: %', SQLERRM;
        END;

    ELSE
        -- Subsequent Iterations: Match against customer_master
        RAISE NOTICE 'Subsequent iteration: Matching customer against customer_master';

        -- Rule 1: (EXACT first_name AND EXACT last_name) AND EXACT email_address
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT b.reference_id, a.id, 1
            FROM orders.customer a
            JOIN orders.customer_master b
            ON a.first_name = b.first_name
            AND a.last_name = b.last_name
            AND a.email_address = b.email_address
            WHERE a.mdm_complete = FALSE;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 1: %', SQLERRM;
        END;

        -- Rule 2: (EXACT first_name OR EXACT last_name) AND (EXACT email_address OR EXACT date_of_birth)
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT b.reference_id, a.id, 2
            FROM orders.customer a
            JOIN orders.customer_master b
            ON (
                a.first_name = b.first_name
                OR a.last_name = b.last_name
            )
            AND (
                a.email_address = b.email_address
                OR a.date_of_birth = b.date_of_birth
            )
            WHERE a.mdm_complete = FALSE;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 2: %', SQLERRM;
        END;

        -- Rule 3: EXACT first_name AND (EXACT phone_number OR EXACT address)
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT b.reference_id, a.id, 3
            FROM orders.customer a
            JOIN orders.customer_master b
            ON a.first_name = b.first_name
            AND (
                a.phone_number = b.phone_number
                OR a.address = b.address
            )
            WHERE a.mdm_complete = FALSE;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 3: %', SQLERRM;
        END;

        -- Rule 4: Fuzzy match first_name and last_name with a threshold of 80%
        BEGIN
            INSERT INTO orders.potential_matches_customer (matched_id_1, matched_id_2, rule_number)
            SELECT b.reference_id, a.id, 4
            FROM orders.customer a
            JOIN orders.customer_master b
            ON similarity(a.first_name, b.first_name) >= 0.8
            AND similarity(a.last_name, b.last_name) >= 0.8
            WHERE a.mdm_complete = FALSE;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An error occurred in Rule 4: %', SQLERRM;
        END;

    END IF;

END;
$$;
