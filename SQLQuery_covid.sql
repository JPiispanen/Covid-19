-- Looking at the entire dataset. 
SELECT * 
	FROM PortfolioProject..CovidDeaths
	ORDER BY 3,4

SELECT * 
	FROM PortfolioProject..CovidVaccinations
	ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
	FROM PortfolioProject..CovidDeaths
	ORDER BY 1,2


-- #1 Mortality rate: Total Cases vs Total Deaths: 
-- The mortality rate tells the proportion of deaths compared to the total number of cases, 
-- providing an indication of the lethality of a disease 
SELECT	 location
		,date, total_cases, total_deaths
		,(total_deaths/total_cases)*100 AS 'Mortality rate'
	FROM PortfolioProject..CovidDeaths
	WHERE location = 'Finland'  -- where clause extracts specific records. By removing this clause all countries are shown
	ORDER BY 1,2


--#2 Infection rate: Total Cases vs Population
-- The infection rate is a measure of the prevalence of the disease within a population and helps 
-- in understanding the spread and impact of the disease.
SELECT	 location
		,date
		,population
		,total_cases
		,(total_cases/population)*100 AS 'Infection rate'
	FROM PortfolioProject..CovidDeaths
	WHERE location = 'Finland' 
	ORDER BY 1,2


-- #3 Countries with highest infection rate  (as a percentage)  compared to population
SELECT	 location
		,population, MAX(total_cases) AS 'Total infection count' 
		,MAX(total_cases/population)*100 AS PercentOfPopulationInfected
	FROM PortfolioProject..CovidDeaths
	GROUP BY location, population
	ORDER BY PercentOfPopulationInfected DESC


-- #4 Showing countries with highest death count per population
-- Provides insights into the severity of the impact of COVID-19 in specific countries
SELECT	 location
		,MAX(total_deaths) AS TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent is not null
	GROUP BY location
	ORDER BY TotalDeathCount DESC


-- #5 Showing continents with the highest death count per population
SELECT	 continent
		,MAX(total_deaths) AS TotalDeathCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent is not null
	GROUP BY continent
	ORDER BY TotalDeathCount DESC


-- #6 Case fatality rate (CFR): This metric indicates the proportion of confirmed cases that have resulted in death.
-- The case fatality rate provides insights into the severity and lethality of COVID-19 by quantifying the risk of death 
-- among those who have tested positive for the disease.
SELECT	 date
		,SUM(new_cases) AS 'Total cases'
		,SUM(new_deaths) AS 'Total deaths'
		,COALESCE(SUM(new_deaths) / NULLIF(SUM(new_cases),0), 0)*100 AS 'Case Fatality Rate'   --The COALESCE function ensures that no division calculation is performed if the number of new cases is zero, resulting in 0..
	FROM PortfolioProject..CovidDeaths
	WHERE continent is not null
	GROUP BY date 
	ORDER BY 1,2


-- #7 Case fatality rate worldwide (by May 17, 2023)
SELECT	 SUM(new_cases) AS 'Total cases'
		,SUM(new_deaths) AS 'Total deaths'
		,COALESCE(SUM(new_deaths) / NULLIF(SUM(new_cases),0), 0)*100 AS 'Case Fatality Rate'
	FROM PortfolioProject..CovidDeaths
	WHERE continent is not null
	ORDER BY 1,2


-- #8 Total population vs vaccinations
-- An inner join from tables CovidDeaths and CovidVaccinations based on location and date.
SELECT	 dea.continent
		,dea.location
		,dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(float,vac.new_vaccinations)) OVER 
			(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS 'People Vaccinated, Cumulative' -- PARTITION BY can perform calculations or aggregations on subsets of data within distinct groups or partitions.
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
	ORDER BY 2,3


-- #9 Cumulative Vaccinations VS. Total Population (Using a Common Table Expression, CTE)
WITH PopvsVac (continent, location, date, population, new_vaccinations, cumulative_new_vaccinations)
AS
(
SELECT	 dea.continent
		,dea.location
		,dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(float,vac.new_vaccinations)) OVER 
			(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cumulative_new_vaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
	--ORDER BY 2,3 
)
SELECT *, (cumulative_new_vaccinations/population)*100 AS 'Rate of vaccinations'
	FROM PopvsVac


-- #10  Cumulative Vaccinations VS. Total Population (Using a temporary table)
DROP TABLE IF exists #PercentPopulationVaccinated -- Check if temp table exists. If yes, then drop the temp table before creating it. 
CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar(255), 
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT	 dea.continent
		,dea.location, dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM #PercentPopulationVaccinated


-- #11 Store data to Views for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT	 dea.continent
		,dea.location
		,dea.date
		,dea.population
		,vac.new_vaccinations
		,SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

CREATE VIEW IcuAndHospitalPatients AS
SELECT	 location
		,date
		,population
		,icu_patients
		,hosp_patients
	FROM PortfolioProject..CovidDeaths


SELECT * 
	FROM PercentPopulationVaccinated
	ORDER BY location, date

SELECT * 
	FROM IcuAndHospitalPatients
	ORDER BY location,date