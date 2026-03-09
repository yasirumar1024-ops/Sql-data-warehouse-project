/*
========================================================================================
Stored Procedure: Load Silver layer (Bronze -> Silver)
========================================================================================
Script Purpose:
  This stored procedure performs the ETL (Extract, Transform, Load) process to populate
  the ' sliver ' schema tables from thr ' bronze ' schema.
 Actios Performed:
    - Truncates Sliver tables.
    - Inserts transformed and cleansed data from bronze into silver tables.

Parameters:
  None.
  This stoers procedure does not accept any parameters or return any values.

Usage Example:
  EXEC Silver.load_silver;
============================================================================================
*/

CREATE OR Alter PROCEDURE silver.load_silver as
BEGIN
	BEGIN TRY
		 DECLARE @start_time DATETIME , @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

		 SET @batch_start_time = GETDATE();

		-- ===================================================== 
		-- An Inserting a clean data to the silver.crm_cust_info
		-- =====================================================

		PRINT '=========================================='; 
		PRINT 'Loading Sliver Layer'
		PRINT '==========================================';


		PRINT '-------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '-------------------------------------------';

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table silver.crm_cust_info';
		Truncate Table silver.crm_cust_info;
		PRINT '>> Inserting Data into : silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstName,
			cst_lastName,
			cst_marital_status,
			cst_gndr,
			cst_create_date 
		)
		Select
		cst_id,
		cst_key,
		TRIM(cst_firstName) as cst_firstName,
		TRIM(cst_lastName) as cst_lastName,
		CASE
			WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Maried'
			ELSE 'n/a'
		END as cst_marital_status, -- Trim and upper the value in case if there is some small alphabhets it may also be convert

		CASE
			WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			ELSE 'n/a'
		END as cst_gndr,
		cst_create_date
		from
		(
		Select 
		*,
		ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
		from bronze.crm_cust_info
		Where cst_id IS NOT NULL
		)t
		where flag_last = 1;
		SET @end_time = GETDATE()
		PRINT ' Loading Time : ' + CAST(DATEDIFF(second,@start_time, @end_time) as NVARCHAR) + ' Seconds ';
		PRINT' -------------------';
		-- =============================================
		-- Inserting a clean Data to silver.crm_prd_info
		-- =============================================

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.crm_prd_info';
		Truncate Table silver.crm_prd_info;
		PRINT '>> Inserting Data into : silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		select 
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5),'-', '_') as cat_id,-- Extract category ID
		SUBSTRING(prd_key,7,len(prd_key)) as prd_key,	   -- Extract product key
		prd_nm,
		ISNULL(prd_cost,0) as prd_cost,
		CASE
			WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			ELSE 'n/a'
		END as prd_line, -- Map product line codes to descriptive values
		CAST(prd_start_dt as DATE) as prd_start_dt, 
		CAST(
			LEAD(prd_start_dt) over (Partition by prd_key order by prd_start_dt )-1 
			as DATE) as prd_end_dt -- Calculate end date as one day before the next start date
		from bronze.crm_prd_info;
		SET @end_time = GETDATE();
		PRINT' Loading Duration : ' + CAST(DATEDIFF(second,@start_time, @end_time) as NVARCHAR) + ' Seconds ';
		PRINT' -------------------';
		-- =======================================================
		-- Inserting a clean Data to  Sliver.crm_sales_details
		-- =======================================================

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.crm_sales_details';
		Truncate Table silver.crm_sales_details;
		PRINT '>> Inserting Data into : silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE
			WHEN sls_order_dt < 0 OR len(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt as NVARCHAR)as DATE)
		END as sls_order_dt, 
		CASE
			WHEN sls_ship_dt < 0 OR len(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt as NVARCHAR)as DATE)
		END as sls_ship_dt,
		CASE
			WHEN sls_due_dt < 0 OR len(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt as NVARCHAR)as DATE)
		END as sls_due_dt,
		CASE
			WHEN sls_sales is NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
					THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales -- Recalulate sales if original value is missing or incorrect
		END as sls_sales,
		sls_quantity,
		CASE
			WHEN sls_price is NULL OR sls_price <= 0
				THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price
		END as sls_price -- Derive price if original value is invald
		from bronze.crm_sales_details;
		SET @end_time = GETDATE();
		PRINT' Loading Duration : ' + CAST(DATEDIFF( second, @start_time, @end_time) as NVARCHAR) + ' Secoonds ';
		PRINT' -------------------';
		-- =======================================================
		-- Inserting a clean Data to  Sliver.erp_cust_az12
		-- =======================================================
			PRINT '-------------------------------------------';
			PRINT 'Loading ERP Tables';
			PRINT '-------------------------------------------';


		SET @start_time = GETDATE()
		PRINT '>> Truncating Table silver.erp_cust_az12';
		Truncate Table silver.erp_cust_az12;
		PRINT '>> Inserting Data into : silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)
		Select
		CASE
			WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix if present
			ELSE cid
		END as cid,
		CASE 
			WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END as bdate, -- SET future BirthDate to Null
		CASE
			WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
			WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
			ELSE 'n/a'
		END as gen -- Normalize gender values and handle unkown cases
		from bronze.erp_cust_az12;
		SET @end_time = GETDATE()
		PRINT' Loading Duration : ' +CAST(DATEDIFF(Second, @start_time, @end_time) as NVARCHAR) + ' Seconds ';
		PRINT' -------------------';
		-- =======================================================
		-- Inserting a clean Data to  Sliver.erp_loc_a101
		-- =======================================================

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.erp_loc_a101';
		Truncate Table silver.erp_loc_a101;
		PRINT '>> Inserting Data into : silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
		)
		SELECT
		REPLACE(cid, '-', '') as cid,
		CASE 
			WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
			WHEN trim(cntry) = '' OR cntry IS NULL THEN 'n/a'
			Else TRIM(cntry)
		END as cntry -- Normalize and Handle missing or blank country codes
		from bronze.erp_loc_a101; 
		SET @end_time = GETDATE()
		PRINT' Loading Duration : ' +CAST(DATEDIFF(Second, @start_time, @end_time) as NVARCHAR) + ' Seconds ';
		PRINT' -------------------';

		-- =======================================================
		-- Inserting a clean Data to  Sliver.erp_px_cat_g1v2
		-- =======================================================

		SET @start_time = GETDATE()
		PRINT '>> Truncating Table silver.erp_px_cat_g1v2';
		Truncate Table silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data into : silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
		id,
		cat,
		subcat,
		maintenance
		From bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE()
		PRINT' Loading Duration : ' +CAST(DATEDIFF(Second, @start_time, @end_time) as NVARCHAR) + ' Seconds ';
		PRINT' -------------------';

		SET @batch_end_time = GETDATE();
		PRINT '=================================';
		PRINT 'Loading silver layer is completed';
		PRINT '    Total durantion time : '+ CAST(DATEDIFF(second,@batch_start_time, @batch_end_time)as NVARCHAR) + ' seconds';
		PRINT '=================================';

		END TRY
		BEGIN CATCH
			PRINT '======================================================================';
			PRINT 'ERROR OCCUR DURING LOADING BRONZE LAYER';
			PRINT 'Error Message' + ERROR_MESSAGE();
			PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR); 
			PRINT '======================================================================';
		END CATCH
END
