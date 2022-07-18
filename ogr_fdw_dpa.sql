DROP SERVER IF EXISTS dpa CASCADE;

CREATE SERVER dpa FOREIGN DATA WRAPPER ogr_fdw OPTIONS (
  datasource 'D:\osm\csp\dpa', 
  format 'ESRI Shapefile'
);

ALTER SERVER dpa OWNER TO osm;

IMPORT FOREIGN SCHEMA ogr_all FROM SERVER dpa INTO csp;