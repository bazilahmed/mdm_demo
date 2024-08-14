-- a stored procedure that updates the to_be_merged value to FALSE for a specific record in the orders.potential_matches_customer table, based on the provided reference_id, matched_id, and rule_number parameters.
CREATE OR REPLACE PROCEDURE orders.flag_to_be_merged_false(
    IN reference_id int4,
    IN matched_id int4,
    IN rule_num int4  
)
LANGUAGE plpgsql
AS $$
DECLARE
    row_count INT;
BEGIN
    -- Update the 'to_be_merged' flag to FALSE for the given reference_id, matched_id, and rule_number
    UPDATE orders.potential_matches_customer
    SET to_be_merged = FALSE
    WHERE matched_id_1 = reference_id
      AND matched_id_2 = matched_id
      AND rule_number = rule_num;
      
    GET DIAGNOSTICS row_count = ROW_COUNT;

    -- If no rows were updated, check for reverse order
    IF row_count = 0 THEN
        UPDATE orders.potential_matches_customer
        SET to_be_merged = FALSE
        WHERE matched_id_1 = matched_id
          AND matched_id_2 = reference_id
          AND rule_number = rule_num;

        GET DIAGNOSTICS row_count = ROW_COUNT;
    END IF;
    
    -- Raise a consistent notice if no rows were updated
    IF row_count = 0 THEN
        RAISE NOTICE 'No match found for reference_id %, matched_id %, rule_number %', reference_id, matched_id, rule_num;
    ELSE
        RAISE NOTICE 'Record updated successfully for reference_id %, matched_id %, rule_number %', reference_id, matched_id, rule_num;
    END IF;
END;
$$;
