/*
=======================================================================
DDL Scripts: Create Gold Views
==============================================================================================
Scripts Purpose:
    This script create view for the gold layer in the data warehouse.
    The Gold layer represents for the final dimension and fact tables (star schema)

    Each view perform transformation and combines data from the silver layer to produce a clean, 
    enriched, and business ready dataset.

 Usages: 
     - These views can be queried directly for analytics and reporting.
==================================================================================================
*/
     
-- ====================================================================
-- Combining the tables crm_cust_info , erp_cust_az12, erp_loc_a101 to 
-- get the combine/related data of the customers
-- =====================================================================

CREATE VIEW gold.dim_customers AS
Select 
	ROW_NUMBER() OVER (ORDER BY cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastName as last_name,
	la.cntry as country,
	ci.cst_marital_status as marital_status,
	CASE
		 WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		 ELSE COALESCE(ca.gen, 'n/a') 
	END as gender,
	ca.bdate as birthdate, 
	ci.cst_create_date as create_date
from silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 as ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON		   ci.cst_key = la.cid;

-- ==================================================================================================
-- Now let combine the data for PRODUCTS from table  silver.crm_prd_info and silver.erp_px_cat_g1v2
-- and put it in view
-- ==================================================================================================

CREATE VIEW  gold.dim_products AS
SELECT
	  ROW_NUMBER() OVER (ORDER BY  pn.prd_start_dt, pn.prd_key) as product_key,
	  pn.prd_id as product_id,
	  pn.prd_key as product_number,
	  pn.prd_nm as product_name,
	  pn.cat_id as category_id,
	  pc.cat as category,
	  pc.subcat as subcategory,
	  pc.maintenance ,
	  pn.prd_cost as cost,
	  pn.prd_line as product_line,
	  pn.prd_start_dt as start_date
 from silver.crm_prd_info as pn
 LEFT JOIN silver.erp_px_cat_g1v2 as pc
 ON	       pn.cat_id =	pc.id   
 WHERE prd_end_dt IS NULL; --Getting the new data (if the end dt is null it's means that data is new

 -- =======================================
 -- Now let make a view of the Sales table
 -- =======================================

 CREATE VIEW gold.fact_sales AS
 Select  
	 sd.sls_ord_num as order_number,
	 pr.product_key,
	 cu.customer_key,
	 sd.sls_order_dt as order_date,
	 sd.sls_ship_dt as shipping_date,
	 sd.sls_due_dt as due_date,
	 sd.sls_sales as sales_amount,
	 sd.sls_quantity as quantity,
	 sd.sls_price as price
 from silver.crm_sales_details as sd
 LEFT JOIN gold.dim_products as pr
 ON		   sd.sls_prd_key = pr.product_number
 LEFT JOIN gold.dim_customers as cu
 ON		   sd.sls_cust_id = cu.customer_id;
