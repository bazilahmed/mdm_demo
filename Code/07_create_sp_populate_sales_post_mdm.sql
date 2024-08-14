CREATE OR REPLACE PROCEDURE orders.populate_sales_post_mdm()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert or update records from sales into sales_post_mdm
    INSERT INTO orders.sales_post_mdm (
        id,
        transaction_id,
        product_id,
        customer_master_id,
        transaction_date,
        quantity,
        total_amount,
        currency,
        payment_method,
        created_date,
        updated_date
    )
    SELECT DISTINCT ON (s.id)  -- Ensure each id is unique in the result set
        s.id,
        s.transaction_id,
        s.product_id,
        cm.master_id AS customer_master_id,
        s.transaction_date,
        s.quantity,
        s.total_amount,
        s.currency,
        s.payment_method,
        s.created_date,
        s.updated_date
    FROM 
        orders.sales s
    JOIN 
        orders.customer c
    ON
        c.customer_id = s.customer_id
    JOIN 
        orders.customer_master cm
    ON 
        c.id = ANY (string_to_array(cm.merged_ids, ',')::int[])
        OR c.id = cm.reference_id  -- This checks if c.id is either in the merged_ids or is the reference_id itself
    ORDER BY s.id, cm.master_id DESC  -- Prioritize the most recent or highest master_id
    ON CONFLICT (id)  -- On conflict with the same id in sales_post_mdm
    DO UPDATE SET
        customer_master_id = EXCLUDED.customer_master_id,  -- Update the master_id if it changes
        transaction_id = EXCLUDED.transaction_id,
        product_id = EXCLUDED.product_id,
        transaction_date = EXCLUDED.transaction_date,
        quantity = EXCLUDED.quantity,
        total_amount = EXCLUDED.total_amount,
        currency = EXCLUDED.currency,
        payment_method = EXCLUDED.payment_method,
        created_date = EXCLUDED.created_date,
        updated_date = EXCLUDED.updated_date;

    -- Step to flip the mdm_complete flag to TRUE in the sales table
    UPDATE orders.sales s
    SET mdm_complete = TRUE
    FROM orders.customer c
    JOIN orders.customer_master cm
    ON c.id = ANY (string_to_array(cm.merged_ids, ',')::int[])
       OR c.id = cm.reference_id
    WHERE s.customer_id = c.customer_id
      AND s.mdm_complete = FALSE;

    RAISE NOTICE 'Sales data populated or updated in sales_post_mdm table, and mdm_complete flag updated in sales table';
END;
$$;
