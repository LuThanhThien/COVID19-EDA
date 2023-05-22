SELECT *
FROM covid19_project_01..CovidDeaths$
ORDER BY 7 DESC;

SELECT *
FROM covid19_project_01..CovidDeaths$
ORDER BY
  7 DESC;

--EXPLORE LOCATION 
SELECT DISTINCT location, continent
FROM covid19_project_01..CovidDeaths$
ORDER BY
  location;

--EXPLORE LOCATION WHERE CONTINENT IS NULL
SELECT DISTINCT location, continent
FROM covid19_project_01..CovidDeaths$ 
WHERE
  continent IS NULL
ORDER BY
  location;

--DISPLAY LOCATIONS THAT ARE NOT A SINGLE COUNTRY
SELECT DISTINCT location
FROM covid19_project_01..CovidDeaths$ 
WHERE
  continent IS NULL
ORDER BY
  location;

--COUNTRY WITH HIGHEST DEATH COUNT
SELECT 
  location, population, 
  MAX(total_deaths) AS highest_death
FROM covid19_project_01..CovidDeaths$ 
WHERE
  continent IS NOT NULL
GROUP BY
  location, population
ORDER BY
  highest_death DESC;

--CONTINENT WITH HIGHEST DEATH COUNT
SELECT 
  location, population, 
  MAX(total_deaths) AS highest_death
FROM covid19_project_01..CovidDeaths$
WHERE
  continent IS NULL
  AND location NOT LIKE '%income%'
GROUP BY
  location, population
ORDER BY
  highest_death DESC;

--INFLECTION RATE BY COUNTRY
SELECT 
  location, population, 
  MAX(total_cases) AS highest_inflection,
  MAX(total_cases/population)*100 AS inflection_rate,
  MAX(total_deaths/population)*100 AS death_rate
FROM covid19_project_01..CovidDeaths$
WHERE
  continent IS NOT NULL
GROUP BY
  location, population
ORDER BY
  inflection_rate DESC;

--DEATH RATE BY COUNTRY
SELECT 
  location, population, 
  MAX(total_deaths) AS highest_deaths,
  MAX(total_deaths/population)*100 AS death_rate
FROM covid19_project_01..CovidDeaths$
WHERE
  continent IS NOT NULL
GROUP BY
  location, population
ORDER BY
  death_rate DESC;

--HIGHEST TOTAL DEATHS BY INCOME
SELECT 
  location, population, 
  MAX(total_deaths) AS highest_death
FROM covid19_project_01..CovidDeaths$
WHERE
  location LIKE '%income%'
GROUP BY
  location, population
ORDER BY
  highest_death DESC;

--GLOBAL CASES AND DEATHS BY DATE
SELECT
  date, SUM(new_cases) AS global_cases, 
  SUM(new_deaths) AS global_deaths
FROM covid19_project_01..CovidDeaths$
WHERE
  continent IS NOT NULL
GROUP BY
  date
ORDER BY
  date;

--TOTAL CASES AND DEATHS BY COUNTRY
SELECT
  location, date, total_cases, total_deaths
FROM covid19_project_01..CovidDeaths$
WHERE
  continent IS NOT NULL
ORDER BY
  location, date;

--USE CTE
WITH population_vaccination (continent, location, date, population,
	people_vaccinated, people_fully_vaccinated, new_vaccinations,
	vaccinated_percentage, fullvac_percentage, total_vaccinations) 
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.people_vaccinated, vac.people_fully_vaccinated, vac.new_vaccinations,
	CONVERT(BIGINT,vac.people_vaccinated)/dea.population*100 AS vaccinated_percentage,
	CONVERT(BIGINT,vac.people_fully_vaccinated)/CONVERT(BIGINT,vac.people_vaccinated)*100 AS fullvac_percentage,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER
	(
		PARTITION BY 
			dea.location 
		ORDER BY
			dea.location, dea.date
	) AS total_vaccinations
	FROM covid19_project_01..CovidDeaths$ dea
		JOIN covid19_project_01..CovidVaccinations$ vac
		ON dea.location = vac.location
		AND dea.date = vac.date
)
--VACCINATION PERCENTAGE
SELECT location, population, MAX(people_vaccinated) AS total_vaccinated, MAX(vaccinated_percentage) AS current_vaccinated
FROM population_vaccination
WHERE
  continent IS NOT NULL
GROUP BY
  location, population
ORDER BY
  current_vaccinated DESC;

--CREATE NEW TABLE
DROP TABLE IF EXISTS #percent_vaccinated
CREATE TABLE #percent_vaccinated
(
  continent NVARCHAR(255),
  location NVARCHAR(255),
  date DATETIME,
  population NUMERIC,
  people_vaccinated NUMERIC,
  people_fully_vaccinated NUMERIC,
  vaccinated_percentage NUMERIC,
  fullvac_percentage NUMERIC,
  new_vaccinations NUMERIC,
  total_vaccinations NUMERIC
)
INSERT INTO #percent_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.people_vaccinated, vac.people_fully_vaccinated, vac.new_vaccinations,
	CONVERT(BIGINT,vac.people_vaccinated)/dea.population*100 AS vaccinated_percentage,
	CONVERT(BIGINT,vac.people_fully_vaccinated)/CONVERT(BIGINT,vac.people_vaccinated)*100 AS fullvac_percentage,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER
  (
    PARTITION BY 
      dea.location 
    ORDER BY
      dea.location, dea.date
   ) AS total_vaccinations
FROM covid19_project_01..CovidDeaths$ dea
  JOIN covid19_project_01..CovidVaccinations$ vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
SELECT *
FROM #percent_vaccinated	
ORDER BY
	location, date;

--CREATE VIEW FOR VISULIZATION
CREATE VIEW percent_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.people_vaccinated, vac.people_fully_vaccinated, vac.new_vaccinations,
	CONVERT(BIGINT,vac.people_vaccinated)/dea.population*100 AS vaccinated_percentage,
	CONVERT(BIGINT,vac.people_fully_vaccinated)/CONVERT(BIGINT,vac.people_vaccinated)*100 AS fullvac_percentage,
	SUM(CONVERT(BIGINT,new_vaccinations)) OVER
  (
    PARTITION BY 
      dea.location 
    ORDER BY
      dea.location, dea.date
   ) AS total_vaccinations
FROM covid19_project_01..CovidDeaths$ dea
  JOIN covid19_project_01..CovidVaccinations$ vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL
