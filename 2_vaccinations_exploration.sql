SELECT *
FROM `coivid19.CovidVaccination`

SELECT *
FROM `coivid19.CovidDeaths` dea
JOIN `coivid19.CovidVaccination` vac
  ON dea.location = vac.location
  and dea.date = vac.date

-- looking at total population vs vaccination

SELECT dea.continent, dea.location, dea.date, dea.population_density, vac.new_vaccinations
SELECT dea.continent, dea.location, dea.date, population_density
FROM `coivid19.CovidDeaths` dea
JOIN `coivid19.CovidVaccination` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3


-- Calculates cumulative vaccinations per location

SELECT dea.continent,
  dea.location,
  dea.date,
  dea.population_density,
  vac.new_vaccinations,
  SUM(CAST (vac.new_vaccinations AS INT64)) OVER (partition by dea.location, dea.date) as RollingPeopleVaccinated
FROM `coivid19.CovidDeaths` dea
JOIN `coivid19.CovidVaccination` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3
