SELECT *
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths` 
order by 3,4

SELECT *
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths` 
order by 3,4
-- Exclude aggregated rows (continents/world) to keep only country-level data
WHERE continent IS NOT NULL


-- select data that we are going to be using


SELECT location, date, total_cases , new_cases,total_deaths,population_density
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
WHERE continent IS NOT NULL
order by 1,2

-- looking at total cases vs total deaths

SELECT location, date, total_cases ,total_deaths, SAFE_DIVIDE(total_deaths,total_cases)*100 as DeathPercentage 
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths` 
WHERE continent IS NOT NULL
order by 1,2

-- shows likelihood of dying if you contract covid in your county
SELECT location, date, total_cases ,total_deaths, SAFE_DIVIDE(total_deaths,total_cases)*100 as DeathPercentage 
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths` 
order by 1,2
WHERE location like '%Egypt%'

-- looking at total cases vs population 
-- shows what percentage of population got covid
SELECT location, date, total_cases ,population_density, SAFE_DIVIDE(total_cases, population_density)*100 as precentPopulation 
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths` 
WHERE continent IS NOT NULL
order by 1,2

-- looking at countries with highest infection rate compared to population
SELECT 
location,
population_density, 
MAX(total_cases) AS MaxCases,
SAFE_DIVIDE(MAX(total_cases), population_density)*100 AS precentPopulation
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
WHERE continent IS NOT NULL
GROUP BY location, population_density
ORDER BY MaxCases desc

-- showing country with highest death count per population
SELECT 
location,
MAX (total_deaths) as TotalDeathCount
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

-- showing country with highest death count per population
SELECT 
location,
MAX (cast(total_deaths as int)) as TotalDeathCount
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc


-- showing contintents with highest count per population
SELECT 
continent,
MAX (cast(total_deaths as int)) as TotalDeathCount
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`
WHERE continent IS not NULL
GROUP BY continent
ORDER BY TotalDeathCount desc


-- Calculate daily global death percentage from new cases and deaths
SELECT 
date,  
SUM(new_cases) as total_cases,
SUM(cast(new_deaths as int)) as total_deaths,
SAFE_DIVIDE(SUM(cast(new_deaths as int)), SUM(new_cases))*100 AS DeathPercent
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`  
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Calculate global total cases, deaths, and overall death percentage
SELECT 
SUM(new_cases) as total_cases,
SUM(cast(new_deaths as int)) as total_deaths,
SAFE_DIVIDE(SUM(cast(new_deaths as int)), SUM(new_cases))*100 AS DeathPercent
FROM `intrepid-charge-485812-r5.coivid19.CovidDeaths`  
WHERE continent IS NOT NULL
ORDER BY 1,2

----------------------------------------------------------------------
----------------------------------------------------------------------
----------------------------------------------------------------------

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
  SUM(CAST (vac.new_vaccinations AS INT64)) OVER (partition by dea.location)
FROM `coivid19.CovidDeaths` dea
JOIN `coivid19.CovidVaccination` vac
  ON dea.location = vac.location
  and dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3
--


