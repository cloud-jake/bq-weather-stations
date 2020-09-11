-- Get nearest weather station by geo coordinates

with my_location as (
  SELECT  ST_GEOGPOINT(-73.764, 41.197) as my_location,
          'Chappaqua' as home
), stations as (
  SELECT *, ST_GEOGPOINT(lon,lat) as latlon_geo
  FROM `bigquery-public-data.noaa_gsod.stations` 
), get_closest as (
  SELECT home,my_location, st.*, 
  FROM (
    SELECT ST_ASTEXT(my_location) as my_location, 
           home,
           ARRAY_AGG( # get the closest station
              STRUCT(usaf,wban,name,lon,lat,country,state,
                    ST_DISTANCE(my_location, b.latlon_geo)*0.00062137 as miles)
           ) as stations
    FROM my_location a, stations b
    WHERE ST_DWITHIN(my_location, b.latlon_geo, 32187)  --meters = 20 miles
    GROUP BY my_location, home
  ), UNNEST(stations) as st
)  -- Thanks to Felipe Hoffa - https://stackoverflow.com/a/53678307/11748236

-- get count of data points from closest stations for 2011-2020
SELECT gc.*, COUNT(temp) as Data_Points
FROM get_closest gc, `bigquery-public-data.noaa_gsod.gsod20*` gs
WHERE max != 9999.9 # code for missing data
AND   _TABLE_SUFFIX BETWEEN '11' AND '20'
AND   gc.usaf = gs.stn
AND   gc.wban = gs.wban

GROUP BY home, my_location, usaf, wban, name, lon, lat, country, state, miles
ORDER BY miles ASC
