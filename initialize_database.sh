#!/bin/bash

#createdb nyc-taxi-data
docker run -v /Volumes/external/ride_max/postgresql/data:/var/lib/postgresql/data --name nyc-taxi-data -p 5436:5432 -d nyc-taxi-data

psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -f create_nyc_taxi_schema.sql

shp2pgsql -s 2263:4326 taxi_zones/taxi_zones.shp | psql -h localhost -p 5436 -U postgres -d nyc-taxi-data
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "CREATE INDEX index_taxi_zones_on_geom ON taxi_zones USING gist (geom);"
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "CREATE INDEX index_taxi_zones_on_locationid ON taxi_zones (locationid);"
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "VACUUM ANALYZE taxi_zones;"

shp2pgsql -s 2263:4326 nyct2010_15b/nyct2010.shp | psql -h localhost -p 5436 -U postgres -d nyc-taxi-data
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -f add_newark_airport.sql
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "CREATE INDEX index_nyct_on_geom ON nyct2010 USING gist (geom);"
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "CREATE INDEX index_nyct_on_ntacode ON nyct2010 (ntacode);"
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "VACUUM ANALYZE nyct2010;"

psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -f add_tract_to_zone_mapping.sql

cat data/fhv_bases.csv | psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "COPY fhv_bases FROM stdin WITH CSV HEADER;"
weather_schema="station_id, station_name, date, average_wind_speed, precipitation, snowfall, snow_depth, max_temperature, min_temperature"
cat data/central_park_weather.csv | psql  -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "COPY central_park_weather_observations (${weather_schema}) FROM stdin WITH CSV HEADER;"
psql -h localhost -p 5436 -U postgres -d nyc-taxi-data -c "UPDATE central_park_weather_observations SET average_wind_speed = NULL WHERE average_wind_speed = -9999;"
