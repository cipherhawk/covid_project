SELECT 
    MAX(LENGTH(location)) AS dlocation_length,
    MAX(LENGTH(date)) AS ddate_length
FROM covid_deaths;
SELECT
    MAX(LENGTH(location)) AS vlocation_length,
    MAX(LENGTH(date)) AS vdate_length
FROM covid_vaccinations;

-- @block
CREATE INDEX idx_location_date ON covid_analysis.covid_deaths (location(33), date);
CREATE INDEX idx_total_cases_total_deaths ON covid_analysis.covid_deaths (total_cases, total_deaths);
CREATE INDEX idx_new_cases_new_deaths ON covid_analysis.covid_deaths (new_cases, new_deaths);
CREATE INDEX idx_population ON covid_analysis.covid_deaths (population);
CREATE INDEX idx_location_date ON covid_analysis.covid_vaccinations (location(33), date);
CREATE INDEX idx_people_vaccinated_new_vaccinations ON covid_analysis.covid_vaccinations (people_vaccinated, new_vaccinations);

-- @block
SELECT 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM covid_analysis.covid_deaths
ORDER BY 1, 2;

-- @block
-- Death Rates (total cases/total deaths)
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    CONCAT(ROUND(total_deaths/total_cases*100, 2), '%') AS death_rate
FROM covid_analysis.covid_deaths
WHERE total_deaths/total_cases IS NOT NULL
ORDER BY 1, 2;

-- @block
-- Death Rates (total cases/total deaths) in Malaysia
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    CONCAT(ROUND(total_deaths/total_cases*100, 2), '%') AS death_rate
FROM covid_analysis.covid_deaths
WHERE 
    total_deaths/total_cases IS NOT NULL
AND
    location = 'Malaysia'
ORDER BY 1, 2;

-- @block
-- Percentage of population infected
SELECT 
    location,
    date,
    total_cases,
    population,
    CONCAT(ROUND(total_cases/population*100, 2), '%') AS 'Infected population'
FROM covid_analysis.covid_deaths
WHERE total_cases/population IS NOT NULL
ORDER BY 1, 2;

-- @block
-- Percentage of population infected in Malaysia
SELECT 
    location,
    date, total_cases,
    population,
    CONCAT(ROUND(total_cases/population*100, 2), '%') AS 'Infected population'
FROM covid_analysis.covid_deaths
WHERE 
    total_cases/population IS NOT NULL
AND
    location = 'Malaysia'
ORDER BY 1, 2;

-- @block
-- Countries with highest infection rates ranked (high to low)
SELECT 
    location,
    MAX(total_cases) AS 'Total cases',
    CONCAT(ROUND(MAX(total_cases/population*100), 2), '%') AS 'Population infected'
FROM covid_analysis.covid_deaths
WHERE continent != ''
GROUP BY location, population
ORDER BY MAX(total_cases/population) DESC;


-- @block
-- Countries with highest death rates ranked (high to low)
SELECT 
    location,
    MAX(total_deaths) AS 'Total death toll',
    CONCAT(ROUND(MAX(total_deaths)/MAX(total_cases)*100, 2), '%') AS 'Death rate'
FROM covid_analysis.covid_deaths
WHERE continent != ''
GROUP BY location
ORDER BY MAX(total_deaths)/MAX(total_cases) DESC;

-- CONTINENTAL DATA --

-- @block
-- Continents with highest death rates
SELECT 
    continent,
    MAX(total_deaths) AS 'Total death toll',
    CONCAT(ROUND(MAX(total_deaths)/MAX(total_cases)*100, 2), '%') AS 'Death rate'
FROM covid_analysis.covid_deaths
WHERE continent != ''
GROUP BY continent
ORDER BY MAX(total_deaths)/MAX(total_cases) DESC;

-- GLOBAL DATA --

-- @block
-- New cases and new deaths over time
SELECT 
    date, 
    COALESCE(SUM(new_cases), 0) AS 'Global cases',
    COALESCE(SUM(new_deaths), 0) AS 'Global deaths',
    CONCAT(ROUND(COALESCE(SUM(new_deaths)/SUM(new_cases), 0)* 100, 2), '%') AS 'Global death rate'
FROM covid_analysis.covid_deaths
WHERE NOT (continent = 'AFRICA' AND date = '2020-01-04')
AND continent != ''
GROUP BY date
ORDER BY 1, 2;

-- @block
-- Total cases, deaths and death rate
SELECT 
    SUM(new_cases) AS 'Global cases',
    SUM(new_deaths) AS 'Global deaths',
    CONCAT(ROUND(COALESCE(SUM(new_deaths)/SUM(new_cases), 0)* 100, 2), '%') AS 'Global death rate'
FROM covid_analysis.covid_deaths
WHERE NOT (continent = 'AFRICA' AND date = '2020-01-04') -- excl. outlier from results
AND continent != ''
ORDER BY 1, 2;

-- @block
-- Vaccinations over time (amount of vaccinations, not uniquely vaccinated individuals)
SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location ORDER BY dea.location, dea.date
        ) VaccinationsOverTime
FROM covid_analysis.covid_deaths AS dea
JOIN covid_analysis.covid_vaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2, 3;

-- @block
-- Vaccination rates over time (against population)
-- (may exceed 100% as data records individuals that may have multiple vaccinations 
-- and not unique vaccinated individuals)
-- referencing CTE
WITH vac_pop (continent, location, date, population, new_vaccinations, VaccinationsOverTime)
AS (
    SELECT dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location ORDER BY dea.location, dea.date
            ) VaccinationsOverTime
    FROM covid_analysis.covid_deaths AS dea
    JOIN covid_analysis.covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent != ''
)
SELECT *, 
    CONCAT(ROUND(VaccinationsOverTime/population* 100, 2), '%') AS vaccination_rate
FROM vac_pop;

-- @block
SET profiling=1;

-- @block
-- Vaccination rates over time
WITH vac_pop (continent, location, date, population, vaccinated_individuals)
AS (
    SELECT dea.continent,
        dea.location,
        dea.date,
        dea.population,
        MAX(people_vaccinated) OVER (PARTITION BY dea.location order by dea.location, dea.date)
        AS vaccinated_individuals
    
    FROM covid_analysis.covid_deaths AS dea
    JOIN covid_analysis.covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent != '' 
)
SELECT *,
CONCAT(ROUND(vaccinated_individuals/population* 100, 2), '%') AS vaccination_rate
FROM vac_pop
ORDER BY 2, 3;

-- @block
SHOW profiles;

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
SELECT *,
    CONCAT(ROUND(vaccinated_individuals/population* 100, 2), '%') AS vaccination_rate
FROM covid_analysis.vaccinated_population
ORDER BY 2, 3;


