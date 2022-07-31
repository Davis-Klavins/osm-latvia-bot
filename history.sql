DROP SCHEMA IF EXISTS history CASCADE;

CREATE SCHEMA IF NOT EXISTS history;

ALTER SCHEMA history OWNER TO osm;

GRANT ALL ON SCHEMA history TO osm;

DROP TABLE IF EXISTS history.nodes_import;

CREATE TABLE history.nodes_import (
  fid SERIAL PRIMARY KEY
  ,id BIGINT NOT NULL
  ,version INTEGER NOT NULL
  ,deleted TEXT NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,user_id INTEGER NOT NULL
  ,user_name TEXT NOT NULL
  ,tags TEXT
  ,longitude TEXT
  ,latitude TEXT
  );

DROP TABLE IF EXISTS history.ways_import;

CREATE TABLE history.ways_import (
  fid SERIAL PRIMARY KEY
  ,id BIGINT NOT NULL
  ,version INTEGER NOT NULL
  ,deleted TEXT NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,user_id INTEGER NOT NULL
  ,user_name TEXT NOT NULL
  ,tags TEXT
  ,way_nodes TEXT NOT NULL
  );

DROP TABLE IF EXISTS history.relations_import;

CREATE TABLE history.relations_import (
  fid SERIAL PRIMARY KEY
  ,id BIGINT NOT NULL
  ,version INTEGER NOT NULL
  ,deleted TEXT NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,user_id INTEGER NOT NULL
  ,user_name TEXT NOT NULL
  ,tags TEXT
  ,relation_members TEXT NOT NULL
  );