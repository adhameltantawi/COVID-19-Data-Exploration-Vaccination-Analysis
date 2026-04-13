-- create Tableau Table 1
-- global_summary_metrics
SELECT  
  SUM(new_cases) AS total_cases, 
  SUM(CAST(new_deaths AS INT64)) AS total_deaths, 
  SAFE_DIVIDE(SUM(CAST(new_deaths AS INT64)), SUM(new_cases)) * 100 AS DeathPercent
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
WHERE continent IS NOT NULL;


-- create Tableau Table 2
-- total_deaths_by_location
SELECT  
  location, 
  SUM(CAST(new_deaths AS INT64)) AS TotalDeathCount
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
WHERE continent IS NULL
  AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- create Tableau Table 3
-- infection_rate_by_location
SELECT 
  location, 
  population_density, 
  MAX(total_cases) AS HighestInfectionCount,
  MAX(SAFE_DIVIDE(total_cases, population_density)) * 100 AS PercentPopulationInfected
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
GROUP BY location, population_density
ORDER BY PercentPopulationInfected DESC;

-- create Tableau Table 4
-- daily_infection_trend
SELECT  
  location,  
  IFNULL(population_density, 0) AS population_density,  
  date,  
  IFNULL(total_cases, 0) AS HighestInfectionCount, 
  IFNULL(SAFE_DIVIDE(total_cases, population_density) * 100, 0) AS PercentPopulationInfected 
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths` 
ORDER BY PercentPopulationInfected DESC;
