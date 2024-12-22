DROP SERVER IF EXISTS vzd_shp CASCADE;

CREATE SERVER vzd_shp FOREIGN DATA WRAPPER ogr_fdw OPTIONS (
  datasource '/data/osm/vzd', 
  format 'ESRI Shapefile'
);

ALTER SERVER vzd_shp OWNER TO osm;

DROP SCHEMA IF EXISTS vzd CASCADE;

CREATE SCHEMA IF NOT EXISTS vzd;

ALTER SCHEMA vzd OWNER TO osm;

GRANT ALL ON SCHEMA vzd TO osm;

IMPORT FOREIGN SCHEMA ogr_all FROM SERVER vzd_shp INTO vzd;
