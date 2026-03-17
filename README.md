# 🦠 COVID-19 Data Analysis — BigQuery SQL Project

> **Exploring the global pandemic through structured SQL analysis on real-world data from Our World in Data.**

---

## 📌 Project Overview

This project analyzes the COVID-19 pandemic using a dataset sourced from [Our World in Data](https://ourworldindata.org/covid-deaths), containing **67 columns** of daily records across all countries — covering cases, deaths, hospitalizations, vaccinations, testing, and demographic indicators.

All queries were written and executed in **Google BigQuery (SQL)**.

---

## 🗂️ Dataset Architecture

The original dataset was intentionally split into **two separate tables** following the principle of **Separation of Concerns** — each table has one clear purpose, queries stay focused, and joins remain intentional.

### Table 1: `CovidDeaths`
> *Tracks the daily progression of the pandemic.*

| Column Group | Columns |
|---|---|
| **Identifiers** | `iso_code`, `continent`, `location`, `date` |
| **Cases** | `total_cases`, `new_cases`, `new_cases_smoothed`, `total_cases_per_million`, `new_cases_per_million`, `new_cases_smoothed_per_million` |
| **Deaths** | `total_deaths`, `new_deaths`, `new_deaths_smoothed`, `total_deaths_per_million`, `new_deaths_per_million`, `new_deaths_smoothed_per_million` |
| **Hospitalization** | `icu_patients`, `icu_patients_per_million`, `hosp_patients`, `hosp_patients_per_million`, `weekly_icu_admissions`, `weekly_icu_admissions_per_million`, `weekly_hosp_admissions`, `weekly_hosp_admissions_per_million` |
| **Demographics** | `population_density`, `reproduction_rate` |

> `population_density` was kept here because it directly influences spread modeling and is needed in the same analytical context as cases/deaths.

---

### Table 2: `CovidVaccinations`
> *Tracks vaccination rollout across countries over time.*

| Column Group | Columns |
|---|---|
| **Join Keys** | `iso_code`, `continent`, `location`, `date` |
| **Vaccinations** | `new_vaccinations`, `total_vaccinations`, `people_vaccinated`, `people_fully_vaccinated`, `total_boosters`, and related per-hundred fields |

---

### Why Split the Data?

| Reason | Explanation |
|---|---|
| **Clarity** | Each table has a single, well-defined subject |
| **Performance** | Smaller tables = faster queries |
| **Join-ready design** | Both tables share `location + date` as join keys |
| **Real-world alignment** | In production, health and vaccination data come from separate sources |

**Primary Join Key:** `location + date`

---

## 🔍 Analysis Performed

### Part 1 — Deaths Analysis (`CovidDeaths`)

| Analysis | Description |
|---|---|
| **Death Percentage** | `total_deaths / total_cases * 100` — likelihood of dying if infected, per country |
| **Egypt Focus** | Filtered death percentage specifically for Egypt |
| **Infection Rate vs Population** | `total_cases / population_density * 100` — share of population that contracted COVID |
| **Highest Infection Rate** | Countries ranked by max infection rate relative to population |
| **Highest Death Count** | Countries with the most total deaths |
| **Continent Death Count** | Continents ranked by total deaths |
| **Daily Global Death %** | Aggregated global new cases and deaths per day, with death percentage |
| **Overall Global Summary** | Single-row global totals: cases, deaths, death percentage |

---

### Part 2 — Vaccinations Analysis (`CovidDeaths` JOIN `CovidVaccinations`)

| Analysis | Description |
|---|---|
| **Basic Join** | Joined both tables on `location + date` |
| **Population vs Vaccinations** | Daily new vaccinations per country alongside population density |
| **Rolling Vaccinations (Window)** | Cumulative vaccination count per location using `SUM() OVER (PARTITION BY location ORDER BY date)` |
| **CTE Approach** | Same rolling logic wrapped in a CTE (`PopvsVac`) for cleaner calculation of vaccination % |
| **Temp Table Approach** | Same logic stored in a `TEMP TABLE` for reuse within the session |
| **View Creation** | Final query stored as a **BigQuery View** (`percentPopulationVaccinated`) for downstream visualization |

---

## 🧠 Key SQL Techniques Used

- `SAFE_DIVIDE()` — avoids division-by-zero errors without needing `CASE WHEN`
- `CAST(... AS INT64)` — handles columns stored as strings/floats
- `SUM() OVER (PARTITION BY ... ORDER BY ...)` — rolling window aggregations
- `WITH ... AS (CTE)` — modular query structure for multi-step calculations
- `CREATE TEMP TABLE` — session-scoped reusable result sets
- `CREATE VIEW` — persistent reusable queries for visualization layers
- `WHERE continent IS NOT NULL` — filters out aggregated rows (World, continents, income groups)

---

## 🏗️ Project Structure

```
covid-data-analysis/
│
├── README.md                        ← You are here
├── analytical_thinking.md           ← Thought process & query breakdown
│
├── 1_deaths_exploration.sql         ← Cases, deaths, infection rates, global aggregates
├── 2_vaccinations_exploration.sql   ← JOIN + rolling vaccinations + CTE
└── 3_views_and_temp_tables.sql      ← Temp table + CREATE VIEW for visualization
│
├── CovidDeaths.csv                  ← Daily cases, deaths, hospitalization per country
└── CovidVaccination.csv             ← Daily vaccination rollout per country
```

---

## 🛠️ Tools & Environment

| Tool | Usage |
|---|---|
| **Google BigQuery** | SQL engine — all queries written and executed here |
| **Our World in Data** | Source dataset |
| **Google Sheets / Tableau** | Intended for downstream visualization via the created View |

---

## 📊 Dataset Source

- **Name:** COVID-19 Complete Dataset
- **Provider:** [Our World in Data](https://ourworldindata.org/covid-deaths)
- **Coverage:** All countries, full pandemic timeline
- **Columns:** 67 fields covering cases, deaths, hospitalization, vaccinations, testing, and demographics

---

*This project is part of a growing data portfolio focused on real-world datasets and reproducible SQL analysis.*
