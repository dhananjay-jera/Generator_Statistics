SELECT TOP 5
    [Location], 
    SUM([Value]) AS TotalGeneration 
FROM 
    [dbo].[Generators_Data]
GROUP BY 
    [Location]
ORDER BY
    [TotalGeneration] DESC;