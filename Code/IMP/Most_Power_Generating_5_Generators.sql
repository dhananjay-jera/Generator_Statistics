----------------------------------------------------------------------------------------------
	------ Most Power Generating 5 Generators (Most_Power_Generating_Top_5_Generators) -------
----------------------------------------------------------------------------------------------
SELECT TOP 5
    [Location], 
    SUM([Value]) AS TotalGeneration 
FROM 
    [dbo].[Generators_Data]
GROUP BY 
    [Location]
ORDER BY
    [TotalGeneration] DESC;
	   