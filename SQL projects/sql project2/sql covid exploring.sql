/* Covid 19 Data Exploration 
   Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types */

/* Select Data that we are going to be starting with */
SELECT * 
FROM covid_death 
WHERE continent IS NOT NULL 
ORDER BY 3, 4;

SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM covid_death  
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

/* Total Cases vs Total Deaths */
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage 
FROM covid_death  
WHERE location LIKE '%states%' AND continent IS NOT NULL 
ORDER BY 1, 2;

/* Total Cases vs Population */
-- Shows what percentage of population infected with Covid
SELECT Location, date, Population, total_cases, 
       (total_cases / population) * 100 AS PercentPopulationInfected 
FROM covid_death  
ORDER BY 1, 2;

/* Countries with Highest Infection Rate compared to Population */
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected 
FROM covid_death  
GROUP BY Location, Population 
ORDER BY PercentPopulationInfected DESC;

/* Countries with Highest Death Count per Population */
SELECT Location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 
FROM covid_death 
WHERE continent IS NOT NULL 
GROUP BY Location 
ORDER BY TotalDeathCount DESC;

/* Breaking Things Down by Continent */
-- Showing continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount 
FROM covid_death  
WHERE continent IS NOT NULL 
GROUP BY continent 
ORDER BY TotalDeathCount DESC;

/* Global Numbers */
SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS INT)) AS total_deaths, 
       (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage 
FROM covid_death  
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

/* Total Population vs Vaccinations */
-- Shows percentage of population that has received at least one Covid vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM covid_death  dea 
JOIN covid_vaccine  vac 
ON dea.location = vac.location 
AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

/* Using CTE to perform Calculation on Partition By in previous query */
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
           SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
    FROM covid_death  dea 
    JOIN covid_vaccine vac 
    ON dea.location = vac.location 
    AND dea.date = vac.date 
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated 
FROM PopvsVac;

/* Using Temp Table to perform Calculation on Partition By in previous query */
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM covid_death  dea 
JOIN covid_vaccine vac 
ON dea.location = vac.location 
AND dea.date = vac.date;

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated 
FROM #PercentPopulationVaccinated;

/* Creating View to store data for later visualizations */
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
       SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated 
FROM covid_death  dea 
JOIN covid_vaccine vac 
ON dea.location = vac.location 
AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL;
