/*
=======================================================================================================
Quality Checks
========================================================================================================
Scripts:
  This scripts performs various quality checks for data consistency, accuracy and standardization across
  the 'silver' schemas. It includes check for:
  - Null or duplicate primary keys
  - Unwanted spaces in the string field
  - Data standardization and consistency
  - Invalid date ranges and others
  - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver layer.
    - Investigate and resolve any discrepancies found during the checks
==========================================================================================================
*/


-- =============================================================
-- Let find the issue in bronze layer table bronze.crm_cust_info
-- =============================================================
--> checking the primary key that is there any duplicates in it

select 
cst_id,
count(*)
from bronze.crm_cust_info
group by cst_id
Having Count(*) > 1 OR cst_id is null ;

-- ==================================================
-- Check for un wanted spaces in bronze.crm_cust_info
-- ==================================================
-- Expectation : No Results

select
cst_firtName
from bronze.crm_cust_info
where cst_firtName != trim(cst_firtName);

-- Same for lastName

select
cst_lastName
from bronze.crm_cust_info
where cst_lastName != trim(cst_lastName);

-- same as check it for gender
select
cst_gndr
from bronze.crm_cust_info
where cst_gndr != trim(cst_gndr);

-- Data Standardization & Consistency for cst_gndr
select Distinct cst_gndr
from bronze.crm_cust_info;

-- Data Standardization & Consistency for  cst_marital_status
select DISTINCT cst_marital_status
from bronze.crm_cust_info;

-- Now take these all query in order to check the silver.cust_info that is there any strach data

select 
cst_id,
count(*)
from silver.crm_cust_info
group by cst_id
Having Count(*) > 1 OR cst_id is null ;

-- ==================================================
-- Check for un wanted spaces in bronze.crm_cust_info
-- ==================================================
-- Expectation : No Results

select
cst_firstName
from silver.crm_cust_info
where cst_firstName != trim(cst_firstName);

-- Same for lastName

select
cst_lastName
from silver.crm_cust_info
where cst_lastName != trim(cst_lastName);

-- same as check it for gender
select
cst_gndr
from silver.crm_cust_info
where cst_gndr != trim(cst_gndr);

-- Data Standardization & Consistency for cst_gndr
select Distinct cst_gndr
from silver.crm_cust_info;

-- Data Standardization & Consistency for  cst_marital_status
select DISTINCT cst_marital_status
from silver.crm_cust_info;

Select * from silver.crm_cust_info;

-- ======================================================
-- Now checking the data in crm_prd_info
-- ======================================================

-- To check that there's any duplicates in the prd_id

select
prd_id,
count(*) 
from bronze.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id IS NULL;

-- Checking an extra space in the prd_nm
select
prd_nm
from bronze.crm_prd_info
where prd_nm != trim(prd_nm);

-- Check for nulls or negative numbers 
select
prd_cost
from bronze.crm_prd_info
where prd_cost < 0 or prd_cost IS NULL;

-- Data Standardization and consistency
SELECT DISTINCT prd_line
from bronze.crm_prd_info

-- =====================================================
-- Now check the quality data of the silver.crm_prd_info
-- =====================================================

select
prd_id,
count(*) 
from silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id IS NULL;

-- Checking an extra space in the prd_nm
select
prd_nm
from silver.crm_prd_info
where prd_nm != trim(prd_nm);

-- Check for nulls or negative numbers 
select
prd_cost
from silver.crm_prd_info
where prd_cost < 0 or prd_cost IS NULL;

-- Data Standardization and consistency
SELECT DISTINCT prd_line
from silver.crm_prd_info

SELECT * FROM silver.crm_prd_info;

-- ==========================================
-- Now let check the bronze.crm_sales_details
-- ==========================================
select * from bronze.crm_sales_details;
-- Here is the issue in date it is in the form of integer but actually is was a date so now in order to let fix it

-- Check for valid date
select NULLIF(sls_order_dt,0) sls_order_dt
from bronze.crm_sales_details
where sls_order_dt < 0
OR len(sls_order_dt) != 8 
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101;

-- now  check for shipping rule
select NULLIF(sls_ship_dt,0) sls_order_dt
from bronze.crm_sales_details
where sls_ship_dt < 0
OR len(sls_ship_dt) != 8 
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101;

-- now for due date
select NULLIF(sls_due_dt,0) sls_order_dt
from bronze.crm_sales_details
where sls_due_dt < 0
OR len(sls_due_dt) != 8 
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101;

-- Check for the date validation
select
*
from bronze.crm_sales_details
where sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check data consistency : between Sales, Quantity and price
-->> Sales = Quantity * Price
-->> values must not be NULL, Zero or negative
Select
DISTINCT 
sls_sales as old_sls,
sls_quantity,
sls_price,
CASE
	WHEN sls_sales is NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END as sls_sales,

CASE
	WHEN sls_price is NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END as sls_price

from bronze.crm_sales_details
where sls_sales != sls_quantity * sls_price
OR sls_sales is NULL OR sls_quantity is NULL OR sls_price is NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0;

-- ===========================================================
-- Now check all these condititon for silver.crm_sales_details
-- ===========================================================

select NULLIF(sls_order_dt,0) sls_order_dt
from bronze.crm_sales_details
where sls_order_dt < 0
OR len(sls_order_dt) != 8 
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101;

-- now  check for shipping rule
select NULLIF(sls_ship_dt,0) sls_order_dt
from bronze.crm_sales_details
where sls_ship_dt < 0
OR len(sls_ship_dt) != 8 
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101;

-- now for due date
select NULLIF(sls_due_dt,0) sls_order_dt
from silver.crm_sales_details
where sls_due_dt < 0
OR len(sls_due_dt) != 8 
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101;

-- Check for the date validation
select
*
from silver.crm_sales_details
where sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check data consistency : between Sales, Quantity and price
-->> Sales = Quantity * Price
-->> values must not be NULL, Zero or negative
Select
DISTINCT 
sls_sales as old_sls,
sls_quantity,
sls_price,
CASE
	WHEN sls_sales is NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
			THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales
END as sls_sales,

CASE
	WHEN sls_price is NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0)
	ELSE sls_price
END as sls_price

from silver.crm_sales_details
where sls_sales != sls_quantity * sls_price
OR sls_sales is NULL OR sls_quantity is NULL OR sls_price is NULL
OR sls_sales <=0 OR sls_quantity <=0 OR sls_price <=0;

select * from silver.crm_sales_details;

-- ===================================
-- Now let clean the data of cust_az12
-- ===================================
Select
cid,
CASE
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END as cid,
bdate,
gen
from bronze.erp_cust_az12;

-- Identity out of range dates
select DISTINCT
bdate
from bronze.erp_cust_az12
where bdate < '1924-01-01' OR bdate > GETDATE();

-- Now let check it for Gender
Select DISTINCT gen,
CASE
	WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	ELSE 'n/a'
END as gen
from silver.erp_cust_az12;

Select
cid,
CASE
	WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END as cid,
bdate,
gen
from silver.erp_cust_az12;

-- Identity out of range dates
select DISTINCT
bdate
from silver.erp_cust_az12
where bdate < '1924-01-01' OR bdate > GETDATE();

-- Now let check it for Gender
Select DISTINCT gen,
CASE
	WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	ELSE 'n/a'
END as gen
from silver.erp_cust_az12;

SELECT * from silver.erp_cust_az12;

-- =============================
-- Now turn for loc_a101
-- =============================
select 
cid,
REPLACE(cid, '-', '') as cid,
cntry
from bronze.erp_loc_a101;

-- Data standaedization and consistency
Select DISTINCT cntry,
CASE 
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN trim(cntry) = '' OR cntry IS NULL THEN 'n/a'
	Else TRIM(cntry)
END as cntry
from bronze.erp_loc_a101;

-- Now check for the silver table

select 
cid,
REPLACE(cid, '-', '') as cid,
cntry
from silver.erp_loc_a101;

-- Data standaedization and consistency
Select DISTINCT cntry,
CASE 
	WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	WHEN trim(cntry) = '' OR cntry IS NULL THEN 'n/a'
	Else TRIM(cntry)
END as cntry
from silver.erp_loc_a101;

Select * from silver.erp_loc_a101; 

-- ======================================================================
-- Now cheacking an un cleaned data in the bronze.erp_px_cat_g1v2
-- ======================================================================
 Select * From bronze.erp_px_cat_g1v2

 Select Distinct 
 maintenance
 from bronze.erp_px_cat_g1v2

 -- Check For unwanted Spaces
 select
 *
 from bronze.erp_px_cat_g1v2
 where cat != trim(cat)
 OR subcat != TRIM(subcat)
 OR maintenance != TRIM(maintenance);

 -- Let check datastandardization & Consistency
 Select Distinct
 cat
From bronze.erp_px_cat_g1v2;

select Distinct
subcat
From bronze.erp_px_cat_g1v2;

Select DISTINCT
maintenance
From bronze.erp_px_cat_g1v2;

Select * from silver.erp_px_cat_g1v2;

-- EXECUTE STORE PROCEDURE
 EXEC silver.load_silver;
