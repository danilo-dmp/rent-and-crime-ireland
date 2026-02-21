/* =====================================================
   IRELAND RENT vs CRIME ANALYSIS (2020–2025)
   Database: MySQL
   Author: Danilo Pereira
   ===================================================== */


/* =====================================================
   1. DATABASE SETUP
   ===================================================== */

CREATE DATABASE ireland_analysis;
USE ireland_analysis;


/* =====================================================
   2. BASE TABLES
   ===================================================== */
-- Store yearly aggregated crime data per Garda division (imported from cleaned CSV)

CREATE TABLE crime_data (
	garda_division VARCHAR(100),
    year INT,
    total_crime INT
);


-- Store yearly average rent per county
CREATE TABLE rent_data (
	county VARCHAR(100),
    year INT,
    avg_rent DECIMAL (10,2)
);


/* =====================================================
   3. MAP GARDA DIVISIONS TO REGIONS
   ===================================================== */

-- Create mapping table to align Garda divisions with analytical regions
-- Necessary because crime and rent datasets use different geographic granularity
CREATE TABLE division_to_region (
    garda_division VARCHAR(255),
    region VARCHAR(100)
);

/* Insert Dublin divisions */
INSERT INTO division_to_region VALUES
('D.M.R. Eastern Garda Division', 'Dublin'),
('D.M.R. North Central Garda Division', 'Dublin'),
('D.M.R. Northern Garda Division', 'Dublin'),
('D.M.R. South Central Garda Division', 'Dublin'),
('D.M.R. Southern Garda Division', 'Dublin'),
('D.M.R. Western Garda Division', 'Dublin');


/* Insert Cork divisions */
INSERT INTO division_to_region VALUES
('Cork City Garda Division', 'Cork'),
('Cork North Garda Division', 'Cork'),
('Cork West Garda Division', 'Cork');

/* Insert remaining single-county regions */
INSERT INTO division_to_region VALUES
('Clare Garda Division', 'Clare'),
('Donegal Garda Division', 'Donegal'),
('Galway Garda Division', 'Galway'),
('Kerry Garda Division', 'Kerry'),
('Kildare Garda Division', 'Kildare'),
('Limerick Garda Division', 'Limerick'),
('Louth Garda Division', 'Louth'),
('Mayo Garda Division', 'Mayo'),
('Meath Garda Division', 'Meath'),
('Tipperary Garda Division', 'Tipperary'),
('Waterford Garda Division', 'Waterford'),
('Westmeath Garda Division', 'Westmeath'),
('Wexford Garda Division', 'Wexford'),
('Wicklow Garda Division', 'Wicklow');

/* Insert multi-county divisions */
INSERT INTO division_to_region VALUES
('Cavan/Monaghan Garda Division', 'Cavan/Monaghan'),
('Kilkenny/Carlow Garda Division', 'Kilkenny/Carlow'),
('Laois/Offaly Garda Division', 'Laois/Offaly'),
('Roscommon/Longford Garda Division', 'Roscommon/Longford'),
('Sligo/Leitrim Garda Division', 'Sligo/Leitrim');


/* =====================================================
   4. BUILD RENT DATA BY REGION
   ===================================================== */

CREATE TABLE rent_by_region AS

SELECT 
    county AS region,
    year,
    avg_rent
FROM rent_data
WHERE county NOT IN (
    'Cavan','Monaghan',
    'Kilkenny','Carlow',
    'Laois','Offaly',
    'Roscommon','Longford',
    'Sligo','Leitrim'
)

UNION ALL

SELECT 
    'Cavan/Monaghan' AS region,
    year,
    AVG(avg_rent) AS avg_rent
FROM rent_data
WHERE county IN ('Cavan','Monaghan')
GROUP BY year

UNION ALL

SELECT 
    'Kilkenny/Carlow' AS region,
    year,
    AVG(avg_rent) AS avg_rent
FROM rent_data
WHERE county IN ('Kilkenny','Carlow')
GROUP BY year

UNION ALL

SELECT 
    'Laois/Offaly' AS region,
    year,
    AVG(avg_rent) AS avg_rent
FROM rent_data
WHERE county IN ('Laois','Offaly')
GROUP BY year

UNION ALL

SELECT 
    'Roscommon/Longford' AS region,
    year,
    AVG(avg_rent) AS avg_rent
FROM rent_data
WHERE county IN ('Roscommon','Longford')
GROUP BY year

UNION ALL

SELECT 
    'Sligo/Leitrim' AS region,
    year,
    AVG(avg_rent) AS avg_rent
FROM rent_data
WHERE county IN ('Sligo','Leitrim')
GROUP BY year;



/* =====================================================
   5. FINAL ANALYTICAL DATASET
   ===================================================== */
CREATE TABLE rent_crime_analysis AS
SELECT 
    r.region,
    r.year,
    r.avg_rent,
    c.total_crime
FROM rent_by_region r
JOIN (
    SELECT 
        d.region,
        c.year,
        SUM(c.total_crime) AS total_crime
    FROM crime_data c
    JOIN division_to_region d
        ON c.garda_division = d.garda_division
    GROUP BY d.region, c.year
) c
ON r.region = c.region
AND r.year = c.year;

SELECT 
    region,
    ROUND(AVG(avg_rent), 2) AS avg_rent_2020_2025
FROM rent_crime_analysis
GROUP BY region
ORDER BY avg_rent_2020_2025 DESC;


SELECT 
    region,
    ROUND(AVG(total_crime), 0) AS avg_crime_2020_2025
FROM rent_crime_analysis
GROUP BY region
ORDER BY avg_crime_2020_2025 DESC;


/* =====================================================
   6. GROWTH ANALYSIS (2020–2025)
   ===================================================== */
   
   -- rent growth
SELECT 
    region,
    MAX(CASE WHEN year = 2020 THEN avg_rent END) AS rent_2020,
    MAX(CASE WHEN year = 2025 THEN avg_rent END) AS rent_2025,
    ROUND(
        (
            MAX(CASE WHEN year = 2025 THEN avg_rent END) -
            MAX(CASE WHEN year = 2020 THEN avg_rent END)
        )
        /
        MAX(CASE WHEN year = 2020 THEN avg_rent END)
        * 100, 2
    ) AS rent_growth_pct
FROM rent_crime_analysis
GROUP BY region
ORDER BY rent_growth_pct DESC;

-- crime growth
SELECT 
    region,
    MAX(CASE WHEN year = 2020 THEN total_crime END) AS crime_2020,
    MAX(CASE WHEN year = 2025 THEN total_crime END) AS crime_2025,
    ROUND(
        (
            MAX(CASE WHEN year = 2025 THEN total_crime END) -
            MAX(CASE WHEN year = 2020 THEN total_crime END)
        )
        /
        MAX(CASE WHEN year = 2020 THEN total_crime END)
        * 100, 2
    ) AS crime_growth_pct
FROM rent_crime_analysis
GROUP BY region
ORDER BY crime_growth_pct DESC;


-- ============================================
-- Key Findings from SQL Analysis
-- ============================================
-- 1. Dublin, Wicklow, and Kildare have the highest average rents.
-- 2. Rent growth between 2020-2025 ranges approximately between 20–35%.
-- 3. Crime growth remains relatively stable across most regions.
-- 4. Structural regional differences appear stronger than year-to-year crime changes.