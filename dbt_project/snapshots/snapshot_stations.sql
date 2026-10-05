{% snapshot snapshot_stations %}

{{
    config(
      target_dataset='london_bicycles_snapshots',
      unique_key='station_id',
      strategy='check',
      check_cols=['station_name', 'bike_capacity'],
    )
}}

SELECT 
    station_id,
    station_name,
    latitude,
    longitude,
    bike_capacity
FROM {{ ref('stg_london_bicycles__stations') }}

{% endsnapshot %}
