DROP SERVER IF EXISTS dpa CASCADE;

CREATE SERVER dpa FOREIGN DATA WRAPPER ogr_fdw OPTIONS (
  datasource 'D:\osm\csp\dpa', 
  format 'ESRI Shapefile'
);

ALTER SERVER dpa OWNER TO osm;

IMPORT FOREIGN SCHEMA ogr_all FROM SERVER dpa INTO csp;

DROP TABLE IF EXISTS csp.dpa_div;

CREATE TABLE csp.dpa_div (
  id serial PRIMARY KEY
  ,geom geometry(Polygon, 4326) NOT NULL
  ,code CHARACTER VARYING(9) NOT NULL
  ,name CHARACTER VARYING(50) NOT NULL
  );

INSERT INTO csp.dpa_div (
  geom
  ,code
  ,name
  )
SELECT ST_Transform(ST_Subdivide(geom, 1024), 4326)
  ,code
  ,name
FROM csp.dpa;

CREATE INDEX dpa_div_geom_idx ON csp.dpa_div USING GIST (geom);

--Make geometries valid.
WITH s
AS (
  SELECT id
    ,(ST_Dump(ST_MakeValid(geom))).geom geom
  FROM csp.dpa_div
  WHERE ST_IsValid(geom) = FALSE
  )
UPDATE csp.dpa_div u
SET geom = s.geom
FROM s
WHERE u.id = s.id
  AND ST_GeometryType(s.geom) = 'ST_Polygon';
