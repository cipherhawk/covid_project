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
    date AS Date,
    SUM(new_deaths) OVER (PARTITION BY location order by location, date) AS 'Total deaths'
FROM covid_analysis.covid_deaths
WHERE continent = ''
AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Lower middle income', 'Low income', 'Upper middle income')

ORDER BY 'Total deaths'

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

-- @block
-- Death Rates (total cases/total deaths)
SELECT 
    location AS Location,
    date AS Date,
    COALESCE(total_cases, 0) AS 'Total Cases',
    COALESCE(total_deaths, 0) 'Total Deaths',
    CONCAT(ROUND(COALESCE(total_deaths/total_cases*100, 0), 2), '%') AS 'Death Rate'
FROM covid_analysis.covid_deaths
WHERE continent != ''
ORDER BY 1, 2;

-- @block
-- Temp table: vaccinated_population
CREATE TEMPORARY TABLE IF NOT EXISTS 
    vaccinated_population(
        continent text,
        location text,
        date date,
        population INT,
        vaccinated_individuals BIGINT
    )
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    MAX(people_vaccinated) OVER (PARTITION BY dea.location order by dea.location, dea.date)
    AS vaccinated_individuals
    FROM covid_analysis.covid_deaths AS dea
    JOIN covid_analysis.covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent != '';

-- @block
-- Vaccination rates over time
SELECT
    location AS Location,
    date AS DATE,
    population AS Population,
    COALESCE(vaccinated_individuals, 0) AS 'Vaccinated Population',
    CONCAT(ROUND(COALESCE(vaccinated_individuals/population* 100, 0), 2), '%') AS 'Vaccination Rate'
FROM covid_analysis.vaccinated_population
ORDER BY 1, 2;