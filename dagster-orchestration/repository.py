import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import assets
import schedules
from dagster import Definitions

defs = Definitions(
    assets=[
        assets.meltano_ingest_raw_data,
        assets.dbt_transform_and_snapshots,
        assets.dbt_test_quality_gate
    ],
    schedules=[
        schedules.daily_pipeline_schedule
    ]
)
