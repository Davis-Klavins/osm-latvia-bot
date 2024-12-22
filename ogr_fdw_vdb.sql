DROP SERVER IF EXISTS vdb CASCADE;

CREATE SERVER vdb FOREIGN DATA WRAPPER ogr_fdw OPTIONS (
  datasource '/data/osm/lgia/vdb_orig.csv'
  ,format 'CSV'
  );

ALTER SERVER vdb OWNER TO osm;

DROP SCHEMA IF EXISTS lgia CASCADE;

CREATE SCHEMA IF NOT EXISTS lgia;

ALTER SCHEMA lgia OWNER TO osm;

GRANT ALL ON SCHEMA lgia TO osm;

DROP FOREIGN TABLE IF EXISTS lgia.vdb_orig;

IMPORT FOREIGN SCHEMA ogr_all FROM SERVER vdb INTO lgia;