-- SELECT * INTO #TempTable 
-- FROM [Test_DB].[dbo].[Generators_Data]
-- WHERE [Location] LIKE N'%–kŠC“¹_–kŠC“¹“d—Í_…—Í_VŠ¥_–k“d_VŠ¥1%' 
--    OR [Location] LIKE N'%–kŠC“¹_–kŠC“¹“d—Í_…—Í_VŠ¥_–k“d_VŠ¥2%' ;


WITH CTE AS (
    SELECT [Date_U], [Hours], [Location], [Value],
        CASE WHEN [Value] = 0 THEN 1 ELSE 0 END AS Binary_Value
    -- FROM #TempTable
    FROM [dbo].[Generators_Data]

),
RunningCount AS (
    SELECT *, 
        SUM(CASE WHEN Binary_Value = 0 THEN 1 ELSE 0 END) 
        OVER (PARTITION BY [Location] ORDER BY [Date_U], [Hours]) AS ResetGroup
    FROM CTE
),
SelectedValues AS (
    SELECT [Date_U], [Hours], [Location], [Value], Binary_Value, ResetGroup,
        CASE WHEN Binary_Value = 1 
            THEN ROW_NUMBER() OVER (PARTITION BY [Location], ResetGroup ORDER BY [Date_U], [Hours]) -1
            ELSE 0 
        END AS Binary_Count
    FROM RunningCount
)
SELECT [Date_U], [Hours], [Location], [Value], Binary_Value, Binary_Count,
    CASE WHEN Binary_Count = 1 THEN MAX(Binary_Count) OVER (PARTITION BY [Location], ResetGroup) ELSE 0 END AS Short_Stopage,
    CASE WHEN Binary_Count = 1 
         THEN ROUND(CAST(MAX(Binary_Count) OVER (PARTITION BY [Location], ResetGroup) AS FLOAT) / 2, 2) 
         ELSE 0 
    END AS Short_Stopage_Hours
INTO #Short_Stopage_FinalResult
FROM SelectedValues
ORDER BY [Location], [Date_U], [Hours];




---- EXEC sp_help 'dbo.#Short_Stopage_FinalResult'; --



-------------------------------------------------------------------------
Finding Data types
-------------------------------------------------------------------------

/*
SELECT name AS COLUMN_NAME, 
       TYPE_NAME(user_type_id) AS DATA_TYPE
FROM tempdb.sys.columns
WHERE object_id = OBJECT_ID('tempdb..#Short_Stopage_FinalResult');
*/




-- Drop table #Short_Stopage_FinalResult

-- select * from #Short_Stopage_FinalResult

--------------------------------------------------------------------------------------------------
-- Creating Table for Short Operation
--------------------------------------------------------------------------------------------------
CREATE TABLE Test_DB.dbo.Short_Stopage_Result (
    Date_U FLOAT,
    Hours FLOAT,
    Location NVARCHAR(510),
    Value FLOAT,
    Binary_Value INT,
    Binary_Count BIGINT,
    Short_Stopage BIGINT,
    Short_Stopage_Hours FLOAT
);


SELECT * from Test_DB.dbo.Short_Stopage_Result


--------------------------------------------------------------------------------------------------
-- Insert data inside Short Operation Table
--------------------------------------------------------------------------------------------------

INSERT INTO Test_DB.dbo.Short_Stopage_Result (
    Date_U,
    Hours,
    Location,
    Value,
    Binary_Value,
    Binary_Count,
    Short_Stopage,
    Short_Stopage_Hours
)
SELECT 
    Date_U,
    Hours,
    Location,
    Value,
    Binary_Value,
    Binary_Count,
    Short_Stopage,
    Short_Stopage_Hours
FROM #Short_Stopage_FinalResult;

-------------------------------
-- Query:- 
-------------------------------

SELECT count (*) FROM [dbo].[Short_Stopage_Result]

SELECT * 
FROM [dbo].[Short_Stopage_Result]
WHERE [Binary_Count] > 0
ORDER BY  [Location], [Date_U], [Hours] ;


--------------------------------------------------------------------------------------------------
-- Query Group by Location :- 
--------------------------------------------------------------------------------------------------

WITH RankedResults AS (
    SELECT
        [Date_U],
        [Hours],
        [Location],
        [Value],
        [Binary_Value],
        [Binary_Count],
        [Short_Stopage],
        Short_Stopage_Hours,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Short_Stopage_Hours) AS RowNum
    FROM Test_DB.dbo.Short_Stopage_Result
    WHERE Short_Stopage_Hours > 0  -- Only consider records where Short_Stopage_Time > 0
)
SELECT 
    [Date_U],
    [Hours],
    [Location],
    [Value],
    [Binary_Value],
    [Binary_Count],
    [Short_Stopage],
    Short_Stopage_Hours
FROM RankedResults
WHERE RowNum <= 3  -- Select top 3 records for each Location
ORDER BY [Location], Short_Stopage_Hours DESC;



------------------------------------------------------------------------------
Only two Columns are display [Location] Short_Stopage_Hours
------------------------------------------------------------------------------

WITH RankedResults AS (
    SELECT
        [Location],
        Short_Stopage_Hours,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY Short_Stopage_Hours) AS RowNum
    FROM Test_DB.dbo.Short_Stopage_Result
    WHERE Short_Stopage_Hours > 0  -- Only consider records where Short_Stopage_Hours > 0
)
SELECT 
    [Location], 
    Short_Stopage_Hours
FROM RankedResults
WHERE RowNum <= 3  -- Select top 3 records for each Location
ORDER BY [Location], Short_Stopage_Hours DESC;




