---- EXEC sp_help 'dbo.Short_Operation_Result'; --

WITH CTE AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        [Value],
        CASE 
            WHEN [Value] > 1 THEN 1  -- Binary_Value = 1 if Value > 1, else 0
            ELSE 0
        END AS Binary_Value
  --  FROM #TempTable
  FROM [Test_DB].[dbo].[Generators_Data]
),
RunningCount AS (
    SELECT 
        * ,
        -- Create a resettable count that restarts when Binary_Value = 1 after 0
        SUM(CASE WHEN Binary_Value = 0 THEN 1 ELSE 0 END) 
        OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours] ROWS UNBOUNDED PRECEDING) AS ResetGroup
    FROM CTE
),
SelectedValues AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binary_Value,
        ResetGroup,  -- Include ResetGroup here
        -- Updated logic to count 1 to 3 and reset to 0
        CASE 
            WHEN Binary_Value = 1 THEN 
                ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U], [Hours]) - 1
            ELSE 0 
        END AS Binary_Count,
        -- Add logic to set Selected_Value based on Binary_Count 1 or 2
        CASE 
            WHEN Binary_Value = 1 AND 
                 ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U], [Hours]) <= 4 
            THEN [Value]
            ELSE 0
        END AS Selected_Value
    FROM RunningCount
),
FilteredValues AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binary_Value,
        Binary_Count,
        Selected_Value,
        ResetGroup,  -- Include ResetGroup here
        LAG(Binary_Value) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Previous_Binary_Value,
        LEAD(Binary_Count) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Next_Binary_Count,
        LEAD(Selected_Value) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Next_Selected_Value
    FROM SelectedValues
),
FilteredValuesFinal AS (
    SELECT 
        * ,
        -- Compute NextTo_Next_Selected_Value in a separate step by referencing Selected_Value
        LEAD(Selected_Value) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS NextTo_Next_Selected_Value
    FROM FilteredValues
),
FinalResult AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binary_Value,
        Binary_Count,
        -- Only display Highest_Binary_Count_Group once per ResetGroup
        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U], [Hours]) = 2 
            THEN MAX(Binary_Count) OVER (PARTITION BY [Location], ResetGroup) 
            ELSE 0
        END AS Total_Numbers_In_Binary_Count_Group
    FROM FilteredValuesFinal
)
-- Final output with filtered results and added logic for Total_Hours
SELECT 
    [Date_U],
    [Hours],
    [Location],
    [Value],
    Binary_Value,
    Binary_Count,
    Total_Numbers_In_Binary_Count_Group,
    -- Calculate Total_Hours based on Total_Numbers_In_Binary_Count_Group, rounded to two decimal places
    CASE
        WHEN Total_Numbers_In_Binary_Count_Group > 0
        THEN CAST(ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2) AS DECIMAL(10, 2))
        ELSE 0
    END AS [Total_Hours]
INTO #FinalResult
FROM FinalResult
ORDER BY [Location], [Date_U], [Hours];

-- Drop table #FinalResult

-- select * from #FinalResult

-------------------------------
-- Query:- 
-------------------------------
SELECT * FROM Test_DB.dbo.Short_Operation_Result;

SELECT * 
FROM Test_DB.dbo.Short_Operation_Result
WHERE [Total_Hours] > 0
ORDER BY  [Location], [Date_U], [Hours] ;


--------------------------------------------------------------------------------------------------
-- Query Group by Location :- 
--------------------------------------------------------------------------------------------------

SELECT 
    [Date_U],
    [Hours],
    [Location],
    [Value],
    Binary_Value,
    Binary_Count,
    Total_Numbers_In_Binary_Count_Group,
    CASE
        WHEN Total_Numbers_In_Binary_Count_Group > 0
        THEN CAST(ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2) AS DECIMAL(10, 2))
        ELSE 0
    END AS [Total_Hours]
FROM (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binary_Value,
        Binary_Count,
        Total_Numbers_In_Binary_Count_Group,
        CASE
            WHEN Total_Numbers_In_Binary_Count_Group > 0
            THEN CAST(ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2) AS DECIMAL(10, 2))
            ELSE 0
        END AS [Total_Hours],
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY 
            CASE
                WHEN Total_Numbers_In_Binary_Count_Group > 0
                THEN ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2)
                ELSE 0
            END ASC) AS RowNum
    FROM Test_DB.dbo.Short_Operation_Result
    WHERE Total_Numbers_In_Binary_Count_Group > 0 -- Filter out records with 0 Total_Numbers_In_Binary_Count_Group
) AS RankedResults
WHERE RowNum <= 3  -- Get top 3 smallest Total_Hours for each Location
ORDER BY [Location], RowNum;


--------------------------------------------------------------------------------------------------------------
-- Display only [Location], [Total_Hours] 
--------------------------------------------------------------------------------------------------------------

SELECT 
    [Location], 
    [Total_Hours]
FROM (
    SELECT 
        [Location],
        CASE
            WHEN Total_Numbers_In_Binary_Count_Group > 0
            THEN CAST(ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2) AS DECIMAL(10, 2))
            ELSE 0
        END AS [Total_Hours],
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY 
            CASE
                WHEN Total_Numbers_In_Binary_Count_Group > 0
                THEN ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2)
                ELSE 0
            END ASC) AS RowNum
    FROM Test_DB.dbo.Short_Operation_Result
    WHERE Total_Numbers_In_Binary_Count_Group > 0 -- Filter out records with 0 Total_Numbers_In_Binary_Count_Group
) AS RankedResults
WHERE RowNum <= 3  -- Get top 3 smallest Total_Hours for each Location
ORDER BY [Location], RowNum;

--------------------------------------------------------------------------------
-- Transpose query :- 
---------------------------------------------------------------------------------

WITH RankedResults AS (
    SELECT 
        [Location],
        CASE
            WHEN Total_Numbers_In_Binary_Count_Group > 0
            THEN CAST(ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2) AS DECIMAL(10, 2))
            ELSE 0
        END AS [Total_Hours],
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY 
            CASE
                WHEN Total_Numbers_In_Binary_Count_Group > 0
                THEN ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2)
                ELSE 0
            END ASC) AS RowNum
    FROM Test_DB.dbo.Short_Operation_Result
    WHERE Total_Numbers_In_Binary_Count_Group > 0 -- Filter out records with 0 Total_Numbers_In_Binary_Count_Group
)
SELECT 
    [Location],
    MAX(CASE WHEN RowNum = 1 THEN Total_Hours END) AS 'Short_Operation-1',
    MAX(CASE WHEN RowNum = 2 THEN Total_Hours END) AS 'Short_Operation-2',
    MAX(CASE WHEN RowNum = 3 THEN Total_Hours END) AS 'Short_Operation-3'
FROM RankedResults
WHERE RowNum <= 3  -- Get top 3 smallest Total_Hours for each Location
GROUP BY [Location]
ORDER BY [Location];





/*

=============================================================================
-- Finding Data type:-
=============================================================================

SELECT * FROM tempdb.sys.objects WHERE name LIKE '#FinalResult%';

EXEC sp_help '#FinalResult';

SELECT name AS COLUMN_NAME, 
       TYPE_NAME(user_type_id) AS DATA_TYPE
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..#FinalResult');




IF OBJECT_ID('tempdb..#FinalResult') IS NOT NULL
    PRINT 'Table exists.'
ELSE
    PRINT 'Table does not exist.';




EXEC sp_help 'Test_DB.dbo.Generators_Data'; --

EXEC sp_help 'Test_DB.dbo.Short_Operation_Result'; --


=============================================================================
-- Finding DataType -- 
=============================================================================
SELECT 
    COLUMN_NAME, DATA_TYPE 
FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME LIKE '#FinalResult%';


==============================================================================


SELECT * 
FROM Test_DB.dbo.Short_Operation_Result
WHERE [Total_Hours] > 0
ORDER BY  [Location], [Date_U], [Hours] ;



==============================================================================
Convert FLOAT to DATE
==============================================================================

WITH CTE AS (
    SELECT 
        -- Fix conversion by converting INT to VARCHAR(8) first, then to DATE
        CONVERT(DATE, CONVERT(VARCHAR(8), CAST([Date_U] AS INT))) AS Date_U, 
        [Hours],
        [Location],
        [Value],
        CASE WHEN [Value] > 1 THEN 1 ELSE 0 END AS Binary_Value
    FROM [Test_DB].[dbo].[Generators_Data]
)
SELECT * FROM CTE;

==============================================================================

INSERT INTO Test_DB.dbo.Short_Operation_Result (
    Day,               -- DATETIME column
    Hours,             -- FLOAT
    Date_U,            -- FLOAT (original)
    Location,          -- NVARCHAR
    Value              -- FLOAT
)
SELECT  
    -- Convert FLOAT YYYYMMDD to DATETIME
    CONVERT(DATETIME, CONVERT(VARCHAR(8), CAST([Date_U] AS INT), 112)) AS Day, 
    [Hours],         -- FLOAT
    [Date_U],        -- FLOAT (original value)
    [Location],      -- NVARCHAR
    [Value]          -- FLOAT
FROM #FinalResult;

------------------------------------------------

-- Step 2: Insert data into the new table with the updated column names
WITH RankedResults AS (
    SELECT 
        [Location],
        CASE
            WHEN Total_Numbers_In_Binary_Count_Group > 0
            THEN CAST(ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2) AS DECIMAL(10, 2))
            ELSE 0
        END AS [Total_Hours],
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY 
            CASE
                WHEN Total_Numbers_In_Binary_Count_Group > 0
                THEN ROUND((Total_Numbers_In_Binary_Count_Group * 30.0) / 60, 2)
                ELSE 0
            END ASC) AS RowNum
    FROM Test_DB.dbo.Short_Operation_Result
    WHERE Total_Numbers_In_Binary_Count_Group > 0
)
INSERT INTO Test_DB.dbo.Short_Operation_Final_Transpose ([Location], [Short_Operation-1], [Short_Operation-2], [Short_Operation-3])
SELECT 
    [Location],
    MAX(CASE WHEN RowNum = 1 THEN Total_Hours END) AS [Short_Operation-1],
    MAX(CASE WHEN RowNum = 2 THEN Total_Hours END) AS [Short_Operation-2],
    MAX(CASE WHEN RowNum = 3 THEN Total_Hours END) AS [Short_Operation-3]
FROM RankedResults
WHERE RowNum <= 3
GROUP BY [Location]
ORDER BY [Location];

SELECT * FROM Test_DB.dbo.Short_Operation_Final_Transpose


*/

/*
--------------------------------------------------------------------------------------------------
-- Creating Table for Short Operation
--------------------------------------------------------------------------------------------------

CREATE TABLE Test_DB.dbo.Short_Operation_Result (
    Date_U FLOAT,                         -- Column Date_U as FLOAT (same as #FinalResult)
    Hours FLOAT,                          -- Column Hours as FLOAT
    Location NVARCHAR(510),               -- Column Location as NVARCHAR
    Value FLOAT,                          -- Column Value as FLOAT
    Binary_Value INT,                     -- Column Binary_Value as INT
    Binary_Count BIGINT,                  -- Column Binary_Count as BIGINT
    Total_Numbers_In_Binary_Count_Group BIGINT,  -- Column Total_Numbers_In_Binary_Count_Group as BIGINT
    Total_Hours DECIMAL(10, 2)            -- Column Total_Hours as DECIMAL with 2 decimal places
);


CREATE TABLE Test_DB.dbo.Short_Operation_Final_Result (
    Location NVARCHAR(255),  -- Use NVARCHAR for Japanese and other non-Latin characters
    Total_Hours DECIMAL(10, 2)  -- Decimal for storing hours, with 2 decimal points
);

CREATE TABLE Test_DB.dbo.Short_Operation_Final_Transpose (
    [Location] VARCHAR(255),  -- Adjust the size if necessary
    [Short_Operation-1] DECIMAL(10, 2),
    [Short_Operation-2] DECIMAL(10, 2),
    [Short_Operation-3] DECIMAL(10, 2)
);




--------------------------------------------------------------------------------------------------
-- Insert data inside Short Operation Table
--------------------------------------------------------------------------------------------------

INSERT INTO Test_DB.dbo.Short_Operation_Result (
    Date_U,
    Hours,
    Location,
    Value,
    Binary_Value,
    Binary_Count,
    Total_Numbers_In_Binary_Count_Group,
    Total_Hours
)
SELECT  
    [Date_U],  
    [Hours],  
    [Location],  
    [Value],  
    [Binary_Value],  
    [Binary_Count],  
    [Total_Numbers_In_Binary_Count_Group],  
    [Total_Hours]  
FROM #FinalResult;


select * from Test_DB.dbo.Short_Operation_Result
ORDER BY [Location], [Date_U], [Hours];

--------------------------------------------------------------



*/