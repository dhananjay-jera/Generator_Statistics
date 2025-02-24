
WITH NumberedRows AS (
    SELECT
        [Day],
        [Hours],
        [Location],
        [Value],
        CASE 
            WHEN [Value] = 0 THEN 1  -- Binery_Value = 1 for Value = 0, else 0
            ELSE 0
        END AS Binery_Value,
        ROW_NUMBER() OVER (PARTITION BY [Location] ORDER BY [Day], [Hours]) AS RowNum,

        -- GroupId resets whenever a non-zero value appears
        SUM(CASE 
                WHEN [Value] != 0 THEN 1  -- Start a new group when there's a non-zero value
                ELSE 0
            END) OVER (PARTITION BY [Location] ORDER BY [Day], [Hours] ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS GroupId
    FROM 
       -- #TempTable  -- Temporary table
       [Test_DB].[dbo].[Generators_Data]

),
WithGroup AS (
    SELECT
        nr.*,
        -- Calculate Binery_Total per GroupId, reset for each new sequence of consecutive zeros
        SUM(CASE 
                WHEN nr.Binery_Value = 1 THEN 1
                ELSE 0
            END) OVER (PARTITION BY nr.[Location], nr.GroupId ORDER BY nr.RowNum ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Binery_Total
    FROM NumberedRows nr
)

-- SELECT TOP 5
SELECT 
    [Day],
    [Hours],
    [Location],
    [Value],
    Binery_Value,
    -- Display Binery_Total only at the last 0 in a sequence of 0's, reset when encountering a non-zero value
    CASE 
        WHEN Binery_Value = 1 AND (
            LEAD(Binery_Value) OVER (PARTITION BY [Location] ORDER BY [Day], [Hours]) = 0 
            OR LEAD(Binery_Value) OVER (PARTITION BY [Location] ORDER BY [Day], [Hours]) IS NULL
        )
        THEN Binery_Total  -- Show total when sequence of zeros ends
        ELSE 0
    END AS Binery_Total
FROM WithGroup
-- ORDER BY Binery_Total DESC;
ORDER BY [Location],[DAY],[HOURS];