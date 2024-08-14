-- First, manually create the database if it doesn't exist:
-- CREATE DATABASE mdm_demo;

-- Then, connect to the mdm_demo database
-- Connect to the mdm_demo database

-- Create the schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS orders;

-- Create the Stage Customer table
CREATE TABLE IF NOT EXISTS orders.stg_customer (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(100) NOT NULL,
    first_name VARCHAR(160),
    last_name VARCHAR(160),
    email_address VARCHAR(200), 
    phone_number VARCHAR(40),
    address VARCHAR(400),
    date_of_birth DATE,
    account_status VARCHAR(20),
    country VARCHAR(100),
    source_system VARCHAR(50),
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create the Customer table
CREATE TABLE IF NOT EXISTS orders.customer (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(100) NOT NULL,
    first_name VARCHAR(160),
    last_name VARCHAR(160),
    email_address VARCHAR(200), 
    phone_number VARCHAR(40),
    address VARCHAR(400),
    date_of_birth DATE,
    account_status VARCHAR(20),
    country VARCHAR(100),
    source_system VARCHAR(50),
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    mdm_complete BOOLEAN DEFAULT FALSE
);



-- Create the Stage Product table
CREATE TABLE IF NOT EXISTS orders.stg_product (
    id SERIAL PRIMARY KEY,
    product_id VARCHAR(100) NOT NULL,
    product_name VARCHAR(200),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    currency VARCHAR(20),
    supplier_id VARCHAR(100),
    stock_level INTEGER,
    discontinued BOOLEAN,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create the Product table
CREATE TABLE IF NOT EXISTS orders.product (
    id SERIAL PRIMARY KEY,
    product_id VARCHAR(100) NOT NULL,
    product_name VARCHAR(200),
    category VARCHAR(100),
    price DECIMAL(10, 2),
    currency VARCHAR(20),
    supplier_id VARCHAR(100),
    stock_level INTEGER,
    discontinued BOOLEAN,
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    mdm_complete BOOLEAN DEFAULT FALSE
);


-- Create the Stage Supplier table
CREATE TABLE IF NOT EXISTS orders.stg_supplier (
    id SERIAL PRIMARY KEY,
    supplier_id VARCHAR(100) NOT NULL,
    supplier_name VARCHAR(200),
    contact_name VARCHAR(200),
    phone_number VARCHAR(40),
    email_address VARCHAR(200),
    address VARCHAR(400),
    country VARCHAR(100),
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Create the Supplier table
CREATE TABLE IF NOT EXISTS orders.supplier (
    id SERIAL PRIMARY KEY,
    supplier_id VARCHAR(100) NOT NULL,
    supplier_name VARCHAR(200),
    contact_name VARCHAR(200),
    phone_number VARCHAR(40),
    email_address VARCHAR(200),
    address VARCHAR(400),
    country VARCHAR(100),
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    mdm_complete BOOLEAN DEFAULT FALSE
);

-- Create the Stage Sales table
CREATE TABLE IF NOT EXISTS orders.stg_sales (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100),
    product_id VARCHAR(100),
    transaction_date DATE,
    quantity INTEGER,
    total_amount DECIMAL(10, 2),
    currency VARCHAR(20),
    payment_method VARCHAR(40),
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Create the Sales table
CREATE TABLE IF NOT EXISTS orders.sales (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(100) NOT NULL,
    customer_id VARCHAR(100),
    product_id VARCHAR(100),
    transaction_date DATE,
    quantity INTEGER,
    total_amount DECIMAL(10, 2),
    currency VARCHAR(20),
    payment_method VARCHAR(40),
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   	mdm_complete BOOLEAN DEFAULT FALSE
);


-- Table for Storing Potential Matches
CREATE TABLE IF NOT EXISTS orders.potential_matches_customer (
    id serial PRIMARY KEY,
    matched_id_1 int NOT NULL,
    matched_id_2 int NOT NULL,
    rule_number int NOT NULL,
    to_be_merged bool NOT NULL DEFAULT TRUE, 
    created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);


-- Enable the pg_trgm extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_trgm;



-- Create the Master table for Customer
CREATE TABLE IF NOT EXISTS orders.customer_master (
    master_id serial PRIMARY KEY,  -- golden record id
    reference_id INT not null unique,
    merged_ids varchar(1000),  -- Stores concatenated IDs from the customer table
    merged_with_rules varchar(1000),  -- Stores concatenated list of matched rules
    first_name varchar(160),
    last_name varchar(160),
    email_address varchar(200),
    phone_number varchar(40),
    address varchar(400),
    date_of_birth date,
    account_status varchar(20),
    country varchar(100),
    source_system varchar(50),
    created_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_date timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL
);


-- Create the post-MDM sales table 
CREATE TABLE IF NOT EXISTS orders.sales_post_mdm (
    id INTEGER PRIMARY KEY,
    transaction_id VARCHAR(100) NOT NULL,
    product_id VARCHAR(100),
    customer_master_id INTEGER NOT NULL,
    transaction_date DATE,
    quantity INTEGER,
    total_amount DECIMAL(10, 2),
    currency VARCHAR(20),
    payment_method VARCHAR(40),
    created_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


-- Create this view to serve as an avenue for comparing the potential matches 
CREATE OR REPLACE VIEW orders.potential_matches_customer_vw AS
WITH ref_list AS (
    -- Get the unique list of id values from the potential matches table and use it as a reference to compare with
    SELECT 
        DISTINCT mc.matched_id_1 AS reference_id,
        NULL::integer AS matched_id,
        NULL::integer AS matched_with_rule
    FROM
        orders.potential_matches_customer mc
    WHERE mc.to_be_merged = true -- filters for records that have been flagged for merging
    ORDER BY
        reference_id
)
SELECT
    rl.*,
    c.first_name,
    c.last_name,
    c.email_address,
    c.phone_number,
    c.address,
    c.date_of_birth,
    c.account_status,
    c.country,
    c.source_system,
    c.customer_id,
    c.created_date,
    c.updated_date
FROM
    ref_list rl
JOIN orders.customer c 
    ON c.id = rl.reference_id
-- Union with all matched ids and specify the rules that made it a successful match
-- The first record of this result set is a reference record and the following are potential matches
UNION 
SELECT
    rl.reference_id,
    mc.matched_id_2 AS matched_id,
    mc.rule_number AS matched_with_rule,
    c.first_name,
    c.last_name,
    c.email_address,
    c.phone_number,
    c.address,
    c.date_of_birth,
    c.account_status,
    c.country,
    c.source_system,
    c.customer_id,
    c.created_date,
    c.updated_date
FROM
    ref_list rl
JOIN orders.potential_matches_customer mc 
    ON mc.matched_id_1 = rl.reference_id
JOIN orders.customer c 
    ON c.id = mc.matched_id_2
WHERE mc.to_be_merged = true -- filters for records that have been flagged for merging
ORDER BY
    reference_id,
    matched_id DESC;

