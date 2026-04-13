# 🧠 Analysis Process — COVID-19 Data Exploration & Vaccination Analysis

This document walks through the complete analytical thinking behind this project using the **Google Data Analytics Framework**: Ask → Prepare → Process → Analyze → Share → Act.

---

## 1. 🙋 Ask — Define the Problem

Before touching any data, I defined the questions this analysis must answer:

**Primary business questions:**
1. How lethal is COVID-19? What percentage of confirmed cases resulted in death globally and per country?
2. Which countries and continents were hit hardest in terms of total deaths?
3. What share of each country's population was infected at its peak?
4. How does the vaccination rollout compare across countries over time?
5. Is there a meaningful relationship between vaccination speed and infection/death rates?

**Stakeholder perspective:**  
The audience for this analysis is a general public health stakeholder or a portfolio reviewer who needs to understand COVID-19 impact rapidly — no medical background assumed. The deliverable is a self-explanatory interactive dashboard alongside documented SQL logic.

**Scope boundary:**  
The analysis covers country-level and continental-level trends. Individual-level (demographic, age, co-morbidity) data is out of scope for this dataset.

---

## 2. 📦 Prepare — Understand and Source the Data

**Data source:**  
The dataset comes from [Our World in Data](https://ourworldindata.org/covid-deaths) — one of the most trusted, openly maintained COVID-19 repositories, updated daily from official government and WHO reports.

**Tables uploaded to BigQuery:**

| Table | Key Columns | Description |
|-------|------------|-------------|
| `CovidDeaths` | `location`, `date`, `total_cases`, `total_deaths`, `new_cases`, `new_deaths`, `population_density`, `continent` | Daily case and death counts per country |
| `CovidVaccination` | `location`, `date`, `new_vaccinations` | Daily new vaccinations administered per country |

**Data characteristics noted:**
- The `continent` column contains `NULL` for aggregated rows (World, continents, EU) — this requires explicit filtering.
- `total_deaths` is stored as STRING in some versions of the dataset → requires explicit `CAST(... AS INT64)` to avoid aggregation errors.
- `population_density` is used as a proxy for population size (as `population` column naming varied across dataset versions).
- Some days have `NULL` values for `new_vaccinations` — handled with `IFNULL(..., 0)` where needed.

**Data credibility check (ROCCC):**
- ✅ **Reliable** — sourced from official government reports
- ✅ **Original** — first-party data from Our World in Data
- ✅ **Comprehensive** — covers 200+ countries globally
- ✅ **Current** — dataset covers 2020–2021 vaccination period
- ✅ **Cited** — publicly available and well-documented

---

## 3. ⚙️ Process — Clean and Transform

All processing was done in **BigQuery Standard SQL**.

### Key cleaning decisions:

**1. Filtering aggregated rows**  
The source data includes rows for "World", "European Union", "International", and continents alongside country rows. Mixing these causes double-counting.

```sql
-- Keep only country-level rows
WHERE continent IS NOT NULL

-- Keep only continent-level rows (for continent analysis)
WHERE continent IS NULL
  AND location NOT IN ('World', 'European Union', 'International')
```

**2. Safe division to prevent divide-by-zero errors**  
Instead of raw division, `SAFE_DIVIDE()` was used throughout to return `NULL` instead of crashing on zero denominators:
```sql
SAFE_DIVIDE(total_deaths, total_cases) * 100 AS DeathPercentage
```

**3. Type casting**  
`new_deaths` and `total_deaths` were cast to `INT64` before aggregation:
```sql
SUM(CAST(new_deaths AS INT64)) AS total_deaths
```

**4. NULL handling in Tableau prep queries**  
For the time-series chart, `NULL` infection counts and rates were replaced with `0` using `IFNULL()` to avoid gaps in the visualization:
```sql
IFNULL(total_cases, 0) AS HighestInfectionCount,
IFNULL(SAFE_DIVIDE(total_cases, population_density) * 100, 0) AS PercentPopulationInfected
```

**5. Reusable view for vaccination data**  
A BigQuery `VIEW` was created to store the cleaned vaccination join query, making it available for future queries without repeating the logic:
```sql
CREATE VIEW `coivid19.percentPopulationVaccinated` AS ...
```

---

## 4. 🔬 Analyze — Extract Insights

Analysis was structured in progressive layers of depth:

### Layer 1 — Death Rate (Case Fatality Rate)
- Computed `DeathPercentage = total_deaths / total_cases * 100` per country per day.
- Confirmed: Egypt's CFR consistently exceeded the global average during wave peaks, indicating strain on healthcare capacity or reporting differences.

### Layer 2 — Infection Rate vs. Population
- Computed what percentage of each country's population ever tested positive.
- Key finding: Smaller nations (San Marino, Andorra, Gibraltar) had the highest infection rates — a result of dense populations and high testing-to-population ratios, not necessarily higher spread.

### Layer 3 — Total Death Toll Ranking
- Aggregated `MAX(total_deaths)` per country → ranked globally.
- Aggregated by continent → North America and South America had the highest absolute death tolls, reflecting both population size and limited early healthcare response.

### Layer 4 — Global Daily Aggregation
- Grouped `SUM(new_cases)` and `SUM(new_deaths)` by `date` globally to compute a daily global CFR time series.
- Revealed the CFR declined over time as testing improved (more cases detected, denominator grew faster than deaths).

### Layer 5 — Rolling Vaccination Analysis (Window Function + CTE)
- Used `SUM() OVER (PARTITION BY location ORDER BY date)` to calculate cumulative vaccinations per country.
- Wrapped in a CTE (`PopvsVac`) to then compute `(RollingPeopleVaccinated / population_density) * 100` as vaccination coverage %.
- Also stored as a TEMP TABLE and VIEW for reproducibility.

### Key metrics derived:

| Metric | Global Value (approx.) |
|--------|----------------------|
| Total Confirmed Cases | ~150 million (as of dataset cutoff) |
| Total Deaths | ~3.2 million |
| Global Death % | ~2.1% |
| Most deaths (country) | United States |
| Most deaths (continent) | North America |
| Highest infection rate (%) | San Marino, Andorra |

---

## 5. 📊 Share — Communicate the Findings

**Visualization tool:** Tableau Public  
**Dashboard:** [COVID-19 Dashboard](https://public.tableau.com/app/profile/adham.eltantawi1075/viz/CovidDashboard_17760856542580/Dashboard1?publish=yes)

The dashboard was built on **4 pre-aggregated query outputs** from `covid_tableau_data_prep.sql`:

| Tableau Table | Chart Type | Insight Communicated |
|--------------|-----------|---------------------|
| `global_summary_metrics` | KPI scorecard | Snapshot of global scale at a glance |
| `total_deaths_by_location` | Horizontal bar chart | Which continents suffered most |
| `infection_rate_by_location` | Choropleth world map | Geographic spread and severity by country |
| `daily_infection_trend` | Multi-line time-series | Country-level infection trajectory over time |

**Design choices:**
- A dark background was chosen to give the dashboard a serious, data-journalism aesthetic appropriate to the subject matter.
- The map uses a diverging color scale (light → dark red) so severity is immediately readable without reading numbers.
- A continent-level filter allows stakeholders to drill down regionally.

---

## 6. 🚀 Act — Recommendations & Next Steps

Based on the findings, the following actions and extensions are recommended:

### For public health decision-makers:
- **Prioritize healthcare infrastructure investment** in countries with high CFR — a high death-to-case ratio signals either late-stage detection or overwhelmed systems, not just viral severity.
- **Accelerate equitable vaccine distribution** — the time-series data shows high-income countries vaccinated 40%+ of their population while low-income countries remained below 5% through mid-2021.

### For further analytical depth:
- [ ] **Join with demographic data** (median age, GDP per capita, healthcare index) to model which factors most predict high CFR.
- [ ] **Add vaccination lag analysis** — measure the delay between vaccination milestones and observable drops in death rates.
- [ ] **Extend the dataset to 2022–2023** to capture Omicron wave dynamics and booster shot effects.
- [ ] **Build a predictive model** (e.g., logistic regression) to estimate peak infection rates in unreported regions.

---

> *This project was completed as part of a data analytics portfolio. All SQL was written by hand in BigQuery Standard SQL. Visualization built in Tableau Public.*  
> **Author: Adham Eltantawi**
