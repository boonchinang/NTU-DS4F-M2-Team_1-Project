WITH hours AS (
    SELECT hour_of_day
    FROM UNNEST(GENERATE_ARRAY(0, 23)) AS hour_of_day
)

SELECT
    hour_of_day AS time_key,
    hour_of_day,
    CASE 
        WHEN hour_of_day BETWEEN 7 AND 9 THEN 'Morning Commute'
        WHEN hour_of_day BETWEEN 17 AND 19 THEN 'Evening Commute'
        WHEN hour_of_day BETWEEN 10 AND 16 THEN 'Midday Off-Peak'
        ELSE 'Night Off-Peak'
    END AS time_of_day_cat
FROM hours
