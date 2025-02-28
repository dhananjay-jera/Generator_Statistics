INSERT INTO Test_DB.dbo.Locations (Location)
SELECT Location
FROM [dbo].[Generators_Data]
GROUP BY Location;

-------------------------------------
--Creating table
-------------------------------------
CREATE TABLE Test_DB.dbo.Locations (
    Location NVARCHAR(255) -- Use NVARCHAR to support Unicode characters (Japanese, etc.)
);

-------------------------------------
--Inserting Data 
-------------------------------------


INSERT INTO Test_DB.dbo.Locations (Location)
SELECT Location
FROM [dbo].[Generators_Data]
GROUP BY Location;
