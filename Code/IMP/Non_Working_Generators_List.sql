		-------------------------------------------------------------------------
		------ Non working Generators List (Non Woerking Generators List) -------
    	-------------------------------------------------------------------------
SELECT 
    [Location], 
    SUM([Value]) AS TotalGeneration
FROM 
    [dbo].[Generators_Data]
GROUP BY 
    [Location]
HAVING 
    SUM([Value]) = 0  -- Filters locations with total generation greater than 0
ORDER BY 
    [Location] ;  -- Orders by TotalGeneration in descending order
