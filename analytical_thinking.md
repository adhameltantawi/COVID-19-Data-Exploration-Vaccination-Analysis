# 🧠 Analytical Thinking — COVID-19 SQL Project

> How I approached this analysis, query by query.

---

## 🎯 The Questions I Started With

Before writing a single query, I asked myself:

1. What does the raw data look like? How many columns? Any nulls?
2. How deadly was COVID per country? — deaths / cases
3. How widespread was it? — cases / population
4. Which countries were hit hardest?
5. How did the world do overall? — global totals
6. How fast did vaccines roll out? — needs a join with the vaccinations table

---

## 🏗️ Data Architecture Decision

**Problem:** The original dataset had 67 columns mixing cases, deaths, AND vaccinations all in one table.

**Decision:** Split into `CovidDeaths` + `CovidVaccinations` — each table has one clear responsibility.

| Reason | Explanation |
|---|---|
| Clarity | Each table has a single, well-defined subject |
| Performance | Smaller tables = faster queries |
| Join-ready design | Both tables share `location + date` as join keys |
| Real-world alignment | In production, health and vaccination data come from separate sources |

**Primary Join Key:** `location + date`

---

## 🔄 My 4-Phase Analytical Flow

### Phase 1 — Explore
`SELECT *` on both tables. Look at what's there before assuming anything.

### Phase 2 — Clean the Scope
Add `WHERE continent IS NOT NULL` everywhere.
BigQuery includes rows for "World", "Asia", "High income", etc. These inflate numbers — filter them out globally.

### Phase 3 — Analyze Deaths
Work inside `CovidDeaths` only. Start simple (death %), then rank (top countries, continents). Build up complexity step by step.

### Phase 4 — Add Vaccinations
JOIN both tables. First verify the join produces expected output, then build the rolling `SUM` window. Then refactor: raw JOIN → CTE → Temp Table → View.

---

## 📋 Query-by-Query Breakdown

### `01` — Explore Deaths Table
**What:** `SELECT *` ordered by location, date  
**Technique:** Full table scan  
**Why:** Never assume. Look at the raw data first to understand columns, nulls, and data types.

---

### `02` — Filter to Countries Only
**What:** Add `WHERE continent IS NOT NULL`  
**Technique:** NULL filter to exclude aggregated rows  
**Why:** BigQuery includes rows for 'World', 'Asia', 'High income', etc. These inflate numbers. This filter goes on every query from here on.

---

### `03` — Core Fields Selection
**What:** Select `location, date, total_cases, new_cases, total_deaths, population_density`  
**Technique:** Column selection  
**Why:** Reduce noise. Work with only the columns relevant to the analysis questions.

---

### `04` — Death Percentage
**What:** `total_deaths / total_cases * 100` per country per day  
**Technique:** `SAFE_DIVIDE()` — avoids division-by-zero without `CASE WHEN`  
**Why:** Shows the fatality rate if you contract COVID. `SAFE_DIVIDE` handles early-pandemic days when cases = 0.

---

### `05` — Egypt Death % Filter
**What:** Same as above, filtered with `WHERE location LIKE '%Egypt%'`  
**Technique:** `LIKE` pattern match  
**Why:** Personal context — wanted to see Egypt specifically. Also validates the query works correctly on a known case.

---

### `06` — Infection Rate vs Population
**What:** `total_cases / population_density * 100` per country per day  
**Technique:** Ratio calculation  
**Why:** Death % tells you *how deadly* it is. Infection rate tells you *how widespread* it is. Different question entirely.

---

### `07` — Highest Infection Rate by Country
**What:** `GROUP BY location`, `MAX(total_cases)`, divide by population  
**Technique:** `GROUP BY` + `MAX()` for country-level peak comparison  
**Why:** Ranking countries by peak infection rate gives a comparative view of how badly each was hit.

---

### `08` — Highest Death Count by Country
**What:** `GROUP BY location`, `MAX(total_deaths)` ordered descending  
**Technique:** `GROUP BY` + `MAX()` + `ORDER BY DESC`  
**Why:** Absolute death toll is different from death %. A country with a low % but huge population can still have massive deaths.

---

### `09` — Continent Death Ranking
**What:** Same death count logic, grouped by continent  
**Technique:** Same `GROUP BY` structure at continent level  
**Why:** Zoom out from countries to continents — see regional patterns.

---

### `10` — Daily Global Death %
**What:** `SUM(new_cases)`, `SUM(new_deaths)` per date globally, then death %  
**Technique:** Global `SUM` aggregation + `SAFE_DIVIDE`  
**Why:** Track the death rate over time globally — was it getting better or worse as the pandemic evolved?

---

### `11` — Global Totals (One Row)
**What:** Single-row global summary: total cases, deaths, death %  
**Technique:** Full aggregation with no `GROUP BY`  
**Why:** A headline number. Quick sanity check and summary statistic for the whole dataset.

---

### `12` — Join Deaths + Vaccinations
**What:** `JOIN` both tables `ON location + date`  
**Technique:** `INNER JOIN` on composite key  
**Why:** First join step. Verify the join produces expected output before adding any complexity.

---

### `13` — Population vs New Vaccinations
**What:** Daily new vaccinations per country alongside population density  
**Technique:** Basic JOIN with column selection  
**Why:** Understand scale — how many people were being vaccinated each day relative to population?

---

### `14` — Rolling Vaccinations (Window Function)
**What:** `SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date)`  
**Technique:** Window function — running total partitioned by country  
**Why:** Cumulative totals matter more than daily counts. This builds "total vaccinated so far" per country over time.

---

### `15` — CTE + Vaccination %
**What:** Wrap rolling logic in a CTE, then compute `RollingVaccinated / population * 100`  
**Technique:** `WITH` clause (CTE)  
**Why:** The window function result can't be reused in the same `SELECT`. A CTE makes it clean and avoids a messy subquery.

---

### `16` — Temp Table Approach
**What:** Same logic stored as `CREATE TEMP TABLE`, queried separately  
**Technique:** `TEMP TABLE` — session-scoped result set  
**Why:** Useful when you need to query the result multiple times or inspect it mid-analysis. Gets cleaned up automatically after the session ends.

---

### `17` — Create View
**What:** `CREATE VIEW` storing the full rolling vaccination logic  
**Technique:** Persistent view for downstream tools  
**Why:** The final step. Views let Tableau, Sheets, or any BI tool query the result without re-running the full JOIN + window logic every time.

---

## 🔄 Refactoring Journey — The Vaccination Query

The same analysis was written four different ways. Each version has a different purpose:

| Version | How It Works | When to Use |
|---|---|---|
| **Raw JOIN** | Select `new_vaccinations` directly from the join | Just need daily raw numbers |
| **Window Function** | Add `SUM() OVER (...)` inside the same SELECT | One-off rolling total, all in one query |
| **CTE** | Wrap window in `WITH`, compute % in outer SELECT | Need further calculations on the window result — more readable |
| **Temp Table** | `CREATE TEMP TABLE`, then query separately | Active analysis sessions — inspect the intermediate result or run multiple queries on it |
| **View** | `CREATE VIEW` — stored query in the database | Production/visualization — any BI tool connects to it directly |

---

## 🛠️ SQL Techniques Glossary

| Technique | What It Does | Why I Used It Here |
|---|---|---|
| `SAFE_DIVIDE(a, b)` | Divides a by b, returns NULL if b = 0 | Handles days with 0 cases without verbose `CASE WHEN` |
| `WHERE continent IS NOT NULL` | Filters rows where continent is NULL | Removes aggregated rows (World, continents, income groups) |
| `CAST(col AS INT64)` | Converts column to 64-bit integer | Some numeric columns loaded as strings in BigQuery |
| `SUM() OVER (PARTITION BY ... ORDER BY ...)` | Running total per partition without collapsing rows | Cumulative vaccinations per country over time |
| `WITH cte AS (...)` | Names a subquery so it can be referenced like a table | Can't reference a window function result in the same SELECT |
| `CREATE TEMP TABLE` | Session-scoped table, auto-deleted after session | Intermediate result needed more than once in a session |
| `CREATE VIEW` | Stores a query as a named reusable database object | Final output layer for BI tools and visualization |
| `GROUP BY + MAX()` | Returns the maximum value per group | Peak infection/death counts — one row per country |
| `JOIN ... ON a.col = b.col AND a.col2 = b.col2` | Joins on a composite key | Neither location nor date alone is unique across both tables |
