/*
COVID-19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3, 4

/*Select data that we are going to use*/

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1, 2

/*We are looking at Total Cases vs Total Deaths
Shows the likelihood of death if you are contracted with COVID in your country*/

--ALTER TABLE PortfolioProject..CovidDeaths
--ALTER COLUMN total_cases float

--ALTER TABLE PortfolioProject..CovidDeaths
--ALTER COLUMN total_deaths float

SELECT location, date, CAST(total_cases AS float) AS total_cases, CAST(total_deaths AS float) AS total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL
ORDER BY 1, 2

/*Demonstrating how the data looks based on continents*/

SELECT continent, MAX((total_deaths / total_cases)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY DeathPercentage DESC

/*We are looking at Total Cases vs Population
Shows the percentage of the population infected with COVID*/

SELECT location, date, total_cases, population, (total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL
ORDER BY 1, 2

/*Looking at the percentage of infected population in terms of continents*/

SELECT continent, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY PercentPopulationInfected

/*We are looking at countries with the highest infection rate compared to the population*/

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

CREATE VIEW InfectedPercent AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population

/*Shows the countries with the highest death count per population*/

SELECT location, population, MAX(total_deaths) AS TotalDeathCount, MAX((total_deaths / population)) * 100 AS PercentPopulationDeath
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationDeath DESC

CREATE VIEW DeathPercent AS
SELECT location, population, MAX(total_deaths) AS TotalDeathCount, MAX((total_deaths / population)) * 100 AS PercentPopulationDeath
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population

/*We can also show the continents with the highest death count per population*/

SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

CREATE VIEW DeathCount AS
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is NOT NULL
GROUP BY continent

SELECT *
FROM DeathCount


/*Global Numbers*/

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / SUM(new_cases)) * 100 AS DeathPercent
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is NOT NULL 
ORDER BY 1, 2



/*Looking at Total Population vs Vaccinations*/

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location 
		ORDER BY dea.location, dea. date) AS PartitionVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2, 3

/*Using CTE to perform calculation on Partition BY to find the percent of the vaccinated*/

WITH PopVsVac (continent, location, date, population, new_vaccinations, PartitionVaccinations) AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(float, vac.new_vaccinations)) OVER (
			PARTITION BY dea.location 
			ORDER BY dea.location, dea. date) AS TotalVaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is NOT NULL
	)

SELECT *, (PartitionVaccinations / population) * 100 AS PercentPopulationVaccinated
FROM PopVsVac

--Observing the percentage of vaccinations per continent

WITH PopVsVac2 (continent, location, population, PartitionVaccinations) AS (
	SELECT dea.continent, dea.location,  dea.population,
		SUM(CONVERT(float, vac.new_vaccinations)) OVER (
			PARTITION BY dea.location 
			ORDER BY dea.location, dea. date) AS TotalVaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is NOT NULL
	)

SELECT continent, MAX((PartitionVaccinations / population)) * 100 AS PercentPopulationVaccinated
FROM PopVsVac2
GROUP BY continent

/*Using Temp Table to perform calculation on Partition BY to find the percent of the vaccinated*/

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated (
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccincations numeric,
	PartitionVaccination numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location 
		ORDER BY dea.location, dea. date) AS TotalVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent is NOT NULL

SELECT *, (PartitionVaccination / population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated

/*Create View to store data for visualizations*/

DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) OVER (
		PARTITION BY dea.location 
		ORDER BY dea.location, dea. date) AS TotalVaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL

SELECT *
FROM PercentPopulationVaccinated