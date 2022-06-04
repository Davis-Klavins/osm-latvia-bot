CREATE OR REPLACE PROCEDURE in_latvia(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

--Table containing node IDs that have tags and are located in Latvia.
DROP TABLE IF EXISTS nodes_lv;

CREATE TABLE nodes_lv (id BIGINT NOT NULL PRIMARY KEY);

CREATE TEMPORARY TABLE nodes_tmp AS
SELECT id
  ,geom
FROM nodes
WHERE tags != ''::HSTORE;

CREATE INDEX nodes_tmp_geom_idx ON nodes_tmp USING GIST (geom);

INSERT INTO nodes_lv
SELECT a.id
FROM nodes_tmp a
INNER JOIN vzd.state b ON ST_Intersects(a.geom, b.geom);

-- 
DROP TABLE IF EXISTS ways_lv;

CREATE TABLE ways_lv (id BIGINT NOT NULL PRIMARY KEY);

INSERT INTO ways_lv
SELECT a.id
FROM ways a
INNER JOIN way_geometry b ON a.id = b.way_id
INNER JOIN vzd.state c ON ST_Intersects(b.geom, c.geom);

--Table containing relation IDs that are located in Latvia.
DROP TABLE IF EXISTS relations_lv;

CREATE TABLE relations_lv (id BIGINT NOT NULL PRIMARY KEY);

INSERT INTO relations_lv
SELECT a.id
FROM relations a
INNER JOIN relation_members m ON a.id = m.relation_id
INNER JOIN nodes_lv n ON m.member_id = n.id
WHERE m.member_type LIKE 'N'

UNION

SELECT a.id
FROM relations a
INNER JOIN relation_members m ON a.id = m.relation_id
INNER JOIN ways_lv w ON m.member_id = w.id
WHERE m.member_type LIKE 'W';

--Relation can contain other relations.
DO $$

DECLARE relations_add INT := 1;

BEGIN
  WHILE relations_add > 0

  LOOP

  INSERT INTO relations_lv
  SELECT DISTINCT a.id
  FROM relations a
  INNER JOIN relation_members m ON a.id = m.relation_id
  INNER JOIN relations_lv n ON m.member_id = n.id
  WHERE m.member_type LIKE 'R'
    AND a.id NOT IN (
      SELECT id
      FROM relations_lv
      );

  relations_add := COUNT(DISTINCT a.id)
  FROM relations a
  INNER JOIN relation_members m ON a.id = m.relation_id
  INNER JOIN relations_lv n ON m.member_id = n.id
  WHERE m.member_type LIKE 'R'
    AND a.id NOT IN (
      SELECT id
      FROM relations_lv
      );

  END LOOP;

--Remove relations tagged as being in another country (to omit borders of Russia and Belarus).
DELETE
FROM relations_lv
WHERE id IN (
    SELECT id
    FROM relations
    WHERE tags -> 'addr:country' NOT LIKE 'LV'
    );

--Table containing all tags in Latvia.
DROP TABLE IF EXISTS tags;

CREATE TABLE tags (
  id serial PRIMARY KEY
  ,tag TEXT NOT NULL
  ,cnt INT NOT NULL
  );

WITH a
AS (
  SELECT UNNEST((%# a.tags) [1:999] [1]) tag
  FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
  
  UNION ALL
  
  SELECT UNNEST((%# a.tags) [1:999] [1]) tag
  FROM nodes a
  INNER JOIN nodes_lv b ON a.id = b.id
  
  UNION ALL
  
  SELECT UNNEST((%# a.tags) [1:999] [1]) tag
  FROM relations a
  INNER JOIN relations_lv b ON a.id = b.id
  )
INSERT INTO tags (
  tag
  ,cnt
  )
SELECT tag
  ,COUNT(*) cnt
FROM a
GROUP BY tag
ORDER BY tag;

END$$;

END;
$BODY$;

REVOKE ALL ON PROCEDURE in_latvia() FROM PUBLIC;