-- PIVOT Table main Query --



		----------------------------------------------------------------
		------ Non working Generators List -------
		-----------------------------------
SELECT 
    [Location], 
    SUM([Value]) AS TotalGeneration
FROM 
    [dbo].[Generators_Data]
GROUP BY 
    [Location]
HAVING 
    SUM([Value]) = 0  -- Filters locations with total generation greater than 0
ORDER BY 
     [Location] ;  -- Orders by TotalGeneration in descending order



		----------------------------------------------------------------
		------ Most Less Power Genrating 5 Generators  -------
		----------------------------------------------------------------

SELECT TOP 5
    [Location], 
    SUM([Value]) AS TotalGeneration
FROM 
    [dbo].[Generators_Data]
GROUP BY 
    [Location]
HAVING 
    SUM([Value]) > 0  -- Filters locations with total generation greater than 0
ORDER BY 
    TotalGeneration ;  -- Orders by TotalGeneration in descending order


		----------------------------------------------------------------
		------Most Power Generating 5 Generators ---------------
		----------------------------------------------------------------
SELECT TOP 5
    [Location], 
    SUM([Value]) AS TotalGeneration 
FROM 
    [dbo].[Generators_Data]
GROUP BY 
    [Location]
ORDER BY
    [TotalGeneration] DESC;
	   

----- 







			---------------------------------------------------------------
		------ Max Ramp Down Rate List -------
		-----------------------------------
	--------------------------------------------------------------
	--Create Table
	--------------------------------------------------------------

USE Test_DB;  -- Ensure you're using the correct database

-- Create the table to store the data
CREATE TABLE [dbo].[Max_Ramp_Down_Results] (
    [Location] NVARCHAR(255),  -- Column to store Japanese characters (Unicode supported)
    [Max_Ramp_Down_Rate] INT     -- Column for Max Ramp Up Rate as an integer (no decimal)
);


-- DROP TABLE  [dbo].[Max_Ramp_Down_Results];

	--------------------------------------------------------------
	--Insert Data inside Max_RampDown_Results Table 
	--------------------------------------------------------------
----------------------------------------------- 

USE Test_DB;  -- Ensure you're using the correct database

WITH CTE AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY [Location], [Date_U], [Hours]) AS PartitionedRowNum,
        [Value],
        COALESCE(LAG([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) AS PrevValue,
        
        -- Max Ramp Down Rate Calculation
        CASE 
            WHEN [Value] = 0 AND COALESCE(LAG([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) > 0
            THEN FLOOR([Value] + COALESCE(LAG([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0))  -- Using FLOOR to ensure it's an integer
            ELSE 0
        END AS Max_Ramp_Down_Rate
    FROM 
        [dbo].[Generators_Data]  -- Replace with the actual table you're using
)
, RankedResults AS (
    SELECT 
        [Location],
        Max_Ramp_Down_Rate,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Max_Ramp_Down_Rate DESC) AS MaxRateRank
    FROM 
        CTE
    WHERE 
        Max_Ramp_Down_Rate > 0
)
-- Insert the highest Max_Ramp_Down_Rate for each Location into the Max_Ramp_Down_Results table
INSERT INTO [dbo].[Max_Ramp_Down_Results] ([Location], [Max_Ramp_Down_Rate])
SELECT 
    [Location],
    Max_Ramp_Down_Rate
FROM 
    RankedResults
WHERE 
    MaxRateRank = 1
ORDER BY 
    Max_Ramp_Down_Rate DESC;


SELECT* FROM  [dbo].[Max_Ramp_Down_Results]




	---------------------------------------------------------------
	--- Running program Max_Ramp_Down_Rate
    ----------------------------------



WITH CTE AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
		-- ROW_NUMBER() function is often used to assign a unique, sequential number to each row within a partition of data. 
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY [Location], [Date_U], [Hours]) AS PartitionedRowNum,
        
        -- Calculate PrevValue and NextValue
        [Value],
        COALESCE(LAG([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) AS PrevValue,
        
        -- PreCampValue Calculation (Max Ramp Down Rate)
        CASE 
            WHEN [Value] = 0 AND COALESCE(LAG([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) > 0
            THEN [Value] + COALESCE(LAG([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) 
            ELSE 0
        END AS Max_Ramp_Down_Rate
    FROM 
        [dbo].[Generators_Data]
)
, RankedResults AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        PartitionedRowNum,
        [Value],
        PrevValue,
        Max_Ramp_Down_Rate,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Max_Ramp_Down_Rate DESC) AS MaxRateRank
    FROM 
        CTE
    WHERE 
        Max_Ramp_Down_Rate > 0
)
SELECT 
    [Date_U],
    [Hours],
    [Location],
  --  PartitionedRowNum,
    [Value],
    PrevValue,
    Max_Ramp_Down_Rate
FROM 
    RankedResults
WHERE 
    MaxRateRank = 1
ORDER BY 
   Max_Ramp_Down_Rate DESC;


			----------------------------------------------------------------
		------ *** Max Ramp UP Rate List *** -------
		-----------------------------------

		
	--------------------------------------------------------------
	--Create Table
	--------------------------------------------------------------
USE Test_DB;  -- Ensure you're using the Test_DB database

-- Create a table to store the [Location] (with Japanese characters) and [Max_Ramp_UP_Rate] (integer values)
CREATE TABLE [dbo].[Max_Ramp_UP_Results] (
    [Location] NVARCHAR(255),  -- Column for Location that can store Japanese characters
    [Max_Ramp_UP_Rate] INT     -- Column for Max_Ramp_UP_Rate as integer (no decimal)
);


	--------------------------------------------------------------
	--Insert Data inside Max_Ramp_UP_Results Table 
	--------------------------------------------------------------



-- Insert the output from your query into the table
USE Test_DB;  -- Ensure you're using the Test_DB database

-- Insert the output from your query into the table
;WITH CTE AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY [Location], [Date_U], [Hours]) AS PartitionedRowNum,
        [Value],
        COALESCE(LEAD([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) AS NextValue,
        CASE 
            WHEN [Value] = 0 AND COALESCE(LEAD([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) > 0
            THEN FLOOR([Value] + COALESCE(LEAD([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0))  -- Ensure integer values
            ELSE 0
        END AS Max_Ramp_UP_Rate
    FROM 
        [dbo].[Generators_Data]
)
, RankedResults AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        PartitionedRowNum,
        [Value],
        NextValue,
        Max_Ramp_UP_Rate,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Max_Ramp_UP_Rate DESC) AS MaxRateRank
    FROM 
        CTE
    WHERE 
        Max_Ramp_UP_Rate > 0
)
INSERT INTO [dbo].[Max_Ramp_UP_Results] ([Location], [Max_Ramp_UP_Rate])
SELECT 
    [Location],
    Max_Ramp_UP_Rate
FROM 
    RankedResults
WHERE 
    MaxRateRank = 1
ORDER BY 
    Max_Ramp_UP_Rate DESC;


SELECT * FROM [dbo].[Max_Ramp_UP_Results]	   
	---------------------------------------------------------------
	--- Running program Max_Ramp_UP_Rate
    ----------------------------------

-- CTE:- Common Table Expression --
WITH CTE AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
		-- ROW_NUMBER() function is often used to assign a unique, sequential number to each row within a partition of data. 
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY [Location], [Date_U], [Hours]) AS PartitionedRowNum,
        
        -- Calculate PrevValue and NextValue
        [Value],
        COALESCE(LEAD([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) AS NextValue,
        
        -- PreCampValue Calculation (Check if current value is 0 and previous value > 0)
        CASE 
            WHEN [Value] = 0 AND COALESCE(LEAD([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) > 0
            THEN [Value] + COALESCE(LEAD([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U]), 0) 
            ELSE 0
        END AS Max_Ramp_UP_Rate
    FROM 
        [dbo].[Generators_Data]
)
, RankedResults AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        PartitionedRowNum,
        [Value],
        NextValue,
        Max_Ramp_UP_Rate,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Max_Ramp_UP_Rate DESC) AS MaxRateRank
    FROM 
        CTE
    WHERE 
        Max_Ramp_UP_Rate > 0
)
SELECT 
    [Date_U],
    [Hours],
    [Location],
    PartitionedRowNum,
    [Value],
    NextValue,
    Max_Ramp_UP_Rate
FROM 
    RankedResults
WHERE 
    MaxRateRank = 1
ORDER BY 
    Max_Ramp_UP_Rate DESC;



