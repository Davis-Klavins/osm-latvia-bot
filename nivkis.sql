CREATE OR REPLACE PROCEDURE vzd.nivkis(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$
BEGIN

--Buildings.
DROP TABLE IF EXISTS vzd.nivkis_buves CASCADE;

CREATE TABLE vzd.nivkis_buves (
  id SERIAL PRIMARY KEY
  ,code VARCHAR(14) NOT NULL
  ,object_code BIGINT NOT NULL
  ,parcel_code VARCHAR(11) NOT NULL
  ,geom geometry(MultiPolygon, 4326) NOT NULL
  );

---Houses.
INSERT INTO vzd.nivkis_buves (
  code
  ,object_code
  ,parcel_code
  ,geom
  )
SELECT code
  ,objectcode::BIGINT
  ,parcelcode
  ,ST_MakeValid(ST_Multi(ST_Transform(geom, 4326)))
FROM vzd.kkbuilding;

/*
---Engineering structures.
INSERT INTO vzd.nivkis_buves (
  code
  ,object_code
  ,parcel_code
  ,geom
  )
SELECT code
  ,objectcode::BIGINT
  ,parcelcode
  ,ST_MakeValid(ST_Multi(ST_Transform(geom, 4326)))
FROM vzd.kkengineeringstructurepoly;
*/

CREATE INDEX nivkis_buves_geom_idx ON vzd.nivkis_buves USING GIST (geom);

--Land parcels.
DROP TABLE IF EXISTS vzd.nivkis_zemes_vienibas;

CREATE TABLE vzd.nivkis_zemes_vienibas (
  id SERIAL PRIMARY KEY
  ,code VARCHAR(11) NOT NULL
  ,geom_actual_date DATE NOT NULL
  ,object_code BIGINT NOT NULL
  ,geom geometry(Geometry, 4326) NOT NULL
  );

INSERT INTO vzd.nivkis_zemes_vienibas (
  code
  ,geom_actual_date
  ,object_code
  ,geom
  )
SELECT code
  ,geom_act_d
  ,objectcode::BIGINT
  ,ST_MakeValid(ST_Transform(geom, 4326))
FROM vzd.kkparcel;

CREATE INDEX nivkis_zemes_vienibas_geom_idx ON vzd.nivkis_zemes_vienibas USING GIST (geom);

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.nivkis() FROM PUBLIC;
