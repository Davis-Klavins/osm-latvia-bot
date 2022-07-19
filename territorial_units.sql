CREATE OR REPLACE PROCEDURE vzd.territorial_units(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$
BEGIN

DROP TABLE IF EXISTS vzd.territorial_units CASCADE;

CREATE TABLE vzd.territorial_units (
  id SERIAL PRIMARY KEY
  ,l1_code VARCHAR(7) NOT NULL
  ,l1_name VARCHAR(50) NOT NULL
  ,l1_type SMALLINT NOT NULL
  ,l0_code VARCHAR(7) NULL
  ,l0_name VARCHAR(50) NULL
  ,l0_type SMALLINT NULL
  ,nuts3_code VARCHAR(5) NULL
  ,nuts3_name VARCHAR(50) NULL
  ,geom geometry(MultiPolygon, 4326) NOT NULL
  );

CREATE INDEX territorial_units_geom_idx ON vzd.territorial_units USING GIST (geom);

--Rural territories.
INSERT INTO vzd.territorial_units (
  l1_code
  ,l1_name
  ,l1_type
  ,geom
  )
SELECT atrib
  ,REPLACE(nosaukums, 'pag.', 'pagasts')
  ,7
  ,ST_Transform(ST_Multi(geom), 4326)
FROM vzd.adm_rob
WHERE tips_cd = 105;

--Cities.
INSERT INTO vzd.territorial_units (
  l1_code
  ,l1_name
  ,l1_type
  ,geom
  ,l0_code
  ,l0_name
  ,l0_type
  )
SELECT atrib
  ,nosaukums
  ,1
  ,ST_Transform(ST_Multi(geom), 4326)
  ,atrib
  ,nosaukums
  ,1
FROM vzd.adm_rob
WHERE tips_cd = 104
  AND vkur_tips = 101;

--Towns.
INSERT INTO vzd.territorial_units (
  l1_code
  ,l1_name
  ,l1_type
  ,geom
  )
SELECT atrib
  ,nosaukums
  ,6
  ,ST_Transform(ST_Multi(geom), 4326)
FROM vzd.adm_rob
WHERE tips_cd = 104
  AND vkur_tips = 113;

--Municipalities without rural territories, cities and towns. None since 1 July 2021.
INSERT INTO vzd.territorial_units (
  l1_code
  ,l1_name
  ,l1_type
  ,geom
  ,l0_code
  ,l0_name
  ,l0_type
  )
SELECT a.atrib
  ,REPLACE(a.nosaukums, 'nov.', 'novads')
  ,5
  ,ST_Transform(ST_Multi(a.geom), 4326)
  ,a.atrib
  ,REPLACE(a.nosaukums, 'nov.', 'novads')
  ,5
FROM vzd.adm_rob a
LEFT OUTER JOIN vzd.territorial_units b ON ST_Contains(ST_Transform(ST_Multi(a.geom), 4326), b.geom)
WHERE b.l1_code IS NULL
  AND a.tips_cd = 113;

--Municipalities with rural territories, cities and towns.
UPDATE vzd.territorial_units
SET l0_code = s.atrib
  ,l0_name = REPLACE(s.nosaukums, 'nov.', 'novads')
  ,l0_type = 5
FROM vzd.adm_rob s
WHERE ST_Contains(ST_Transform(ST_Multi(s.geom), 4326), vzd.territorial_units.geom)
  AND l0_code IS NULL
  AND s.tips_cd = 113;

--NUTS3 codes.
UPDATE vzd.territorial_units
SET nuts3_code = a.code_parent
FROM csp.atu_nuts_codes a
WHERE vzd.territorial_units.l0_code = a.code
  AND a.level::SMALLINT = 3
  AND fid NOT IN (
    SELECT fid
    FROM csp.atu_nuts_codes
    WHERE validity_period_end IS NOT NULL
    ); --Workaround to IS NULL retrieving no rows.

--NUTS3 names.
UPDATE vzd.territorial_units
SET nuts3_name = a.name
FROM csp.atu_nuts_codes a
WHERE vzd.territorial_units.nuts3_code = a.code
  AND a.level::SMALLINT = 1
  AND fid NOT IN (
    SELECT fid
    FROM csp.atu_nuts_codes
    WHERE validity_period_end IS NOT NULL
    ); --Workaround to IS NULL retrieving no rows.

--Make geometries valid.
UPDATE vzd.territorial_units
SET geom = ST_MakeValid(geom)
WHERE ST_IsValid(geom) = false;

/*
--Materialized view with dissolved administrative territories.
DROP MATERIALIZED VIEW IF EXISTS vzd.state;

CREATE MATERIALIZED VIEW vzd.state
AS
(
    SELECT 1::SMALLINT ID
      ,ST_Union(geom) geom
    FROM vzd.territorial_units
    --WHERE l1_name LIKE 'Viļāni' -- Limit to process smaller territory (NUTS3 region (nuts3_code/nuts3_name)/municipality (l0_code/l0_name)/city/town/rural territory (l1_code/l1_name)).
    );

CREATE INDEX state_geom_idx ON vzd.state USING GIST (geom);
*/

--Villages.
DROP TABLE IF EXISTS vzd.villages;

CREATE TABLE vzd.villages (
  id serial PRIMARY KEY
  ,geom geometry(MultiPolygon, 4326) NOT NULL
  ,code BIGINT NOT NULL
  ,name TEXT NOT NULL
  );

INSERT INTO vzd.villages (
  geom
  ,code
  ,name
  )
SELECT ST_Transform(ST_Multi(geom), 4326)
  ,kods
  ,nosaukums
FROM vzd.ciemi;

CREATE INDEX villages_geom_idx ON vzd.villages USING GIST (geom);

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.territorial_units() FROM PUBLIC;
