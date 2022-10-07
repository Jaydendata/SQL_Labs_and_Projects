-- 1. Create Data Base
CREATE DATABASE SalesPersonAnalysis

-- 2. Import data from SalePerson.csv using Import Wizard

-- 3. Define demisions and fact table to create a star schema

-- 3.1 Create DimCustomer Table to contain Customer ID (PK) and Names

USE SalesPersonAnalysis

DROP TABLE IF EXISTS DimCustomer
CREATE TABLE DimCustomer
(
    [Customer_ID] VARCHAR (32) NOT NULL,
    [Customer_First_Name] VARCHAR (32),
    [Customer_Surname] VARCHAR (32),
    PRIMARY KEY (Customer_ID)
);

-- 3.2 Create DimOffice Table to include office number and office location

USE SalesPersonAnalysis

DROP TABLE IF EXISTS DimOffice
CREATE TABLE DimOffice
(
    [Staff_Office_Key] VARCHAR (32) NOT NULL,
    [Staff_Office_Location] VARCHAR (32),
    PRIMARY KEY (Staff_Office_Key)
);

-- 3.3 Create DimItem to include Item ID (PK) and Item Descrpition

DROP TABLE IF EXISTS DimItem
CREATE TABLE DimItem
(
    [Item_ID] VARCHAR (32) NOT NULL,
    [Item_Description] VARCHAR (32),
    PRIMARY KEY (Item_ID)
);

-- 3.4 Create DimStaff to inlude Staff ID (PK) and Staff names

DROP TABLE IF EXISTS DimStaff
CREATE TABLE DimStaff
(
    [Staff_ID] VARCHAR (32) NOT NULL,
    [Staff_First_Name] VARCHAR (32),
    [Staff_Surname] VARCHAR (32),
    PRIMARY KEY (Staff_ID)
);

-- 3.5 Create DimDate table to inlclude Date key as a surrogate key, Date ID, Month, Quarter and Year.

DROP TABLE IF EXISTS DimDate
CREATE TABLE DimDate
(
    [Date_Key] INT IDENTITY NOT NULL,
    [Date_ID] DATE NOT NULL,
    [Date_Month] INT NOT NULL,
    [Date_Quarter] INT NOT NULL,
    [Date_Year] INT NOT NULL,
    PRIMARY KEY (Date_Key),
);

-- 3.6 Create Fact Table with surrogate key Sale Key, date, customer, staff, item(product) information
DROP TABLE IF EXISTS FactSale
CREATE TABLE FactSale
(
    [Sale_Key] INT IDENTITY NOT NULL,
    [Loyalty] VARCHAR (32),
    [Date_Key] INT,
    [Customer_ID] VARCHAR (32),
    [Staff_ID] VARCHAR (32),
    [Item_ID] VARCHAR (32),
    [Item_Quantity] INT,
    [Item_Price] FLOAT,
    [Row_Total] FLOAT,
    [Receipt_Transaction_Row] INT,
    [Receipt_ID] INT,

-- 3.7 Define foreign keys in the Fact Table

    FOREIGN KEY (Date_Key) REFERENCES DimDate (Date_Key),
    FOREIGN KEY (Customer_ID) REFERENCES DimCustomer (Customer_ID),
    FOREIGN KEY (Staff_ID) REFERENCES DimStaff (Staff_ID),
    FOREIGN KEY (Item_ID) REFERENCES DimItem (Item_ID),

);

-- 4.0 

