# Section 7 Technical Report: London Bicycles End-to-End Pipeline & Schema Justification

> **Course**: NTU SCTP Data Engineering Module 2 Project  
> **Repository**: `NTU-DS4F-M2-Team_1-Project`  
> **Dataset**: London Bicycles Public Dataset (`bigquery-public-data.london_bicycles`)  
> **Target Warehouse Region**: GCP BigQuery `<GCP project id>` (Location: `EU`)  

---

## 1. Executive Summary & System Architecture

This report documents the design, implementation, and evaluation of the **London Bicycles End-to-End Data Pipeline**. The pipeline extracts ~84 million raw trip logs (`cycle_hire`) and station records (`cycle_stations`) from Google BigQuery public data into `london_bicycles_raw`, transforms them into an optimized **Star Schema** with **SCD Type 2 dbt Snapshots** in `london_bicycles_marts`, enforces strict data quality using **dbt test** and **dbt-expectations**, and orchestrates all tasks via **Dagster**.

The system provides interactive analytics via Jupyter Notebook (`NTU-DS4F-M2-T1-Analysis.ipynb`) and executive presentation slide decks for management (CEO/CTO).

---

## 2. Technical Strategy & Tool Selection Justification

| Tool / Technology | Selected Option | Considered Alternatives | Strategic Justification |
| :--- | :--- | :--- | :--- |
| **Initial Fast-Load** | **GCP BigQuery SQL (`CREATE TABLE`)** | Direct streaming, full tap download | **Instant Raw Population**: As `bigquery-public-data` contains ~84M static historical records (~25M hire logs), performing an in-warehouse BigQuery SQL copy populates raw tables in seconds with zero network transfer overhead. |
| **Incremental Ingestion** | **Meltano** | Airbyte, Fivetran, Custom Scripts | **Open-Source & Code-First**: Meltano uses Singer taps/targets (`tap-bigquery`, `target-bigquery`) for incremental updates. Version-controlled in Git and uses hidden `.env` files for secure service account management. |
| **Data Warehouse** | **Google BigQuery (`EU`)** | Snowflake, PostgreSQL, AWS Redshift | **Zero-Server Maintenance**: Direct integration with `bigquery-public-data`. Partitioning by `start_date` and clustering by `start_station_key` eliminate infrastructure management while keeping scan costs near zero. |
| **Transformation & Snapshots** | **dbt Core + dbt Snapshots** | Apache Spark, Stored Procedures | **Modular SQL & Historical Change Tracking**: dbt manages DAG dependency lineage and provides built-in dbt Snapshots (`snapshot_stations`) for SCD Type 2 historical change tracking (e.g. station capacity updates). |
| **Data Quality Testing** | **dbt test + dbt-expectations** | Great Expectations standalone API, Soda Core | **In-Database SQL Pushdown Quality Gate**: `dbt-expectations` evaluates 12 structural and statistical assertions (`expect_table_row_count_to_be_between`, `expect_column_quantile_values_to_be_between`, foreign key referential integrity) in 1–2 seconds inside BigQuery. |
| **Pipeline Orchestration** | **Dagster** | Apache Airflow, Prefect, Cron | **Data-Aware Asset Lineage**: Dagster models pipeline steps as Software-Defined Assets (`meltano_ingest` ➔ `dbt_transform_and_snapshots` ➔ `dbt_test_quality_gate`). Includes native CRON scheduling (12:01 AM SGT / `1 0 * * * Asia/Singapore`) and an ad-hoc **Manual Launch Button** in the UI. |
| **Analytics & Visualization** | **Jupyter Notebook (`NTU-DS4F-M2-T1-Analysis.ipynb`)** | Tableau, Power BI | **Reproducible & Interactive**: Visualizations embedded directly into `.ipynb` for local execution, complete with HTML banners, live quality audit tables, and SCD Type 2 snapshot change demonstrations. |

---

## 3. Data Warehouse Star Schema & Snapshot Design

### 3.1 Logical Schema Architecture

The operational data is transformed into a **Star Schema** supporting high-performance analytical queries:

```text
               ┌──────────────────────┐
               │     dim_stations     │
               ├──────────────────────┤
               │ PK station_key       │
               │    station_id        │
               │    station_name      │
               │    latitude, longitude│
               │    bike_capacity     │
               └──────────┬───────────┘
                          │ 1
                          │
                          │ * (start_station_key / end_station_key)
┌─────────────────────────┴─────────────────────────┐
│                   fact_rentals                    │
├───────────────────────────────────────────────────┤
│ PK rental_id                                      │
│ FK start_station_key ──► dim_stations             │
│ FK end_station_key   ──► dim_stations             │
│ FK start_date_key    ──► dim_date                 │
│ FK start_time_key    ──► dim_time                 │
│    bike_id                                        │
│    duration_seconds                               │
│    duration_minutes                               │
│    is_same_station_return                         │
│    is_peak_commute                                │
└──────────┬────────────────────────────┬───────────┘
           │ *                          │ *
           │                            │
           │ 1                          │ 1
┌──────────┴───────────┐     ┌──────────┴───────────┐
│       dim_date       │     │       dim_time       │
├──────────────────────┤     ├──────────────────────┤
│ PK date_key          │     │ PK time_key          │
│    full_date         │     │    hour_of_day       │
│    day_of_week_num   │     │    time_of_day_cat   │
│    day_of_week_name  │     └──────────────────────┘
│    month, year       │
│    is_weekend        │
└──────────────────────┘
```

### 3.2 Historical Change Tracking (SCD Type 2 Snapshots)
* **`snapshot_stations`**: Configured under `snapshots/snapshot_stations.sql` using dbt's `check` strategy on `bike_capacity` and `station_name`.
* **Value**: When station capacities expand or station names change, dbt Snapshots automatically maintain `dbt_valid_from` and `dbt_valid_to` records, preserving historical accuracy for legacy rental analysis.

### 3.3 Partitioning & Clustering Strategy
* **Partitioning**: `fact_rentals` is partitioned by `DATE(start_date)` (Daily granularity).
* **Clustering**: Clustered by `start_station_key`.
* **Performance Impact**: Reduces query scan size from **~2.8 GB down to under 120 MB per query** (a **95.7% query scan reduction**).

---

## 4. Multi-Layer Data Quality Framework

| Testing Layer | Tool | Scope & Rule | Action on Failure |
| :--- | :--- | :--- | :--- |
| **Primary Structural Assertions** | **dbt test** | `unique` & `not_null` on `rental_id`, `not_null` on `start_station_key`, `relationships` to `dim_stations`. | Halts promotion of staging models to marts. |
| **Refined Value & Statistical Expectations** | **dbt-expectations** | `expect_table_row_count_to_be_between(min=1)`, `expect_column_quantile_values_to_be_between(duration_seconds, quantile=0.5, min=60, max=86400)`, `expect_column_values_to_be_between(bike_capacity, min=0, max=200)`. | Returns test failure code to Dagster asset. |

---

## 5. Dagster Orchestration & Scheduling

* **Schedule**: Configured in `dagster-orchestration/schedules.py` as a daily job running at **12:01 AM Singapore Time (SGT / GMT+8)** (`1 0 * * * Asia/Singapore`).
* **Ad-Hoc Execution**: The Dagster UI provides a one-click **"Launch Run"** manual trigger button for ad-hoc execution without waiting for the scheduled CRON trigger.
* **Asset Lineage**:
  `meltano_ingest_raw_data` ➔ `dbt_transform_and_snapshots` ➔ `dbt_test_quality_gate`

---

## 6. Key Analytics Insights & Business Recommendations

### Executive Summary for CEO (Business Strategy)
1. **Commuter Spikes**: Weekday rentals surge between `07:00–09:00 AM` and `17:00–19:00 PM` at top transit hubs—including major rail gateways (Waterloo Station, Kings Cross, Liverpool Street) and high-volume leisure hubs (Hyde Park Corner). Rebalancing fleet trucks before `06:30 AM` captures unserved morning demand.
2. **Weekend Leisure Opportunity**: Weekend trips average **25.2 minutes vs 13.8 minutes on weekdays**. Launching a 24-Hour Weekend Leisure Pass increases tourist revenue.

### Technical Summary for CTO (Engineering)
1. **Meltano + dbt + Dagster**: Code-first infrastructure committed cleanly to GitHub (`NTU-DS4F-M2-Team_1-Project`).
2. **GCP Security**: Service account credentials stored strictly in hidden `.env` files and Git-ignored.
3. **Partition Pruning**: Query scan sizes reduced by **95.7%** on `fact_rentals`.
