SELECT * FROM covid_data_deaths ORDER BY 3,4;

-- select data that we are going to be using
SELECT location, date, population, total_cases, new_cases, total_deaths
FROM covid_data_deaths
ORDER BY 1,2;

-- looking at total cases vs total deaths
-- shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM covid_data_deaths
WHERE location = 'United States'
ORDER BY 1,2;

-- looking at total cases vs population
SELECT location, date, population, total_cases,  (total_cases/CAST(population AS DOUBLE))*100 AS infected_population_percentage
FROM covid_data_deaths
WHERE location = 'United States'
ORDER BY date;

-- looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highestinfectioncount, ROUND(MAX(total_cases/CAST(population AS DOUBLE))*100, 2) AS PercentPopulationInfected
FROM covid_data_deaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- looking at countries with the highest death count per population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM covid_data_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- let's break things down by continent
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM covid_data_deaths
WHERE continent IS NULL
AND location != 'High income' 
AND location != 'Upper middle income' 
AND location != 'Lower middle income' 
AND location != 'Low income' 
AND location != 'World'
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- looking at global numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, CONCAT(ROUND(SUM(new_deaths)/SUM(new_cases)*100,2),'%') AS DeathPercentage
FROM covid_data_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

-- looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rolling_people_vaccinated
FROM covid_data_deaths dea
JOIN covid_data_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- use cte
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rolling_people_vaccinated
FROM covid_data_deaths dea
JOIN covid_data_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac;

-- temp table
DROP TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TABLE PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
);
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rolling_people_vaccinated
FROM covid_data_deaths dea
JOIN covid_data_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date;
    
SELECT *, (rolling_people_vaccinated/population)*100
FROM PercentPopulationVaccinated;

-- creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinatedView AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
AS rolling_people_vaccinated
FROM covid_data_deaths dea
JOIN covid_data_vaccinations vac
	ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;