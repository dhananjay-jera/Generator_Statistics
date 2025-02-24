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
 --   FROM #TempTable
),
RunningCount AS (
    SELECT
        * ,
        -- Create a resettable count that restarts at 1 when Binery_Value = 1 after 0
        SUM(CASE WHEN Binery_Value = 0 THEN 1 ELSE 0 END)
        OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours] ROWS UNBOUNDED PRECEDING) AS ResetGroup
    FROM CTE
),
SelectedValues AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        [Value],
        Binery_Value,
        -- Updated logic to count 1 to 3 and reset to 0
        CASE
            WHEN Binery_Value = 1 THEN
                  CASE
                        WHEN ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U] DESC, [Hours] DESC) <= 2
                        THEN ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U] DESC, [Hours] DESC)
                        ELSE 0
                  END
                        ELSE 0
            END AS Binery_Count,
        -- Add logic to set Updated_Column based on Binery_Count 1 or 2
        CASE
            WHEN Binery_Value = 1 AND
                      ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U] DESC, [Hours] DESC) <= 2
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
        Binery_Value,
        Binery_Count,
        Selected_Value,
        LEAD(Binery_Count) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Next_Binery_Count,
        -- Retrieve the Selected_Value of the next row for when Binery_Count is 2
        LEAD(Selected_Value) OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS Next_Selected_Value
    FROM SelectedValues
)
-- Final output with filtered results and added logic for Final_Value
SELECT
    [Date_U],
    [Hours],
    [Location],
    [Value],
    Binery_Value,
    Binery_Count,
    Selected_Value,
    -- Only add to Final_Value if the current row has Binery_Count 1 and the next row has Binery_Count 2
 CASE
        WHEN  Binery_Count = 2 AND Next_Binery_Count = 1 THEN
            ROUND((Selected_Value + Next_Selected_Value) / 60.0, 2)  -- Add both the current and next Selected_Value and round to 2 decimal places
        ELSE 0
    END AS Final_Value_Mega_Watt_Per_Minute
INTO #Ramp_Down_Final  --
FROM FilteredValues
ORDER BY [Location], [Date_U] , [Hours];





------------------------------------------------------------------------------
-- QUERY RESULT AND CHECK OUTPUT 
-------------------------------------------------------------------------------
SELECT * FROM [dbo].[RampDown_Result]
ORDER BY [Location], [Date_U], [Hours];

---------------------------------------------------------

SELECT * FROM [dbo].[RampDown_Result]
WHERE Binery_Count IN (1, 2, 3)
ORDER BY [Location], [Date_U], [Hours];

---------------------------------------------------------

WITH RankedResults AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Final_Value_Mega_Watt_Per_Minute DESC) AS RowNum
    FROM Test_DB.dbo.RampDown_Result
)
SELECT *
FROM RankedResults  -- Use RankedResults instead of RampDown_Result
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
    FROM Test_DB.dbo.RampDown_Result
)
SELECT 
    [Location], 
    Final_Value_Mega_Watt_Per_Minute
FROM RankedResults
WHERE RowNum = 1
ORDER BY [Location], Final_Value_Mega_Watt_Per_Minute DESC;





/*
=============================================================================
-- Finding DataType -- 
=============================================================================
SELECT name AS COLUMN_NAME, 
       TYPE_NAME(user_type_id) AS DATA_TYPE
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..##Ramp_Down_Final');

EXEC tempdb.sys.sp_help '#Ramp_Down_Final';

--------------------------------------------------------------------------------------------------
-- Creating Table for Ramp Down Table 
--------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'RampDown_Result')
BEGIN
    CREATE TABLE Test_DB.dbo.RampDown_Result (
        Date_U FLOAT,
        Hours FLOAT,
        Location NVARCHAR(510),
        Value FLOAT,
        Binery_Value INT,
        Binery_Count BIGINT,
        Selected_Value FLOAT,
        Final_Value_Mega_Watt_Per_Minute FLOAT
    );
END;




--------------------------------------------------------------------------------------------------
-- Insert data inside Short Operation Table
--------------------------------------------------------------------------------------------------

INSERT INTO Test_DB.dbo.RampDown_Result
    (Date_U, Hours, Location, Value, Binery_Value, Binery_Count, Selected_Value, Final_Value_Mega_Watt_Per_Minute)
SELECT 
    Date_U,
    Hours,
    Location,
    Value,
    Binery_Value,
    Binery_Count,
    Selected_Value,
    Final_Value_Mega_Watt_Per_Minute
FROM #Ramp_Down_Final;
