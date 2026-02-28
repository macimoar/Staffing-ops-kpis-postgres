# Staffing Operations KPI Analytics (Postgres SQL Project)

This project simulates a real-world analytics environment for an IT staffing / consulting company using PostgreSQL.  
It includes schema design, synthetic data generation, KPI queries, and data quality checks covering recruiting, sales, pipeline, and delivery performance.

The goal of this project is to demonstrate practical SQL skills applied to realistic business problems.


---

## Project Overview

Staffing companies track performance across several areas:

- Recruiting pipeline
- Client job requests
- Candidate funnel conversion
- Placement delivery
- Bill rate / pay rate margins
- Data quality validation

This project builds a small analytics layer that could be used by operations, recruiting, or finance teams.


---

## Tech Stack

- PostgreSQL (Supabase)
- SQL
- GitHub
- Synthetic dataset generated with SQL

No external BI tool is used — all KPIs are computed directly in SQL.


---

## Database Schema

Tables included:

- candidates
- jobs
- applications
- interviews
- offers
- placements

These tables model a simplified staffing workflow:

Candidate → Application → Interview → Offer → Placement


---

## File Structure
sql/
  00_schema.sql
  01_seed_data.sql
  02_kpis_pipeline.sql
  03_kpis_recruiting.sql
  04_kpis_sales
  05_kpis_delivery.sql
  06_data_quality_checks.sql

docs/
  kpi_dictionary.md

---

## How to Run

1. Create a PostgreSQL database (Supabase used for this project)
2. Run:

```
sql/00_schema.sql
```

3. Load sample data:

```
sql/01_seed_data.sql
```

4. Run KPI queries:

```
sql/02_kpis_pipeline.sql
sql/03_kpis_recruiting.sql
sql/04_kpis_sales.sql
sql/05_kpis_delivery.sql
sql/06_data_quality_checks.sql
```

---

## Example KPIs

Pipeline metrics
- Job aging
- Funnel conversion rates
- Time to fill

Recruiting metrics
- Source effectiveness
- Interview pass rate
- Offer acceptance rate

Sales metrics
- Fill rate by client
- Average bill rate
- Margin %

Delivery metrics
- Active placements
- Early termination rate
- Margin run rate

Data quality checks
- Invalid margins
- Missing placements
- Inconsistent status values
- Orphan records

See:

```
docs/kpi_dictionary.md
```

for definitions.


---

## Why This Project Exists

This project was built to demonstrate:

- SQL for analytics, not just syntax practice
- Understanding of business KPIs
- Ability to design schema + queries
- Experience working with realistic operational data
- Data validation / data quality awareness


---

## Author

Brian Ceradsky

Interested in roles involving:

- Data Analytics
- Data Engineering
- Software / Systems Development
- Technical Operations

```
Built while learning PostgreSQL and refreshing SQL skills.
```
