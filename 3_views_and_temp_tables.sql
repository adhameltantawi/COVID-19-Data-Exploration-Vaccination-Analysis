
-- Calculate cumulative vaccinations per location using CTE and window function

WITH PopvsVac AS (
SELECT 
  dea.continent,
  dea.location,
  dea.date,
  dea.population_density,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS INT64)) 
  OVER (PARTITION BY dea.location ORDER BY dea.date) 
  AS RollingPeopleVaccinated
FROM `coivid19.CovidDeaths` dea
JOIN `coivid19.CovidVaccination` vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population_density)*100
FROM PopvsVac
ORDER BY location, date;



-- TEMP TABLE
DROP TABLE IF EXISTS percentPopulationVaccinated;

CREATE TEMP TABLE percentPopulationVaccinated AS
SELECT  
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population_density,
  vac.new_vaccinations, 
  SUM(CAST(vac.new_vaccinations AS INT64))  
  OVER (PARTITION BY dea.location ORDER BY dea.date)  
  AS RollingPeopleVaccinated 
FROM `coivid19.CovidDeaths` dea 
JOIN `coivid19.CovidVaccination` vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL;

SELECT *,
       (RollingPeopleVaccinated / population_density) * 100 AS VaccinationPercentage
FROM percentPopulationVaccinated
ORDER BY location, date;

-- creating view to store data for later visualization

CREATE VIEW `coivid19.percentPopulationVaccinated` AS
SELECT  
  dea.continent, 
  dea.location, 
  dea.date, 
  dea.population_density,
  vac.new_vaccinations, 
  SUM(CAST(vac.new_vaccinations AS INT64))  
  OVER (PARTITION BY dea.location ORDER BY dea.date)  
  AS RollingPeopleVaccinated
FROM `coivid19.CovidDeaths` dea 
JOIN `coivid19.CovidVaccination` vac 
  ON dea.location = vac.location 
  AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL;

SELECT *,
       (RollingPeopleVaccinated / population_density) * 100 AS VaccinationPercentage
FROM `coivid19.percentPopulationVaccinated`
ORDER BY location, date;
