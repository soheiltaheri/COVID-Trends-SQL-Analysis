# COVID-19 SQL Exploration

## Overview

A concise MySQL exploration of COVID-19 cases, deaths, population, and vaccination activity. The project demonstrates practical SQL analysis with country-level comparisons, global and continent aggregations, a joined vaccination timeline, a chronological window calculation, a CTE, and a reusable view.

This is a supporting portfolio project rather than a current public-health dashboard.

## Dataset and Source Requirements

The source data is not included in this repository. The analysis expects two Our World in Data-compatible tables in a MySQL schema named `portfolio`:

- `covid-deaths`: `location`, `continent`, `date`, `population`, `total_cases`, `new_cases`, `total_deaths`, and `new_deaths`
- `covid-vaccinations`: `location`, `date`, and `new_vaccinations`

Use the same geographic definitions and date coverage in both tables. The original repository did not record its exact download date or dataset version. Current data and documentation are available from [Our World in Data](https://ourworldindata.org/coronavirus) and its [COVID-19 data repository](https://github.com/owid/covid-19-data).

## Analytical Questions

- How did the recorded case fatality ratio change by country over time?
- Which countries recorded the highest infection share and death totals?
- How do reported deaths compare across continents?
- What are the global reported case and death totals when calculated from country rows?
- How did cumulative vaccination doses progress by country?

## SQL Techniques Used

- Filtering aggregate locations from country/territory observations
- Aggregations with `SUM`, `MAX`, and `COUNT`
- Null-safe division with `NULLIF`
- Conditional null handling with `COALESCE`
- Joining deaths and vaccination data on location and date
- A common table expression
- A chronological `SUM() OVER (...)` window
- `CREATE OR REPLACE VIEW`

## Repository Structure

```text
sql/
  covid_exploration.sql
README.md
.gitignore
```

## Setup and Import

Requirements: MySQL 8.0 or later.

1. Obtain a compatible COVID-19 dataset and record its source URL and download date.
2. Create or select a schema named `portfolio`.
3. Split or import the required fields into tables named `covid-deaths` and `covid-vaccinations`.
4. Store `date` as `DATE` and case, death, population, and vaccination fields as numeric types.
5. Confirm that `(location, date)` is unique within each table before joining.
6. Run [`sql/covid_exploration.sql`](sql/covid_exploration.sql) section by section.

Backtick quoting is required because the expected source-table names contain hyphens. If different table names are used, update the two qualified table references consistently.

## Filtering Logic

In the expected OWID-style data, rows with `continent IS NOT NULL` represent countries or territories. Rows with a null continent commonly represent aggregates such as `World`, continents, or income groups. Country comparisons, continent rollups, and global totals therefore use only non-null-continent rows to avoid mixing geographic levels or double counting aggregate rows.

## Limitations

- The source files and query-result snapshots are not included, so results depend on the imported dataset version.
- Reporting practices, revisions, and missing values differ by country and date.
- Summing daily reported changes can include retrospective corrections, including negative revisions.
- `total_cases / population` is a recorded-case share, not a unique-person infection rate.
- `total_deaths / total_cases` is a reported case fatality ratio, not an infection fatality rate.
- The vaccination window sums doses, not uniquely vaccinated people; values can exceed 100 doses per 100 people.
- Historical COVID-19 figures should not be interpreted as current medical guidance.
