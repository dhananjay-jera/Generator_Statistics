/*
SELECT * INTO #TempTable 
FROM [Test_DB].[dbo].[Generators_Data]
WHERE [Location] LIKE N'%–kŠC“¹_–kŠC“¹“d—Í_…—Í_VŠ¥_–k“d_VŠ¥1%' 
   OR [Location] LIKE N'%–kŠC“¹_–kŠC“¹“d—Í_…—Í_VŠ¥_–k“d_VŠ¥2%' ;
*/

WITH CTE AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        [Value],
        CASE
            WHEN [Value] > 1 THEN 1  -- Binery_Value = 1 if Value > 1, else 0
            ELSE 0
        END AS Binery_Value
    FROM [Test_DB].[dbo].[Generators_Data]
   -- FROM #TempTable
),
RunningCount AS (
    SELECT
        * ,
        -- Create a resettable count that restarts at 1 when Binery_Value = 0 after 1
        SUM(CASE WHEN Binery_Value = 0 THEN 1 ELSE 0 END)
        OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours] ROWS UNBOUNDED PRECEDING) AS ResetGroup
    FROM CTE
),
FilteredValues AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binery_Value,
        -- Use LAG to get the previous row's Value partitioned by Location
        LAG([Value]) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Prev_Value
    FROM RunningCount
)
-- Final output with subtraction of current Value and previous Value
SELECT
    [Date_U],
    [Hours],
    [Location],
    [Value],
    Binery_Value,
    -- Subtract the current Value from the previous row's Value to get Ramp_UP
    CASE
        WHEN Prev_Value IS NOT NULL AND [Value] - Prev_Value > 0 THEN [Value] - Prev_Value
        ELSE 0
    END AS Ramp_UP,
    -- If the subtraction is negative, move it to Ramp_Down
    CASE
        WHEN Prev_Value IS NOT NULL AND [Value] - Prev_Value <= 0 THEN [Value] - Prev_Value
        ELSE 0
    END AS Ramp_Down
INTO #Ramp_Down_Final  -- Final table output
FROM FilteredValues
ORDER BY [Location], [Date_U], [Hours];








-- drop table #Ramp_Down_Final


------------------------------------------------------------------------------
-- QUERY RESULT AND CHECK OUTPUT 
-------------------------------------------------------------------------------
SELECT * FROM #Ramp_Down_Final
ORDER BY Ramp_Down;


SELECT * FROM #Ramp_Down_Final
ORDER BY Ramp_UP DESC;



SELECT * FROM #Ramp_Down_Final
ORDER BY [Location], [Date_U], [Hours];

---------------------------------------------------------
-- Ramp UP by Location
---------------------------------------------------------

WITH RankedResults AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binery_Value,
        Ramp_UP,
        Ramp_Down,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Ramp_UP DESC) AS RowNum
    FROM [dbo].[Ramp_Up_Down_Result]
)
SELECT
    [Date_U],
    [Hours],
    [Location],
    [Value],
    Binery_Value,
    Ramp_UP,
    Ramp_Down
FROM RankedResults
WHERE RowNum = 1
ORDER BY Ramp_UP DESC;

--------------------------------------------------------------------
-- Ramp Down by Location
--------------------------------------------------------------------
WITH RankedResults AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binery_Value,
        Ramp_UP,
        Ramp_Down,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Ramp_Down ASC) AS RowNum
    FROM [dbo].[Ramp_Up_Down_Result]
)
SELECT
    [Location],
    Ramp_Down
FROM RankedResults
WHERE RowNum = 1
ORDER BY Ramp_Down ASC;





---------------------------------------------------------




--------------------------------------------------------------------------------
-- QUERY RESULT AND Display [Location], Final_Value_Mega_Watt_Per_Minute
-------------------------------------------------------------------------------






/*
=============================================================================
-- Finding DataType -- 
=============================================================================
SELECT name AS COLUMN_NAME, 
       TYPE_NAME(user_type_id) AS DATA_TYPE
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..##Ramp_Down_Final');

EXEC tempdb.sys.sp_help '#Ramp_Down_Final';

EXEC sp_help 'dbo.#Short_Stopage_FinalResult';
--------------------------------------------------------------------------------------------------
-- Creating Table for Ramp Down Table 
--------------------------------------------------------------------------------------------------
CREATE TABLE Test_DB.dbo.Ramp_Up_Down_Result (
    Date_U FLOAT,
    Hours FLOAT,
    Location NVARCHAR(510),
    Value FLOAT,
    Binery_Value INT,
    Ramp_UP FLOAT,
    Ramp_Down FLOAT
);



--------------------------------------------------------------------------------------------------
-- Insert data inside Short Operation Table
--------------------------------------------------------------------------------------------------
-- Check for rows with invalid data in the Value column
INSERT INTO Test_DB.dbo.Ramp_Up_Down_Result (Date_U, Hours, Location, Value, Binery_Value, Ramp_UP, Ramp_Down)
SELECT Date_U, Hours, Location, Value, Binery_Value, Ramp_UP, Ramp_Down
FROM #Ramp_Down_Final;





-----------------------------------


WITH RankedResults AS (
    SELECT
        TRY_CAST([Date_U] AS DATETIME) AS Date_U,  -- Safely cast Date_U to DATETIME
        [Hours],
        [Location],
        TRY_CAST([Value] AS FLOAT) AS Value,      -- Safely cast Value to FLOAT
        Binery_Value,
        TRY_CAST(Ramp_UP AS FLOAT) AS Ramp_UP,    -- Safely cast Ramp_UP to FLOAT
        TRY_CAST(Ramp_Down AS FLOAT) AS Ramp_Down, -- Safely cast Ramp_Down to FLOAT
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Ramp_Down ASC) AS RowNum
    FROM #Ramp_Down_Final
)
INSERT INTO Test_DB.dbo.Ramp_Down_Up_Result
SELECT
    Date_U,   -- If Date_U is invalid, it will be NULL
    [Hours],
    [Location],
    Value,    -- If Value is invalid, it will be NULL
    Binery_Value,
    Ramp_UP,  -- If Ramp_UP is invalid, it will be NULL
    Ramp_Down -- If Ramp_Down is invalid, it will be NULL
FROM RankedResults
WHERE RowNum = 1;




