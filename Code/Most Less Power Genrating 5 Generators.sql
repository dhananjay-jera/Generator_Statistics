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