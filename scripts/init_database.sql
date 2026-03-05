/*
=======================================================================
Create Database and Schemas
=======================================================================
Script Purpose:
  This script create a new database named 'DataWarehouse'.
  The scripts sets up three scheas with the database: 'bronze', 'silver', 'gold'.
*/

-- Create DataBase ' Datawarehouse'

Use master;

CREATE DATABASE DataWarehouse;

-- Let Switch to our new database
USE DataWarehouse;

-- Now we will have to create Schemas
CREATE SCHEMA bronze;
Go

CREATE SCHEMA silver;
Go

CREATE SCHEMA gold;
GO
