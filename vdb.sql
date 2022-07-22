CREATE OR REPLACE PROCEDURE lgia.vdb(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$
BEGIN

DROP TABLE IF EXISTS lgia.vdb;

CREATE TABLE lgia.vdb (
  objektaid INTEGER NOT NULL PRIMARY KEY
  ,pamatnosaukums TEXT NOT NULL
  ,pamatnosaukums2 TEXT NULL
  ,objekta_veids TEXT NOT NULL
  ,stavoklis TEXT NULL
  ,oficialais_nosaukums TEXT NULL
  ,oficialais_nosaukums_ar TEXT NULL
  ,citi_nosaukumi TEXT [] NULL
  ,galv_pagasts TEXT NOT NULL
  ,galv_novads TEXT NOT NULL
  ,galv_rajons_agrak TEXT NOT NULL
  ,atkkods TEXT NOT NULL
  ,arisid INTEGER NULL
  ,raksturojums TEXT NULL
  ,zinas_par_objektu TEXT NULL
  ,papildus_zinas_par_nosaukumu TEXT NULL
  ,geom geometry(Point, 4326) NOT NULL
  ,izveides_datums TIMESTAMP NOT NULL
  ,pedejo_izmainu_datums TIMESTAMP NOT NULL
  );

INSERT INTO lgia.vdb (
  objektaid
  ,pamatnosaukums
  ,pamatnosaukums2
  ,objekta_veids
  ,stavoklis
  ,oficialais_nosaukums
  ,oficialais_nosaukums_ar
  ,citi_nosaukumi
  ,galv_pagasts
  ,galv_novads
  ,galv_rajons_agrak
  ,atkkods
  ,arisid
  ,raksturojums
  ,zinas_par_objektu
  ,papildus_zinas_par_nosaukumu
  ,geom
  ,izveides_datums
  ,pedejo_izmainu_datums
  )
SELECT objektaid
  ,pamatnosaukums
  ,pamatnosaukums2
  ,objekta_veids
  ,stavoklis
  ,oficialais_nosaukums
  ,oficialais_nosaukums_ar
  ,STRING_TO_ARRAY(citi_nosaukumi, ',')
  ,galv_pagasts
  ,galv_novads
  ,galv_rajons_agrak
  ,atkkods
  ,arisid
  ,raksturojums
  ,zinas_par_objektu
  ,papildus_zinas_par_nosaukumu
  ,ST_SetSRID(ST_MakePoint(geogarums, geoplatums), 4326)
  ,REPLACE(izveides_datums, ',', '.')::TIMESTAMP
  ,REPLACE(pedejo_izmainu_datums, ',', '.')::TIMESTAMP
FROM lgia.vdb_orig;

CREATE INDEX vdb_geom_idx ON lgia.vdb USING GIST (geom);

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE lgia.vdb() FROM PUBLIC;