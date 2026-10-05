WITH raw_hire AS (
    SELECT
        CAST(rental_id AS INT64) AS rental_id,
        CAST(duration AS INT64) AS duration_seconds,
        CAST(bike_id AS INT64) AS bike_id,
        CAST(start_date AS TIMESTAMP) AS start_date,
        CAST(start_station_id AS INT64) AS start_station_id,
        CAST(start_station_name AS STRING) AS start_station_name,
        CAST(end_date AS TIMESTAMP) AS end_date,
        CAST(end_station_id AS INT64) AS end_station_id,
        CAST(end_station_name AS STRING) AS end_station_name
    FROM {{ source('london_bicycles_raw', 'cycle_hire') }}
    WHERE rental_id IS NOT NULL
      AND duration > 0
      AND start_station_id IS NOT NULL
)

SELECT * FROM raw_hire
