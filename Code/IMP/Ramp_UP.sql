/*
===============================================================================
-- Script Name      : <RampUP.sql>
-- Description      : <Its gives information about Max Ramp Up Rate>
-- Author           : <Dhananjay Awachat (Jay)>
-- Date Created     : <20250220>
-- Last Modified    : <20250220>
-- Modification History:
--   - <Date> - <Description of changes made>

===============================================================================
*/
-- Step 1: Create a Common Table Expression (CTE) to classify values as binary (1 or 0) based on a threshold
WITH CTE AS (
    SELECT
        [Date_U],        -- Date column
        [Hours],         -- Hourly data
        [Location],      -- Location of the generator
        [Value],         -- Actual value recorded
        -- Determine if the value is greater than 1 (set to 1) or not (set to 0)
        CASE 
            WHEN [Value] > 1 THEN 1  -- Binary_Value = 1 if Value > 1, else 0
            ELSE 0
        END AS Binery_Value
    FROM [Test_DB].[dbo].[Generators_Data]  -- Use actual database table
),

-- Step 2: Generate a resettable group count whenever Binery_Value switches from 0 to 1
RunningCount AS (
    SELECT 
        *, 
        -- Create a grouping ID that increments whenever Binery_Value changes from 0 to 1
        SUM(CASE WHEN Binery_Value = 0 THEN 1 ELSE 0 END) 
        OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours] ROWS UNBOUNDED PRECEDING) AS ResetGroup
    FROM CTE
),

-- Step 3: Assign row numbers to each sequence of Binery_Value = 1 within its ResetGroup
SelectedValues AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binery_Value,
        -- Count occurrences of Binery_Value = 1 (reset at every new group)
        CASE 
            WHEN Binery_Value = 1 THEN 
                CASE 
                    WHEN ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U], [Hours]) <= 4 
                    THEN ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U], [Hours]) - 1
                    ELSE 0 
                END
            ELSE 0 
        END AS Binery_Count,
        -- Store selected values when Binery_Count is 1 or 2
        CASE 
            WHEN Binery_Value = 1 
                 AND ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U], [Hours]) <= 4 
            THEN [Value]
            ELSE 0
        END AS Selected_Value
    FROM RunningCount
),

-- Step 4: Calculate Previous and Next Values
FilteredValues AS (
    SELECT 
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binery_Value,
        Binery_Count,
        Selected_Value,
        -- Get the previous row's Binery_Value to check transitions from 0 to 1
        LAG(Binery_Value) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Previous_Binery_Value,
        -- Get the next row's Binery_Count
        LEAD(Binery_Count) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Next_Binery_Count,
        -- Get the next row's Selected_Value
        LEAD(Selected_Value) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Next_Selected_Value
    FROM SelectedValues
),

-- Step 5: Compute Next-to-Next Selected Value
FilteredValuesFinal AS (
    SELECT *,
        -- Compute the value after the next row
        LEAD(Next_Selected_Value) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS NextTo_Next_Selected_Value
    FROM FilteredValues
)

-- Step 6: Compute Final Value and store it in a temporary table
SELECT 
    [Date_U],
    [Hours],
    [Location],
    [Value],
    Binery_Value,
    Binery_Count,
    Selected_Value,
    -- Compute Final_Value_Mega_Watt_Per_Minute based on certain conditions
    CASE 
        WHEN Previous_Binery_Value = 0 
             AND Binery_Count = 1 
             AND Next_Binery_Count = 2  
        THEN ROUND((Selected_Value + Next_Selected_Value + NextTo_Next_Selected_Value) / 90, 2) 
        ELSE 0
    END AS Final_Value_Mega_Watt_Per_Minute
INTO #Ramp_Up_Final  -- Store the final results in a temporary table
FROM FilteredValuesFinal  
ORDER BY [Location], [Date_U], [Hours]; -- Sort results by location and time





-- DROP TABLE #Ramp_Up_Final



SELECT * FROM Test_DB.dbo.RampUP_Result
WHERE Binery_Count IN (1, 2, 3)
ORDER BY [Location], [Date_U], [Hours];


------------------------------------------------------------------------------
-- QUERY RESULT AND CHECK only one highest record from Location
-------------------------------------------------------------------------------

WITH RankedResults AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Final_Value_Mega_Watt_Per_Minute DESC) AS RowNum
    FROM Test_DB.dbo.RampUP_Result
)
SELECT *
FROM RankedResults
WHERE RowNum = 1
ORDER BY [Location], Final_Value_Mega_Watt_Per_Minute DESC;


--------------------------------------------------------------------------------
-- QUERY RESULT AND Display [Location], Final_Value_Mega_Watt_Per_Minute
-------------------------------------------------------------------------------

WITH RankedResults AS (
    SELECT 
        [Location],
        Final_Value_Mega_Watt_Per_Minute,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Final_Value_Mega_Watt_Per_Minute DESC) AS RowNum
    FROM Test_DB.dbo.RampUP_Result
)
SELECT 
    [Location], 
    Final_Value_Mega_Watt_Per_Minute
FROM RankedResults
WHERE RowNum = 1
ORDER BY [Location], Final_Value_Mega_Watt_Per_Minute DESC;






-- DROP TABlE #Ramp_Up_Final

        -- Row number function to rank each row partitioned by Location, ordered by Final_Value_Mega_Watt_Per_Minute in descending order
    --    ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Final_Value_Mega_Watt_Per_Minute DESC) AS RowNum
    ------------------------------------------------------------------------------

--- SELECT * FROM Test_DB.dbo.RampUP_Result
--- WHERE Binery_Count IN (1, 2, 3)
--- ORDER BY [Location], [Date_U], [Hours];


/*
=============================================================================
-- Finding DataType -- 
=============================================================================

SELECT name AS COLUMN_NAME, 
       TYPE_NAME(user_type_id) AS DATA_TYPE
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..#Ramp_Up_Final');


EXEC sp_help 'Test_DB.dbo.Generators_Data'; --

EXEC sp_help 'Test_DB.dbo.Short_Operation_Result'; --




--------------------------------------------------------------------------------------------------
-- Creating Table for Short Operation
--------------------------------------------------------------------------------------------------

CREATE TABLE Test_DB.dbo.RampUP_Result (
    Date_U FLOAT,                          -- Column Date_U as FLOAT
    Hours FLOAT,                           -- Column Hours as FLOAT
    Location NVARCHAR(510),                -- Column Location as NVARCHAR
    Value FLOAT,                           -- Column Value as FLOAT
    Binery_Value INT,                      -- Column Binery_Value as INT (fixed spelling)
    Binery_Count BIGINT,                   -- Column Binery_Count as BIGINT (fixed spelling)
    Selected_Value FLOAT,                  -- Column Selected_Value as FLOAT
    Final_Value_Mega_Watt_Per_Minute FLOAT -- Column Final_Value_Mega_Watt_Per_Minute as FLOAT
);


--------------------------------------------------------------------------------------------------
-- Insert data inside Short Operation Table
--------------------------------------------------------------------------------------------------

INSERT INTO Test_DB.dbo.RampUP_Result (
    Date_U,
    Hours,
    Location,
    Value,
    Binery_Value,                          -- Fixed spelling here
    Binery_Count,                          -- Fixed spelling here
    Selected_Value,
    Final_Value_Mega_Watt_Per_Minute
)
SELECT  
    [Date_U],  
    [Hours],  
    [Location],  
    [Value],  
    [Binery_Value],                        -- Fixed spelling here
    [Binery_Count],                        -- Fixed spelling here
    [Selected_Value],  
    [Final_Value_Mega_Watt_Per_Minute]  
FROM #Ramp_Up_Final;



*/