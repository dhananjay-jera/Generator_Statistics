		-------------------------------------------------------------------------
		------ Non Stop working Generators List (Non_Stop_Woerking Generators List) -------
    	-------------------------------------------------------------------------
SELECT 
    [Location]
FROM 
    [dbo].[Generators_Data]
GROUP BY 
    [Location]
HAVING 
    SUM(CASE WHEN [Value] = 0 THEN 1 ELSE 0 END) = 0  -- Ensures no 0 values exist for that location
ORDER BY 
    [Location];