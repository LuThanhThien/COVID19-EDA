SELECT *
FROM covid19_project_01..CovidDeaths$
ORDER BY
	7 DESC;

SELECT *
FROM covid19_project_01..CovidVaccinations$
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

--COUNTRY WITH HIGHEST DEATH COUNT BY DATE 
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

--CONTINENT WITH HIGHEST DEATH COUNT BY DATE 
SELECT 
	location, population, 
	MAX(total_deaths) AS highest_death
FROM covid19_project_01..CovidDeaths$
WHERE
	continent IS NULL
	AND location NOT LIKE '%income%'
	AND location NOT IN ('World','European Union')
GROUP BY
	location, population
ORDER BY
	highest_death DESC;

--HIGHEST INFLECTION RATE, DEATH RATE BY COUNTRY
SELECT 
	location, population, 
	MAX(total_cases) AS highest_inflection,
	MAX(total_cases/population) AS inflection_rate,
	MAX(total_deaths/population) AS death_rate
FROM covid19_project_01..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location, population
ORDER BY
	inflection_rate DESC;

--TOTAL DEATHS BY DATE BY COUNTRY
SELECT
	location, date,
	total_deaths
FROM covid19_project_01..CovidDeaths$
WHERE
	continent IS NOT NULL
ORDER BY
	location, date

--INFLECTION RATE BY DATE BY COUNTRY
SELECT
	location, population, SUM(new_cases) AS total_cases,
	SUM(new_cases)/population AS inflection_rate
FROM covid19_project_01..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location, population
ORDER BY
	inflection_rate DESC;

--TOTAL CASES, DEATHS, CFR, INFLECTION RATE, DEATH_RATES BY CONTINENT
SELECT
   location, population, 
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deahts, 
	CASE	
		WHEN SUM(new_cases) IS NULL THEN 0
		WHEN SUM(new_cases) = 0 THEN 0
		ELSE SUM(new_deaths)/SUM(new_cases)
		END AS case_facility_rate,
	SUM(new_cases)/population AS inflection_rate,
	SUM(new_deaths)/population AS death_rate
FROM covid19_project_01..CovidDeaths$
WHERE
	continent IS NULL
	AND location NOT IN ('World','European Union')
	AND location NOT LIKE '%income%'
GROUP BY
	location, population
ORDER BY
	location;

--TOTAL CASES AND DEATHS BY COUNTRY
SELECT location, population,  
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deahts, 
	CASE	
		WHEN SUM(new_cases) IS NULL THEN 0
		WHEN SUM(new_cases) = 0 THEN 0
		ELSE SUM(new_deaths)/SUM(new_cases)
		END AS case_facility_rate,
	SUM(new_cases)/population AS inflection_rate,
	SUM(new_deaths)/population AS death_rate
FROM covid19_project_01..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location, population
ORDER BY
	location--total_cases;

--COUNTRY CATERGORIZED BY HERD IMMUNITY
/*Herd immunity is a threshold for vaccinated percentage 
above which the society is protected from inflectous desease*/
WITH population_vaccination (continent, location, date, population,
	people_vaccinated, people_fully_vaccinated, new_vaccinations,
	vaccinated_percentage, fullvac_percentage, total_vaccinations) 
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.people_vaccinated, vac.people_fully_vaccinated, vac.new_vaccinations,
	CONVERT(BIGINT,vac.people_vaccinated)/dea.population AS vaccinated_percentage,
	CONVERT(BIGINT,vac.people_fully_vaccinated)/CONVERT(BIGINT,vac.people_vaccinated) AS fullvac_percentage,
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
SELECT 
	location, MAX(vaccinated_percentage) AS current_vaccinated_percent,
	CAST( 
	CASE
		WHEN MAX(vaccinated_percentage)>0.8
			THEN 1
        ELSE 0
		END AS BIT) AS herd_immunity
FROM population_vaccination
GROUP BY
	location
ORDER BY 
	location;

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
  new_vaccinations NUMERIC,
  vaccinated_percentage FLOAT,
  fullvac_percentage FLOAT,
  total_vaccinations NUMERIC
)
INSERT INTO #percent_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.people_vaccinated, vac.people_fully_vaccinated, vac.new_vaccinations,
	CONVERT(FLOAT,vac.people_vaccinated)/dea.population AS vaccinated_percentage,
	CONVERT(FLOAT,vac.people_fully_vaccinated)/CONVERT(BIGINT,vac.people_vaccinated) AS fullvac_percentage,
	SUM(CONVERT(FLOAT,new_vaccinations)) OVER
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
	CONVERT(BIGINT,vac.people_vaccinated)/MAX(dea.population) AS vaccinated_percentage,
	CONVERT(BIGINT,vac.people_fully_vaccinated)/CONVERT(BIGINT,vac.people_vaccinated) AS fullvac_percentage,
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

--GLOBAL SUMMARY
SELECT 
	MAX(date) AS latest_date,
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths,
	SUM(new_deaths)/SUM(new_cases) AS death_percentage
FROM covid19_project_01..CovidDeaths$
WHERE
	continent IS NULL
	AND location NOT IN ('World', 'European Union')
	AND location NOT LIKE '%income%'
--TOTAL PEOPLE HAVE AT LEAST 1 VACCINATION
SELECT 
	MAX(CONVERT(BIGINT,vac.people_vaccinated)) AS total_vaccinated,
	MAX(CONVERT(BIGINT,vac.people_vaccinated))/MAX(dea.population) AS vaccinated_percentage
FROM covid19_project_01..CovidDeaths$ dea
  JOIN covid19_project_01..CovidVaccinations$ vac
  ON dea.location = vac.location AND dea.date = vac.date
WHERE 
	dea.location = 'World'

--GLOBAL TOTAL CASES, TOTAL DEATHS, CFR, INFLECTION RATE AND DEATH RATE BY INCOME
SELECT 
	location, population, 
	SUM(new_cases) AS total_cases,
	SUM(new_deaths) AS total_deaths,
	CASE	
		WHEN SUM(new_cases) IS NULL THEN 0
		WHEN SUM(new_cases) = 0 THEN 0
		ELSE SUM(new_deaths)/SUM(new_cases)
		END AS case_facility_rate,
	SUM(new_cases)/population AS inflection_rate,
	SUM(new_deaths)/population AS death_rate
FROM covid19_project_01..CovidDeaths$
WHERE
	location LIKE '%income%'
GROUP BY
	location, population
ORDER BY
	location;

--COUNTRY INFLECTION RATE VERSUS POPULATION DENSITY
SELECT 
	dea.location, dea.population, 
	SUM(dea.new_cases)/dea.population AS inflection_rate,
	vac.population_density
FROM
	covid19_project_01..CovidDeaths$ dea
	JOIN covid19_project_01..CovidVaccinations$ vac
	ON dea.date = vac.date AND dea.location = vac.location
WHERE
	dea.continent IS NOT NULL
GROUP BY
	dea.location, dea.population, vac.population_density
ORDER BY
	dea.location;

--COUNTRY VACCINATED PERCENTAGE VERSUS GDP PER CAPITAL
SELECT
	dea.location, dea.population, 
	MAX(CONVERT(BIGINT,vac.people_vaccinated))/MAX(dea.population) AS vaccinated_percentage,
	vac.gdp_per_capita
FROM
	covid19_project_01..CovidDeaths$ dea
	JOIN covid19_project_01..CovidVaccinations$ vac
	ON dea.date = vac.date AND dea.location = vac.location
WHERE
	dea.continent IS NOT NULL
GROUP BY
	dea.location, dea.population, vac.gdp_per_capita
ORDER BY
	dea.location;

--COUNTRY DEATH RATE VERSUS VACCINATED PERCENTAGE, MEDIAN AGE, CARDIOVAC DSELECT 
SELECT
	dea.location, dea.population, 
	SUM(dea.new_deaths)/dea.population AS death_rate,
	MAX(CONVERT(BIGINT,vac.people_vaccinated))/MAX(dea.population) AS vaccinated_percentage,
	vac.median_age, vac.cardiovasc_death_rate
FROM
	covid19_project_01..CovidDeaths$ dea
	JOIN covid19_project_01..CovidVaccinations$ vac
	ON dea.date = vac.date AND dea.location = vac.location
WHERE
	dea.continent IS NOT NULL
GROUP BY
	dea.location, dea.population, vac.median_age, vac.cardiovasc_death_rate
ORDER BY
	dea.location;