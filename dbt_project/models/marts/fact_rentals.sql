{{
    config(
        materialized='table',
        partition_by={
            "field": "start_date",
            "data_type": "date",
            "granularity": "day"
        },
        cluster_by=["start_station_key"]
    )
}}

WITH hire_data AS (
    SELECT * FROM {{ ref('stg_london_bicycles__hire') }}
)

SELECT
    h.rental_id,
    FARM_FINGERPRINT(CAST(h.start_station_id AS STRING)) AS start_station_key,
    FARM_FINGERPRINT(CAST(h.end_station_id AS STRING)) AS end_station_key,
    CAST(FORMAT_DATE('%Y%m%d', DATE(h.start_date)) AS INT64) AS start_date_key,
    EXTRACT(HOUR FROM h.start_date) AS start_time_key,
    DATE(h.start_date) AS start_date,
    h.bike_id,
    h.duration_seconds,
    ROUND(h.duration_seconds / 60.0, 2) AS duration_minutes,
    CASE WHEN h.start_station_id = h.end_station_id THEN TRUE ELSE FALSE END AS is_same_station_return,
    CASE WHEN EXTRACT(HOUR FROM h.start_date) IN (7, 8, 9, 17, 18, 19) THEN TRUE ELSE FALSE END AS is_peak_commute
FROM hire_data h
