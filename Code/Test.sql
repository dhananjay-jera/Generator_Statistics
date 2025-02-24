SELECT 
    [Location],
    SUM([Value]) AS TotalValue
FROM 
    [Test_DB].[dbo].[Generators_Data]
GROUP BY 
    [Location]
ORDER BY 
    [TotalValue] DESC;


    ===========================================
