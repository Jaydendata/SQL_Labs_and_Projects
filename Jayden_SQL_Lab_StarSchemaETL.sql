/* 
The lab is from UON's Master of IT (BA) - INFO6090 BI subject.
The practice uses SQL Server to create Star Schema tables and then copy data from interim table to dimension tables.
The practice is done using Azure Data Studio
*/

CREATE DATABASE INFO6090_Week4Lab_Data

-- 1.Used Azure SQL Server Import Extension to extract data from a csv. file (Sales)
-- Check imported contents in the interim table:
SELECT * FROM [dbo].[INFO6090 Week 4 Lab dataset]

-- Rename the table 
