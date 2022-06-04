DROP SERVER IF EXISTS atu_nuts_codes CASCADE;

CREATE SERVER atu_nuts_codes FOREIGN DATA WRAPPER ogr_fdw OPTIONS (
  datasource 'D:\osm\csp\atu_nuts_codes.csv'
  ,format 'CSV'
  );

ALTER SERVER atu_nuts_codes OWNER TO osm;

DROP SCHEMA IF EXISTS csp CASCADE;

CREATE SCHEMA IF NOT EXISTS csp;

ALTER SCHEMA csp OWNER TO osm;

GRANT ALL ON SCHEMA csp TO osm;

IMPORT FOREIGN SCHEMA ogr_all FROM SERVER atu_nuts_codes INTO csp;