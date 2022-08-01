CREATE OR REPLACE PROCEDURE history.history(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

--Nodes.
DROP TABLE IF EXISTS history.nodes;

CREATE TABLE history.nodes (
  fid SERIAL PRIMARY KEY
  ,id BIGINT NOT NULL
  ,version INTEGER NOT NULL
  ,deleted CHARACTER(1) NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,user_id INTEGER NOT NULL
  ,user_name TEXT NOT NULL
  ,tags HSTORE
  ,geom geometry(Point,4326)
  );

INSERT INTO history.nodes (
  id
  ,version
  ,deleted
  ,changeset_id
  ,tstamp
  ,user_id
  ,user_name
  ,tags
  ,geom
  )
SELECT id
  ,version
  ,deleted
  ,changeset_id
  ,tstamp
  ,user_id
  ,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(user_name, '%20%', ' '), '%25%', '%'), '%2c%', ','), '%3d%', '='), '%40%', '@') user_name
  ,CASE 
    WHEN tags LIKE ''
      THEN NULL
    ELSE REPLACE(string_to_array(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tags, '%20%', ' '), '=', ','), '%25%', '%'), '%3d%', '='), '%40%', '@'), ',')::HSTORE::TEXT, '%2c%', ',')::HSTORE
    END
  ,CASE 
    WHEN longitude LIKE ''
      THEN NULL
    ELSE ST_SetSRID(ST_MakePoint(longitude::DECIMAL(9, 7), latitude::DECIMAL(9, 7)), 4326)
    END
FROM history.nodes_import
ORDER BY tstamp
  ,id;

CREATE INDEX nodes_geom_idx ON history.nodes USING GIST (geom);

TRUNCATE TABLE history.nodes_import RESTART IDENTITY;

--Ways.
DROP TABLE IF EXISTS history.ways;

CREATE TABLE history.ways (
  fid SERIAL PRIMARY KEY
  ,id BIGINT NOT NULL
  ,version INTEGER NOT NULL
  ,deleted CHARACTER(1) NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,user_id INTEGER NOT NULL
  ,user_name TEXT NOT NULL
  ,tags HSTORE
  ,way_nodes BIGINT[]
  );

INSERT INTO history.ways (
  id
  ,version
  ,deleted
  ,changeset_id
  ,tstamp
  ,user_id
  ,user_name
  ,tags
  ,way_nodes
  )
SELECT id
  ,version
  ,deleted
  ,changeset_id
  ,tstamp
  ,user_id
  ,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(user_name, '%20%', ' '), '%25%', '%'), '%2c%', ','), '%3d%', '='), '%40%', '@') user_name
  ,CASE 
    WHEN tags LIKE ''
      THEN NULL
    ELSE REPLACE(string_to_array(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tags, '%20%', ' '), '=', ','), '%25%', '%'), '%3d%', '='), '%40%', '@'), ',')::HSTORE::TEXT, '%2c%', ',')::HSTORE
    END
  ,CASE 
    WHEN way_nodes LIKE ''
      THEN NULL
    ELSE string_to_array(REPLACE(way_nodes, 'n', ''), ',')::BIGINT[]
    END
FROM history.ways_import
ORDER BY tstamp
  ,id;

TRUNCATE TABLE history.ways_import RESTART IDENTITY;

--Relations.
DROP TABLE IF EXISTS history.relations;

CREATE TABLE history.relations (
  fid SERIAL PRIMARY KEY
  ,id BIGINT NOT NULL
  ,version INTEGER NOT NULL
  ,deleted CHARACTER(1) NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,user_id INTEGER NOT NULL
  ,user_name TEXT NOT NULL
  ,tags HSTORE
  );

INSERT INTO history.relations (
  id
  ,version
  ,deleted
  ,changeset_id
  ,tstamp
  ,user_id
  ,user_name
  ,tags
  )
SELECT id
  ,version
  ,deleted
  ,changeset_id
  ,tstamp
  ,user_id
  ,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(user_name, '%20%', ' '), '%25%', '%'), '%2c%', ','), '%3d%', '='), '%40%', '@') user_name
  ,CASE 
    WHEN tags LIKE ''
      THEN NULL
    ELSE REPLACE(string_to_array(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(tags, '%20%', ' '), '=', ','), '%25%', '%'), '%3d%', '='), '%40%', '@'), ',')::HSTORE::TEXT, '%2c%', ',')::HSTORE
    END
FROM history.relations_import;

DROP TABLE IF EXISTS history.relation_members;

CREATE TABLE history.relation_members (
  fid SERIAL PRIMARY KEY
  ,relation_id BIGINT NOT NULL
  ,relation_version INTEGER NOT NULL
  ,member_id BIGINT NOT NULL
  ,member_type CHARACTER(1) NOT NULL
  ,member_role TEXT
  ,sequence_id INTEGER NOT NULL
  );

INSERT INTO history.relation_members (
  relation_id
  ,relation_version
  ,member_id
  ,member_type
  ,member_role
  ,sequence_id
  )
SELECT t.id
  ,t.version
  ,SUBSTRING(a.elem, 2, strpos(a.elem, '@') - 2)::BIGINT
  ,UPPER(LEFT(a.elem, 1))
  ,CASE 
    WHEN SUBSTRING(a.elem, strpos(a.elem, '@') + 1) LIKE ''
      THEN NULL
    ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SUBSTRING(a.elem, strpos(a.elem, '@') + 1), '%20%', ' '), '%25%', '%'), '%2c%', ','), '%3d%', '='), '%40%', '@')
    END
  ,a.nr - 1
FROM history.relations_import t
INNER JOIN LATERAL UNNEST(string_to_array(relation_members, ',')) WITH ORDINALITY AS a(elem, nr) ON true;

TRUNCATE TABLE history.relations_import RESTART IDENTITY;

END;
$BODY$;

REVOKE ALL ON PROCEDURE history.history() FROM PUBLIC;
