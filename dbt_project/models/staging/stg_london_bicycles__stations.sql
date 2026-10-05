WITH raw_stations AS (
    SELECT
        CAST(id AS INT64) AS station_id,
        CAST(name AS STRING) AS station_name,
        CAST(latitude AS FLOAT64) AS latitude,
        CAST(longitude AS FLOAT64) AS longitude,
        CAST(bikes_count AS INT64) AS bike_capacity,
        CAST(install_date AS TIMESTAMP) AS install_date
    FROM {{ source('london_bicycles_raw', 'cycle_stations') }}
    WHERE id IS NOT NULL
)

SELECT * FROM raw_stations
