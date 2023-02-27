/* Union results from [year]_data tables */

WITH master_data AS
	(
	SELECT * FROM dbo.[2018_data]
	UNION
	SELECT * FROM dbo.[2019_data]
	UNION
	SELECT * FROM dbo.[2020_data]
	)


/* Create temp table from union statements */

SELECT * INTO #master_data FROM master_data

/* 1. Is hotel revenue growing by year? */

SELECT
	arrival_date_year,
	/* In most cases, hotels allow children under a certain
	   age to stay for free. Since we cannot determine the
	   age of children in the data, they are excluded from
	   calculation*/
	FORMAT(SUM(((stays_in_week_nights + stays_in_weekend_nights)*adr)*adults), 'C') AS [Revenue]
FROM 
	#master_data
GROUP BY
	arrival_date_year
ORDER BY 
	arrival_date_year

/* 2. Revenue by year and hotel type */

SELECT
	arrival_date_year,
	hotel,
	FORMAT(SUM(((stays_in_week_nights + stays_in_weekend_nights)*adr)*adults), 'C') AS [Revenue]
FROM 
	#master_data
GROUP BY
	arrival_date_year, hotel
ORDER BY hotel, arrival_date_year


/* -- Join market_segment data and meals data onto master_data list
   -- Create master query for Power BI integration*/

WITH master_data AS
	(
	SELECT * FROM dbo.[2018_data]
	UNION
	SELECT * FROM dbo.[2019_data]
	UNION
	SELECT * FROM dbo.[2020_data]
	)

SELECT 
	md.*,
	ms.Discount,
	mc.*
FROM 
	master_data md
LEFT JOIN dbo.market_segment ms
	ON md.market_segment = ms.market_segment
LEFT JOIN dbo.meal_cost mc
	ON mc.meal = md.meal