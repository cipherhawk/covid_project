-- @block
-- Global cases & deaths
SELECT 
    SUM(new_cases) AS 'Global cases',
    SUM(new_deaths) AS 'Global deaths',
    CONCAT(ROUND(COALESCE(SUM(new_deaths)/SUM(new_cases), 0)* 100, 2), '%') AS 'Global death rate'
FROM covid_analysis.covid_deaths
WHERE NOT (continent = 'AFRICA' AND date = '2020-01-04') -- excl. outlier from results
AND continent != ''
ORDER BY 1, 2;

-- @block
-- Total deaths by region
SELECT
    location AS Location,
    SUM(new_deaths) AS 'Total deaths'
FROM covid_analysis.covid_deaths
WHERE continent = ''
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Lower middle income', 'Low income', 'Upper middle income')
GROUP BY location
ORDER BY 'Total deaths'

-- @block
-- Infection rate by country
SELECT 
    location AS Location,
    population AS Population,
    COALESCE(MAX(total_cases), 0) AS 'Total cases',
    CONCAT(ROUND(COALESCE(MAX(total_cases/population*100), 0), 2), '%') AS 'Infection rate'
FROM covid_analysis.covid_deaths
WHERE continent != ''
GROUP BY location, population
ORDER BY MAX(total_cases/population) DESC;

-- @block
-- Infection rate over time
SELECT 
    location AS Location,
    population AS Population,
    date AS Date,
    COALESCE(MAX(total_cases), 0) AS 'Total cases',
    CONCAT(ROUND(COALESCE(MAX(total_cases/population*100), 0), 2), '%') AS 'Infection rate'
FROM covid_analysis.covid_deaths
WHERE continent != ''
GROUP BY location, population, date
ORDER BY location, MAX(total_cases/population);