DROP SERVER IF EXISTS hl CASCADE;

CREATE SERVER hl FOREIGN DATA WRAPPER ogr_fdw OPTIONS (
  datasource 'D:\osm\csp\hl', 
  format 'ESRI Shapefile'
);

ALTER SERVER hl OWNER TO osm;

IMPORT FOREIGN SCHEMA ogr_all FROM SERVER hl INTO csp;

DROP TABLE IF EXISTS csp.hl;

CREATE TABLE csp.hl (
  id serial PRIMARY KEY
  ,geom geometry(Polygon, 4326) NOT NULL
  ,code CHARACTER VARYING(9) NOT NULL
  ,name CHARACTER VARYING(50) NOT NULL
  );

INSERT INTO csp.hl (
  geom
  ,code
  ,name
  )
SELECT ST_Transform(geom, 4326)
  ,code
  ,name
FROM csp.vesturiskas_zemes;

CREATE INDEX hl_geom_idx ON csp.hl USING GIST (geom);