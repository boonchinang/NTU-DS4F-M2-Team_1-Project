WITH stations_metadata AS (
    SELECT 
        station_id,
        station_name,
        latitude,
        longitude,
        bike_capacity
    FROM {{ ref('stg_london_bicycles__stations') }}
),

all_trip_stations AS (
    SELECT DISTINCT start_station_id AS station_id, start_station_name AS station_name 
    FROM {{ ref('stg_london_bicycles__hire') }}
    WHERE start_station_id IS NOT NULL
    UNION DISTINCT
    SELECT DISTINCT end_station_id AS station_id, end_station_name AS station_name 
    FROM {{ ref('stg_london_bicycles__hire') }}
    WHERE end_station_id IS NOT NULL
),

combined_stations AS (
    SELECT
        COALESCE(m.station_id, t.station_id) AS station_id,
        COALESCE(m.station_name, t.station_name, 'Unknown Station') AS station_name,
        COALESCE(m.latitude, 0.0) AS latitude,
        COALESCE(m.longitude, 0.0) AS longitude,
        COALESCE(m.bike_capacity, 0) AS bike_capacity,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(m.station_id, t.station_id) 
            ORDER BY (m.station_name IS NOT NULL) DESC, LENGTH(t.station_name) DESC
        ) AS rn
    FROM all_trip_stations t
    FULL OUTER JOIN stations_metadata m ON t.station_id = m.station_id
)

SELECT
    FARM_FINGERPRINT(CAST(station_id AS STRING)) AS station_key,
    station_id,
    station_name,
    latitude,
    longitude,
    bike_capacity
FROM combined_stations
WHERE rn = 1
