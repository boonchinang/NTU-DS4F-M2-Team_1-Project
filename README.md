# NTU-DS4F-M2-Team_1-Project: London Bicycles End-to-End Data Pipeline

An end-to-end production data engineering pipeline that ingests raw public data (~84 million records) from `bigquery-public-data.london_bicycles`, transforms it into an optimized **Star Schema** with **SCD Type 2 Snapshots**, validates data quality using **dbt test** (dbt-expectations) and **Great Expectations**, orchestrates tasks via **Dagster** (scheduled at **12:01 AM SGT / GMT+8** daily with manual UI trigger button), and provides interactive Jupyter analytics (`NTU-DS4F-M2-T1-Analysis.ipynb`).

---

### 📂 Project Directory Structure

```text
NTU-DS4F-M2-Team_1-Project/
├── .env                              # Hidden credentials pointer
├── .gitignore                        # Git security rules
├── README.md                         # Main step-by-step setup guide
├── .gcp/                             # Hidden service account key directory
│   └── sa_key.json
├── environment/                      # Conda environment specifications
│   └── env.yml
├── meltano-ingestion/                # Meltano ELT extraction & loading
│   ├── meltano.yml
│   └── README.md
├── dbt_project/                      # dbt transformation models & snapshots
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   ├── models/ (staging, marts)
│   ├── snapshots/ (snapshot_stations.sql)
│   └── README.md
├── great_expectations/               # Great Expectations quality gate
│   ├── run_validation.py
│   └── README.md
├── dagster-orchestration/            # Dagster orchestration & scheduling
│   ├── workspace.yaml
│   ├── repository.py
│   ├── schedules.py
│   ├── assets.py
│   └── README.md
├── report_presentation/              # Technical report & slide presentations
│   ├── TECHNICAL_REPORT_AND_SCHEMA_JUSTIFICATION.md
│   ├── london_bicycles_executive_summary.pptx
│   └── london_bicycles_executive_summary.pdf
├── architecture_diagram/             # Pipeline architecture diagram
│   └── architecture_diagram.drawio
└── notebook/                         # Analytics & quality audit notebook
    └── NTU-DS4F-M2-T1-Analysis.ipynb
```

---

### 🚀 Environment and GCP Dataset Setup
1. Navigate to the `environment/` directory and create the Conda virtual environment:
   ```bash
   cd environment
   conda env create --file env.yml
   conda activate ntu-ds4f-m2
   cd ..
   ```
2. Connect to your GCP Project, Create a new dataset in BigQuery, set the Data set ID as `london_bicycles_raw` and choose location `EU`.
---

### 🔒 Secure GCP Service Account Key Setup



To connect to your GCP Project `<GCP project id>` safely without committing credentials to Git:

1. Obtain your GCP Service Account JSON key file from GCP IAM Console with BigQuery Admin / Data Editor roles.

2. Save the key inside the hidden directory `.gcp/sa_key.json`:
```bash
mkdir -p .gcp
# Copy your downloaded JSON key to .gcp/sa_key.json
```
3. Ensure `.env` has the following setting:
```env
GCP_PROJECT_ID = <YOUR_GCP_PROJECT_ID>

GOOGLE_APPLICATION_CREDENTIALS = ../.gcp/sa_key.json
```

*(Note: `.env` and `.gcp/` are explicitly listed in `.gitignore` and will never be uploaded to GitHub).*

---

### ⚡ Accelerated Initial Data Load (~84M Rows SQL Setup)

Because `bigquery-public-data.london_bicycles` contains ~84 million rows of static historical trip data, extracting all 84M records line-by-line over network APIs takes several hours.
To speed up initial setup, execute an in-warehouse SQL `CREATE TABLE` query directly in your GCP BigQuery Console (`EU` location) under dataset `london_bicycles_raw`:

```sql
-- Run in GCP BigQuery Console (Dataset: london_bicycles_raw, Location: EU)
CREATE OR REPLACE TABLE `<GCP project id>.london_bicycles_raw.cycle_hire` AS
SELECT * FROM `bigquery-public-data.london_bicycles.cycle_hire`;

CREATE OR REPLACE TABLE `<GCP project id>.london_bicycles_raw.cycle_stations` AS
SELECT * FROM `bigquery-public-data.london_bicycles.cycle_stations`;
```

---

### 🚀 How to Run the Project

#### Option A: Complete Orchestration via Dagster (Recommended)

1. Navigate to `dagster-orchestration/`:
```bash
cd dagster-orchestration
```
2. Launch Dagster webserver:
```bash
dagster dev
```
3. Open `http://localhost:3000` in your web browser. Dagster will automatically orchestrate:
   * **Meltano** incremental ingestion
   * **dbt** Star Schema models & SCD Type 2 snapshots
   * **dbt test** (dbt-expectations) quality checks
   * **Great Expectations** SQLAlchemy statistical validations
   * Daily schedule running at **12:01 AM SGT (GMT+8)**, or click **"Launch Run"** for manual execution anytime.

---

#### Option B: Running Individual Pipeline Modules Manually

If you prefer to execute each pipeline stage step-by-step:

1. **Meltano Ingestion**:
```bash
cd meltano-ingestion
meltano config set meltano python python3.11
meltano --env-file=../.env run tap-bigquery target-bigquery
cd ..
```

2. **dbt Transformation & Quality Tests**:
```bash
cd dbt_project
dbt deps
dbt run
dbt snapshot
dbt test
cd ..
```

3. **Great Expectations Validation**:
```bash
cd great_expectations
python run_validation.py
cd ..
```

4. **Jupyter Analytics Notebook**: Open `notebook/NTU-DS4F-M2-T1-Analysis.ipynb` in VS Code, Jupyter Lab, or Google Colab to view live quality audits and interactive Plotly visualizations.
