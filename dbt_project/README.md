# dbt Core Transformation & Data Quality Layer

This directory transforms raw BigQuery data into an optimized **Star Schema** (`fact_rentals`, `dim_stations`, `dim_date`, `dim_time`) with **SCD Type 2 Snapshots** (`snapshot_stations`) and executes data quality assertions using **dbt-expectations**.

## 🚀 How to Run dbt Core Transformations

1. Navigate to the `dbt_project/` folder:
   ```bash
   cd dbt_project
   ```

2. Test database connection:
   ```bash
   dbt debug
   ```

3. Download required package dependencies (`dbt-expectations`):
   ```bash
   dbt deps
   ```

4. Run Star Schema models:
   ```bash
   dbt run
   ```

5. Execute SCD Type 2 Snapshots:  
   ```bash
   dbt snapshot
   ```

6. Run dbt-expectations quality assertions:
   ```bash
   dbt test
   ```
