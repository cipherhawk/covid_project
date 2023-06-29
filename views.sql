-- Views for visualizations --

-- @block
--Vaccination rates
DROP VIEW IF EXISTS covid_analysis.VaccinatedPopulation;
CREATE VIEW covid_analysis.VaccinatedPopulation AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    MAX(people_vaccinated) OVER (
        PARTITION BY dea.location order by dea.location, dea.date)
    AS vaccinated_individuals,
    CAST(ROUND(
        (MAX(people_vaccinated) OVER (
            PARTITION BY dea.location order by dea.location, dea.date)
        ) / dea.population, 4) AS DECIMAL(5,4)) AS vaccination_rate
    FROM covid_analysis.covid_deaths AS dea
    JOIN covid_analysis.covid_vaccinations AS vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent != '';
