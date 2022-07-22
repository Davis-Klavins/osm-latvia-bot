DROP SERVER IF EXISTS vdb CASCADE;

CREATE SERVER vdb FOREIGN DATA WRAPPER ogr_fdw OPTIONS (
  datasource 'D:\osm\lgia\VDB_OBJEKTI.xlsx'
  ,format 'XLSX'
  );

ALTER SERVER vdb OWNER TO osm;

DROP SCHEMA IF EXISTS lgia CASCADE;

CREATE SCHEMA IF NOT EXISTS lgia;

ALTER SCHEMA lgia OWNER TO osm;

GRANT ALL ON SCHEMA lgia TO osm;

DROP FOREIGN TABLE IF EXISTS lgia.vdb_orig;

CREATE FOREIGN TABLE lgia.vdb_orig (
  fid BIGINT NOT NULL
  ,pamatnosaukums TEXT NOT NULL
  ,pamatnosaukums2 TEXT NULL
  ,objektaid INTEGER NOT NULL
  ,objekta_veids TEXT NOT NULL
  ,stavoklis TEXT NULL
  ,oficialais_nosaukums TEXT NULL
  ,oficialais_nosaukums_ar TEXT NULL
  ,citi_nosaukumi TEXT NULL
  ,galv_pagasts TEXT NOT NULL
  ,galv_novads TEXT NOT NULL
  ,galv_rajons_agrak TEXT NOT NULL
  ,atkkods TEXT NOT NULL
  ,arisid INTEGER NULL
  ,geoplatums DOUBLE PRECISION NOT NULL
  ,geogarums DOUBLE PRECISION NOT NULL
  ,raksturojums TEXT NULL
  ,zinas_par_objektu TEXT NULL
  ,papildus_zinas_par_nosaukumu TEXT NULL
  ,izveides_datums TEXT NOT NULL
  ,pedejo_izmainu_datums TEXT NOT NULL
  )
  SERVER vdb
  OPTIONS (layer 'VDB_OBJEKTI_EXPORT');