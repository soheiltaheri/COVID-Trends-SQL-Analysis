/*
COVID-19 SQL Exploration
Database: MySQL 8.0+

Expected tables in the portfolio schema:
- `covid-deaths`: location, continent, date, population, total_cases,
  new_cases, total_deaths, new_deaths
- `covid-vaccinations`: location, date, new_vaccinations

Rows with continent IS NOT NULL represent countries/territories. Aggregate
locations such as World, income groups, and continents have continent IS NULL
and are excluded where country-level comparisons are intended.
*/


/* 1. Dataset coverage and basic quality checks */

SELECT
    COUNT(*) AS death_rows,
    COUNT(DISTINCT location) AS locations,
    MIN(date) AS first_date,
    MAX(date) AS last_date,
    SUM(population IS NULL) AS missing_population,
    SUM(total_cases IS NULL) AS missing_total_cases,
    SUM(total_deaths IS NULL) AS missing_total_deaths
FROM portfolio.`covid-deaths`;

SELECT
    COUNT(*) AS vaccination_rows,
    COUNT(DISTINCT location) AS locations,
    MIN(date) AS first_date,
    MAX(date) AS last_date,
    SUM(new_vaccinations IS NULL) AS missing_new_vaccinations
FROM portfolio.`covid-vaccinations`;


/* 2. Country-level case fatality ratio over time */

SELECT
    location,
    date,
    total_cases,
    total_deaths,
    ROUND(100.0 * total_deaths / NULLIF(total_cases, 0), 3) AS case_fatality_pct
FROM portfolio.`covid-deaths`
WHERE continent IS NOT NULL
  AND total_cases IS NOT NULL
ORDER BY location, date;


/* 3. Countries with the highest recorded infection share */

SELECT
    location,
    MAX(population) AS population,
    MAX(total_cases) AS highest_recorded_cases,
    ROUND(100.0 * MAX(total_cases / NULLIF(population, 0)), 2) AS highest_infection_pct
FROM portfolio.`covid-deaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_infection_pct DESC;


/* 4. Countries with the highest recorded death counts */

SELECT
    location,
    MAX(total_deaths) AS highest_recorded_deaths
FROM portfolio.`covid-deaths`
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_recorded_deaths DESC;


/* 5. Continent totals calculated from country-level daily deaths */

SELECT
    continent,
    SUM(COALESCE(new_deaths, 0)) AS reported_deaths
FROM portfolio.`covid-deaths`
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY reported_deaths DESC;


/* 6. Global totals calculated once from country-level daily records */

SELECT
    SUM(COALESCE(new_cases, 0)) AS reported_cases,
    SUM(COALESCE(new_deaths, 0)) AS reported_deaths,
    ROUND(
        100.0 * SUM(COALESCE(new_deaths, 0))
        / NULLIF(SUM(COALESCE(new_cases, 0)), 0),
        3
    ) AS reported_case_fatality_pct
FROM portfolio.`covid-deaths`
WHERE continent IS NOT NULL;


/* 7. Vaccination progress by country using a chronological rolling window */

WITH population_vs_vaccination AS (
    SELECT
        deaths.continent,
        deaths.location,
        deaths.date,
        deaths.population,
        vaccinations.new_vaccinations,
        SUM(COALESCE(vaccinations.new_vaccinations, 0)) OVER (
            PARTITION BY deaths.location
            ORDER BY deaths.date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS rolling_vaccination_doses
    FROM portfolio.`covid-deaths` AS deaths
    JOIN portfolio.`covid-vaccinations` AS vaccinations
      ON vaccinations.location = deaths.location
     AND vaccinations.date = deaths.date
    WHERE deaths.continent IS NOT NULL
)
SELECT
    continent,
    location,
    date,
    population,
    new_vaccinations,
    rolling_vaccination_doses,
    ROUND(100.0 * rolling_vaccination_doses / NULLIF(population, 0), 2)
        AS cumulative_doses_per_100_people
FROM population_vs_vaccination
ORDER BY location, date;


/* 8. Reusable vaccination-progress view */

CREATE OR REPLACE VIEW portfolio.percent_population_vaccinated AS
SELECT
    deaths.continent,
    deaths.location,
    deaths.date,
    deaths.population,
    vaccinations.new_vaccinations,
    SUM(COALESCE(vaccinations.new_vaccinations, 0)) OVER (
        PARTITION BY deaths.location
        ORDER BY deaths.date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS rolling_vaccination_doses
FROM portfolio.`covid-deaths` AS deaths
JOIN portfolio.`covid-vaccinations` AS vaccinations
  ON vaccinations.location = deaths.location
 AND vaccinations.date = deaths.date
WHERE deaths.continent IS NOT NULL;

SELECT
    continent,
    location,
    date,
    population,
    new_vaccinations,
    rolling_vaccination_doses,
    ROUND(100.0 * rolling_vaccination_doses / NULLIF(population, 0), 2)
        AS cumulative_doses_per_100_people
FROM portfolio.percent_population_vaccinated
ORDER BY location, date;

