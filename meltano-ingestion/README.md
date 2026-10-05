### Meltano Data Ingestion Module

This module manages extraction and loading of London Bicycles incremental datasets from `bigquery-public-data.london_bicycles` into GCP BigQuery dataset `london_bicycles_raw`.

#### Step-by-Step Instructions:

1. Navigate to this folder:
```bash
cd meltano-ingestion
```

2. Configure python executable for Meltano:
```bash
meltano config set meltano python python3.11
```

3. Run the extraction and loading pipeline:
```bash
meltano --env-file=../.env run tap-bigquery target-bigquery
```
