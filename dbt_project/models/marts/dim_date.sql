WITH date_spine AS (
    SELECT 
        date_day AS full_date
    FROM UNNEST(
        GENERATE_DATE_ARRAY('2015-01-01', '2025-12-31', INTERVAL 1 DAY)
    ) AS date_day
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date) AS year,
    EXTRACT(MONTH FROM full_date) AS month,
    FORMAT_DATE('%B', full_date) AS month_name,
    EXTRACT(DAY FROM full_date) AS day_of_month,
    EXTRACT(DAYOFWEEK FROM full_date) AS day_of_week_num,
    FORMAT_DATE('%A', full_date) AS day_of_week_name,
    CASE WHEN EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_spine
