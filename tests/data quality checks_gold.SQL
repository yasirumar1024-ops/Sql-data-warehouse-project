/*
===================================================================================================
Quality checks
============================================================================================================================================
Scripts Purpose:
    This scripts perform quality checks to validate the integrity, consistency, and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential intergrity between fact and dimension tables.
    - validation of the relationships in the data model for analytical purpose.

Usage Notes
    - Run these checks after data loading Silver layer.
    - Investigae and resolve any discrepancies found during the checks
===============================================================================================================================================
*/

-- now checking these tables that is there any duplicates

select cst_id,
COUNT(*) as duplicates
from
(
Select 
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastName,
ci.cst_marital_status,
ci.cst_gndr,
ci.cst_create_date,
ca.bdate,
ca.gen,
la.cntry
from silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 as ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON		   ci.cst_key = la.cid
)y
Group by cst_id
Having count(*) > 1;

-- NOW let do data integration because we have two gender in the table

Select DISTINCT
ci.cst_gndr,
ca.gen,
CASE
	WHEN ci_cst_gndr != 'n/a' THEN ci_cst_gndr
	WHEN ci_cst_gndr = 'n/a' or ci_cst_gndr is NULL then ca.gen
END new
from silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 as ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON		   ci.cst_key = la.cid
Order by 1,2;


SELECT DISTINCT
    ci.cst_gndr,
    ca.gen,
CASE
	 WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- Here crm is master for gender
	 ELSE COALESCE(ca.gen, 'n/a')--  here when this senario occur ask the source developer 
END as new_gen				-- That which data is more important and correct.
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 AS ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 AS la
    ON ci.cst_key = la.cid
ORDER BY 1,2;

-- Checking the Quality of these tables
 SELECT * FROM gold.dim_customers;

 -- now check the uniqueness of columns

 Select DISTINCT gender from gold.dim_customers; 

 -- ===============================================================
 -- In prd_info table we have to type of data about the
 -- product the one is current data and the other is 
 -- historical (PAST) data of the product so for that we
 -- will seperate the data for the current and the historical data
 -- ===============================================================

 -- FOR CURRENT DATA
 -- ALSO HERE WE JOIN A TABLE silver.erp_px_cat_g1v2 TO GET DATA FROM IT.
 -- NOW CHECK THE DATA QUALITY THAT IS THERE ANY DUPLICATES

 SELECT prd_key,
 COUNT (*)
 from
 (
 Select 
 pn.prd_id,
 pn.cat_id,
 pn.prd_key,
 pn.prd_nm,
 pn.prd_cost,
 pn.prd_line,
 pn.prd_start_dt,
 pc.cat,
 pc.subcat,
 pc.maintenance
 from silver.crm_prd_info as pn
 LEFT JOIN silver.erp_px_cat_g1v2 as pc
 ON	       pn.cat_id =	pc.id   
 WHERE prd_end_dt IS NULL
 )y --Getting the new data (if the end dt is null it's means that data is new
 group by prd_key
 having count(*) > 1;

 -- Now let check our new  view -> gold.dim_products
 select * from gold.dim_products;

select * from  gold.fact_sales;

-- Foreign key Integration (Dimensions)
Select * 
from gold.fact_sales as f
LEFT JOIN gold.dim_customers as c
On c.customer_key = f.customer_key
LEFT JOIN gold.dim_products as p
ON p.product_key = f.product_key
where p.product_key IS NULL;
