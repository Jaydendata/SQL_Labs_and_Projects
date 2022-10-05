/* 
The lab is from UON's Master of IT (BA) - INFO6090 BI subject.
The practice uses SQL Server to create Star Schema tables and then copy data from interim table to dimension tables.
The practice is done using Azure Data Studio.
*/

CREATE DATABASE INFO6090_Week4Lab_Data


-- 1. Used Azure SQL Server Import Extension to extract data from a csv. file (Sales)

-- Check imported contents in the interim table:
SELECT * FROM [dbo].[INFO6090 Week 4 Lab dataset];

-- Rename the table to 'RawData' 
EXEC sp_rename 'INFO6090 Week 4 Lab dataset', 'RawData';


----------------------------------------------------------------


-- 2. Examine the Raw Data in SQL

-- 2.1 Look up null values
SELECT Receipt_Unique_Id,
        Customer_ID
FROM [dbo].[RawData]
WHERE Receipt_Unique_Id IS NULL OR Customer_ID IS NULL

-- 2.2 Look up duplicated unique values (Receipt Unique ID)
SELECT Receipt_Unique_Id,
        COUNT(*)
FROM [dbo].[RawData]
GROUP BY Receipt_Unique_Id
HAVING COUNT(*) > 1


-------------------------------------------------------------------


-- 3. Copy the raw data to a staging table named 'Lab4DataStaging'

-- 3.1 Create a new table, specify columns, and then insert same contents from the RawData Table.
/* This script assumes the data that was imported from the Excel file is stored in a table
called RawData. Need to adjust this table name if not the same.
*/

CREATE TABLE [dbo].[Lab4DataStaging](
	[Sale_Date] [datetime] NULL,
	[Receipt_Unique_Id ] [nvarchar](255) NULL,
	[Customer_ID] [nvarchar](255) NULL,
	[Customer_First_name] [nvarchar](255) NULL,
	[Customer_Surname] [nvarchar](255) NULL,
	[Customer_Address_Line_1] [nvarchar](255) NULL,
	[Customer_Address_Line_2] [nvarchar](255) NULL,
	[Customer_Address_Suburb] [nvarchar](255) NULL,
	[Customer_Address_Postal_Code] [nvarchar](10) NULL,
	[Staff_Id] [nvarchar](255) NULL,
	[Staff_First_Name] [nvarchar](255) NULL,
	[Staff_Surname] [nvarchar](255) NULL,
	[Total_Items_in_Sale] [int] NULL,
	[Item_1_ID] [nvarchar](5) NULL,
	[Item_1_Quantity] [int] NULL,
	[Item_1_Description] [nvarchar](255) NULL,
	[Item_1_Unit_Price] [float] NULL,
	[Item_1_Sub_Total] [float] NULL,
	[Item_2_Id] [nvarchar](5) NULL,
	[Item_2_Quantity] [int] NULL,
	[Item_2_Description] [nvarchar](255) NULL,
	[Item_2_Unit_Price] [float] NULL,
	[Item_2_Sub_Total] [float] NULL,
	[Receipt_Total_Sale_Amount] [float] NULL
) ON [PRIMARY]

INSERT INTO  [dbo].[Lab4DataStaging](
	  [Sale_Date]
      ,[Receipt_Unique_Id ]
      ,[Customer_ID]
      ,[Customer_First_name]
      ,[Customer_Surname]
      ,[Customer_Address_Line_1]
      ,[Customer_Address_Line_2]
      ,[Customer_Address_Suburb]
      ,[Customer_Address_Postal_Code]
      ,[Staff_Id]
      ,[Staff_First_Name]
      ,[Staff_Surname]
      ,[Total_Items_in_Sale]
      ,[Item_1_ID]
      ,[Item_1_Quantity]
      ,[Item_1_Description]
      ,[Item_1_Unit_Price]
      ,[Item_1_Sub_Total]
      ,[Item_2_Id]
      ,[Item_2_Quantity]
      ,[Item_2_Description]
      ,[Item_2_Unit_Price]
      ,[Item_2_Sub_Total]
      ,[Receipt_Total_Sale_Amount]
)
SELECT [Sale_Date],
        [Receipt_Unique_Id],
        [Customer_ID],
        [Customer_First_name],
        [Customer_Surname],
        [Customer_Address_Line_1],
        [Customer_Address_Line_2],
        [Customer_Address_Suburb],
        [Customer_Address_Postal_Code],
        [Staff_Id],
        [StaffFirst_Name],
        [Staff_Surname],
        [Total_Items_in_Sale],
        [Item1_ID],
        [Item_1_Quantity],
        [Item_1_Description],
        [Item_1_Unit_Price],
        [Item_1_Sub_Total],
        [Item_2_Id],
        [Item_2_Quantity],
        [Item_2_Description],
        [Item_2_Unit_Price],
        [Item_2_Sub_Total],
        [Receipt_Total_Sale_Amount]
  FROM [dbo].[RawData];

-- 3.2 Check imported contents
SELECT * FROM [dbo].[Lab4DataStaging]
SELECT COUNT(*) FROM [dbo].[RawData]



/* NOTE:
The above seems to be a complicated way to duplicate the table. 
Alternatively, we can use SELECT * INTO table2 FROM table1 
*/

-- For example: 

SELECT *
INTO [dbo].[RawDataCopy]
FROM [dbo].[RawData] 


----------------------------------------------------------


-- 4.0 Create the Star Schema tables
/* This step defines the tables in SQL server that will contain 
fact and dimension tables for the Star Schema. Also need to establish keys.*/


-- Setup table for Star Schema Data Mart 
-- Creates a simple star schema

-- Drop tables if they exist
DROP TABLE IF EXISTS FactSales;	--Need to drop FactTable before dropping other tables, 
						--	for example, DimItem and DimDate tables as 
						--	the Fact table contains Foreign Key references 
						--	to both DimItem and DimDate tables
						--	and you cannot drop a table with existing references
						--	from another table
DROP TABLE IF EXISTS DimCustomer;
DROP TABLE IF EXISTS DimStaff;
DROP TABLE IF EXISTS DimDate;
DROP TABLE IF EXISTS DimAddress;
DROP TABLE IF EXISTS DimItem; --After FactTable has been dropped, it is safe to drop Item Table

GO 
/* GO is a signal to send the current batch of Transact-SQL statements 
to an instance of SQL Server.  The scope of local (user-defined) variables is limited to a batch, 
and cannot be referenced after a GO command.
*/

CREATE TABLE DimCustomer (
	Customer_Key int identity not null,					-- Surrogate key for Dimension Table
	Customer_ID nvarchar(3) not null,				-- customer natural key
	Customer_First_Name nvarchar(20) null,
	Customer_Surname nvarchar(20) null,				-- note not null may not always be true	
 Primary Key (Customer_Key)
 )

 /* Need a dimension table for address 
 as a customer can have several addresses and it would
 create confusion when joining customer with sale transaction
 if it appeared 2 customers with different addresses were on the same sale transaction
*/

 CREATE TABLE DimAddress (
	Customer_Address_Key int identity not null,			-- Surrogate key for Dimension Table
	Customer_Address_Line_1 nvarchar(30) null,			
	Customer_Address_Line_2 nvarchar(30) null,			-- can be null
	Customer_Address_Suburb nvarchar(30) null,	
	Customer_Address_Postal_Code nvarchar(5) null,			-- Can be alphanumeric
)

 CREATE TABLE DimStaff (
	Staff_Key int identity not null,				-- Surrogate key for Dimension Table	
	Staff_ID nvarchar(2) null,						-- staff natural key identifer
	Staff_First_Name	nvarchar(20) null,				
	Staff_Surname		nvarchar(20) null,

	Primary Key (Staff_Key)
	)


CREATE TABLE DimItem (					
	Item_Key int identity not null,					--Surrogate dimension table key
	Item_ID	nvarchar(5)	null,						-- Natural item key
	Item_Description nvarchar(30) null,

    Primary Key (Item_Key)
    )

CREATE TABLE DimDate (
	Date_Key int identity not null,
	Date_ID date not null,							
/*This will be the datekey and the actual date, although in
DataMarts it is usually a surrogate key that has a YYYYMMDD format
to allow joins across all table and date formats*/
	Date_Month int	null, -- Can calculate Month from date
	Date_Quarter int null,
	Date_Year int null,

    Primary Key (Date_Key)
    )

--We now create the Fact Table for each Sale transaction.
--Assume there is a business rule that states there are only 2 items per transaction 
 CREATE TABLE FactSale (
	Sale_Key int identity not null,					--Surrogate Sale Fact Key
	Receipt_Unique_Key nvarchar(255) null,			--Natural Sale Transaction Key
	Sale_Date_Key int null,							--will use a Date Dimension later
	Customer_Key int null,
	Customer_Address_Key int null,
	Staff_Key int null,
	Item_1_Key Int null,
	Item_1_Quantity int null,
	Item_1_Unit_Price  decimal(5,2) null,
	Item_1_Sub_Total decimal(5,2) null,
	Item_2_Key Int null,
	Item_2_Quantity int null,
	Item_2_Unit_Price  decimal(5,2) null,
	Item_2_Sub_Total decimal(5,2) null,
	Total_Items_In_Sale int null,
	Receipt_Total_Sale_Amount decimal(5,2) null, 
	
	
 FOREIGN KEY (Item_1_Key) REFERENCES DimItem (Item_Key),
 FOREIGN KEY (Item_2_Key) REFERENCES DImItem (Item_Key),
 FOREIGN KEY (Sale_Date_Key)  REFERENCES DimDate (Date_Key),
 FOREIGN KEY (Customer_Key) REFERENCES DimCustomer (Customer_Key),
 FOREIGN KEY (Staff_Key) REFERENCES DimStaff (Staff_Key)
 )							

 GO

 ---------------------------------------------------

-- 5.0 Lastly, copy data into created schema tables. 

--  Populate the DataMart Star Schema tables from Lab4DataStaging table.

INSERT INTO DimDate 
(Date_ID, Date_Month, Date_Quarter, Date_Year)
SELECT distinct Cast(Lab4DataStaging.[Sale_Date] AS date), 
                Datepart(month, Lab4DataStaging.[Sale_Date]), 
                Datepart(quarter, Lab4DataStaging.[Sale_Date]), 
                Datepart(year, Lab4DataStaging.[Sale_Date]) 
FROM Lab4DataStaging


Insert into DimCustomer
(Customer_ID, Customer_First_Name, Customer_Surname)
SELECT distinct Lab4DataStaging.[Customer_ID], 
                Lab4DataStaging.[Customer_First_name], 
                Lab4DataStaging.[Customer_Surname]
FROM Lab4DataStaging


Insert into DimAddress
(Customer_Address_Line_1, Customer_Address_Line_2, Customer_Address_Suburb, Customer_Address_Postal_Code)
SELECT distinct Lab4DataStaging.[Customer_Address_Line_1],
                Lab4DataStaging.[Customer_Address_Line_2], 
                Lab4DataStaging.[Customer_Address_Suburb], 
                Lab4DataStaging.[Customer_Address_Postal_Code]
FROM Lab4DataStaging



Insert into DimStaff
 (Staff_ID, Staff_First_Name, Staff_Surname)
SELECT distinct Lab4DataStaging.[staff_ID],
                Lab4DataStaging.[Staff_First_Name], 
                Lab4DataStaging.[Staff_Surname]
FROM Lab4DataStaging


--Get the unique Item Id's and match their description
Insert into DimItem 
(Item_ID)
SELECT  Lab4DataStaging.[item_1_id] from Lab4DataStaging
UNION
SELECT distinct Lab4DataStaging.[Item_2_Id] from Lab4DataStaging
WHERE item_1_id <> [Item_2_Id] AND [Item_2_Id] IS NOT NULL


/*SELECT distinct (Lab4DataStaging.[Item_1_ID] + Lab4DataStaging.[Item_2_Id]) from Lab4DataStaging 
where item_1_id <> [Item_2_Id] AND [Item_2_Id] IS NOT NULL
*/


--Insert the matching description
Update DimItem
Set DimItem.Item_Description = Lab4DataStaging.[Item_1_Description] 
FROM DimItem left join Lab4DataStaging
ON DimItem.Item_ID = Lab4DataStaging.Item_1_ID
OR DimItem.Item_ID = Lab4DataStaging.[Item_2_Id]


--Now Populate the Fact Table
INSERT INTO FactSale
(Receipt_Unique_Key, Sale_Date_Key, Customer_Key, Customer_Address_Key, Staff_Key, Item_1_Key, Item_1_Quantity, Item_1_Unit_Price, Item_1_Sub_Total,
	Item_2_Key, Item_2_Quantity, Item_2_Unit_Price, Item_2_Sub_Total, Total_Items_In_Sale, Receipt_Total_Sale_Amount)
	  
  SELECT  x.[Receipt_Unique_Id],
          d.[Date_Key], 
          c.[Customer_Key], 
          a.[Customer_Address_Key], 
          s.[Staff_Key], 
          i.[Item_Key], 
          x.[Item_1_Quantity], 
          x.[Item_1_Unit_Price],
          x.[Item_1_Sub_Total],
          p.[Item_Key],
          x.[Item_2_Quantity],
          x.[Item_2_Unit_Price], 
          x.[Item_2_Sub_Total], 
          x.[Total_Items_in_Sale], 
          x.[Receipt_Total_Sale_Amount]
  FROM
  Lab4DataStaging x
	left join DImStaff s
		on s.Staff_ID = x.[Staff_Id]
	left Join DimAddress a	
		on x.[Customer_Address_Line_1] = a.Customer_Address_Line_1
	left join DimCustomer c
		on x.[Customer_ID] = c.Customer_ID
	left join DimDate d
		on x.[Sale_Date] = d.Date_ID
	Left join DImItem i
		on x.item_1_id = i.Item_ID
	left join DimItem p
		on x.[Item_2_Id] = p.Item_ID 
