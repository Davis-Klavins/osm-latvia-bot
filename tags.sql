-- PROCEDURE: public.tags()

-- DROP PROCEDURE IF EXISTS public.tags();

CREATE OR REPLACE PROCEDURE public.tags(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN

CREATE TEMPORARY TABLE lv_border AS
SELECT a.id
  ,ST_Union(c.geom) geom
FROM relations a
INNER JOIN relation_members b ON a.id = b.relation_id
INNER JOIN way_geometry c ON b.member_id = c.way_id
WHERE id = 72594
  AND b.member_role LIKE 'outer'
GROUP BY a.id;

CREATE INDEX lv_border_geom_idx ON lv_border USING GIST (geom);

CREATE TEMPORARY TABLE relations_geometry AS
WITH c
AS (
  SELECT a.id
    ,n2.geom
  FROM relations a
  INNER JOIN relation_members m ON a.id = m.relation_id
  INNER JOIN nodes_lv n ON m.member_id = n.id
  INNER JOIN nodes n2 ON n.id = n2.id
  WHERE m.member_type LIKE 'N'
  
  UNION
  
  SELECT a.id
    ,g.geom
  FROM relations a
  INNER JOIN relation_members m ON a.id = m.relation_id
  INNER JOIN ways_lv w ON m.member_id = w.id
  INNER JOIN way_geometry g ON w.id = g.way_id
  WHERE m.member_type LIKE 'W'
  )
SELECT id relation_id
  ,ST_Collect(geom) geom
FROM c
GROUP BY id;

CREATE INDEX relations_geometry_geom_idx ON relations_geometry USING GIST (geom);

CREATE TEMPORARY TABLE nodes_unnest AS
SELECT a.id
  ,UNNEST((%# a.tags) [1:999] [1]) tag
  ,UNNEST((%# a.tags) [1:999] [2:2]) val
FROM nodes a
INNER JOIN nodes_lv b ON a.id = b.id
LEFT OUTER JOIN lv_border x ON ST_Intersects(a.geom, x.geom)
WHERE x.id IS NULL;

CREATE TEMPORARY TABLE ways_unnest AS
SELECT a.id
  ,UNNEST((%# a.tags) [1:999] [1]) tag
  ,UNNEST((%# a.tags) [1:999] [2:2]) val
FROM ways a
INNER JOIN ways_lv b ON a.id = b.id
INNER JOIN way_geometry g ON a.id = g.way_id
LEFT OUTER JOIN lv_border x ON ST_Intersects(g.geom, x.geom)
WHERE x.id IS NULL;

CREATE TEMPORARY TABLE relations_unnest AS
SELECT a.id
  ,UNNEST((%# a.tags) [1:999] [1]) tag
  ,UNNEST((%# a.tags) [1:999] [2:2]) val
FROM relations a
INNER JOIN relations_lv b ON a.id = b.id
INNER JOIN relations_geometry g ON a.id = g.relation_id
LEFT OUTER JOIN lv_border x ON ST_Intersects(g.geom, x.geom)
WHERE x.id IS NULL;

CREATE TEMPORARY TABLE nodes_unnest_his AS
SELECT a.id
  ,a.version
  ,UNNEST((%# a.tags) [1:999] [1]) tag
  ,UNNEST((%# a.tags) [1:999] [2:2]) val
FROM history.nodes a
INNER JOIN nodes_lv b ON a.id = b.id;

CREATE TEMPORARY TABLE ways_unnest_his AS
SELECT a.id
  ,a.version
  ,UNNEST((%# a.tags) [1:999] [1]) tag
  ,UNNEST((%# a.tags) [1:999] [2:2]) val
FROM history.ways a
INNER JOIN ways_lv b ON a.id = b.id;

CREATE TEMPORARY TABLE relations_unnest_his AS
SELECT a.id
  ,a.version
  ,UNNEST((%# a.tags) [1:999] [1]) tag
  ,UNNEST((%# a.tags) [1:999] [2:2]) val
FROM history.relations a
INNER JOIN relations_lv b ON a.id = b.id;

--1. Trim values.
---Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore(c.tag, TRIM(c.val)) tags
  FROM nodes a
  INNER JOIN nodes_unnest c ON a.id = c.id
  WHERE c.val LIKE ' %'
    OR c.val LIKE '% '
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore(c.tag, TRIM(c.val)) tags
  FROM ways a
  INNER JOIN ways_unnest c ON a.id = c.id
  WHERE c.val LIKE ' %'
    OR c.val LIKE '% '
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore(c.tag, TRIM(c.val)) tags
  FROM relations a
  INNER JOIN relations_unnest c ON a.id = c.id
  WHERE c.val LIKE ' %'
    OR c.val LIKE '% '
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--2. Remove semicolons at the end of values.
---Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore(c.tag, LEFT(c.val, LENGTH(c.val) - 1)) tags
  FROM nodes a
  INNER JOIN nodes_unnest c ON a.id = c.id
  WHERE c.val LIKE '%;'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore(c.tag, LEFT(c.val, LENGTH(c.val) - 1)) tags
  FROM ways a
  INNER JOIN ways_unnest c ON a.id = c.id
  WHERE c.val LIKE '%;'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore(c.tag, LEFT(c.val, LENGTH(c.val) - 1)) tags
  FROM relations a
  INNER JOIN relations_unnest c ON a.id = c.id
  WHERE c.val LIKE '%;'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--3. Trim and sort multiple semicolon separated values in alt_name* and old_name* keys.
---Nodes.
WITH c
AS (
  SELECT id
    ,tag
    ,TRIM(UNNEST(string_to_array(val, ';'))) AS val
  FROM nodes_unnest
  WHERE (
      tag LIKE 'alt_name%'
      OR tag LIKE 'old_name%'
      )
    AND val LIKE '%;%'
  ORDER BY 1
    ,2
    ,3
  )
  ,s2
AS (
  SELECT id
    ,hstore(tag, string_agg(val, ';')) tags
  FROM c
  GROUP BY id
    ,tag
  )--multiple ids, concatenate!
  ,s
AS (
  SELECT s2.id
    ,b.tags || s2.tags tags
  FROM s2
  INNER JOIN nodes b ON s2.id = b.id
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
WITH c
AS (
  SELECT id
    ,tag
    ,TRIM(UNNEST(string_to_array(val, ';'))) AS val
  FROM ways_unnest
  WHERE (
      tag LIKE 'alt_name%'
      OR tag LIKE 'old_name%'
      )
    AND val LIKE '%;%'
  ORDER BY 1
    ,2
    ,3
  )
  ,s2
AS (
  SELECT id
    ,hstore(tag, string_agg(val, ';')) tags
  FROM c
  GROUP BY id
    ,tag
  )
  ,s
AS (
  SELECT s2.id
    ,b.tags || s2.tags tags
  FROM s2
  INNER JOIN ways b ON s2.id = b.id
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
WITH c
AS (
  SELECT id
    ,tag
    ,TRIM(UNNEST(string_to_array(val, ';'))) AS val
  FROM relations_unnest
  WHERE (
      tag LIKE 'alt_name%'
      OR tag LIKE 'old_name%'
      )
    AND val LIKE '%;%'
  ORDER BY 1
    ,2
    ,3
  )
  ,s2
AS (
  SELECT id
    ,hstore(tag, string_agg(val, ';')) tags
  FROM c
  GROUP BY id
    ,tag
  )
  ,s
AS (
  SELECT s2.id
    ,b.tags || s2.tags tags
  FROM s2
  INNER JOIN relations b ON s2.id = b.id
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--4. If missing, add name equal to name:lv if it's already present. name:lv might be deleted in later steps.
---Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name', a.tags -> 'name:lv') tags
  FROM nodes a
  INNER JOIN nodes_lv b ON a.id = b.id
  WHERE a.tags ? 'name:lv'
    AND NOT a.tags ? 'name'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name', a.tags -> 'name:lv') tags
  FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
  WHERE a.tags ? 'name:lv'
    AND NOT a.tags ? 'name'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name', a.tags -> 'name:lv') tags
  FROM relations a
  INNER JOIN relations_lv b ON a.id = b.id
  WHERE a.tags ? 'name:lv'
    AND NOT a.tags ? 'name'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--If missing, add alt_name equal to alt_name:lv if it's already present. alt_name:lv might be deleted in later steps.
---Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('alt_name', a.tags -> 'alt_name:lv') tags
  FROM nodes a
  INNER JOIN nodes_lv b ON a.id = b.id
  WHERE a.tags ? 'alt_name:lv'
    AND NOT a.tags ? 'alt_name'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('alt_name', a.tags -> 'alt_name:lv') tags
  FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
  WHERE a.tags ? 'alt_name:lv'
    AND NOT a.tags ? 'alt_name'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('alt_name', a.tags -> 'alt_name:lv') tags
  FROM relations a
  INNER JOIN relations_lv b ON a.id = b.id
  WHERE a.tags ? 'alt_name:lv'
    AND NOT a.tags ? 'alt_name'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--If missing, add old_name equal to old_name:lv if it's already present. old_name:lv might be deleted in later steps.
---Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('old_name', a.tags -> 'old_name:lv') tags
  FROM nodes a
  INNER JOIN nodes_lv b ON a.id = b.id
  WHERE a.tags ? 'old_name:lv'
    AND NOT a.tags ? 'old_name'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('old_name', a.tags -> 'old_name:lv') tags
  FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
  WHERE a.tags ? 'old_name:lv'
    AND NOT a.tags ? 'old_name'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('old_name', a.tags -> 'old_name:lv') tags
  FROM relations a
  INNER JOIN relations_lv b ON a.id = b.id
  WHERE a.tags ? 'old_name:lv'
    AND NOT a.tags ? 'old_name'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--5. Remove multilingual names if all match default name.
---Exclude some keys in Latgale.
----Nodes. In Latgale, exclude key "place".
CREATE TEMPORARY TABLE nodes_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM nodes a
INNER JOIN nodes_unnest t ON a.id = t.id
WHERE t.tag = 'name'
  OR t.tag LIKE 'name:%';

CREATE TEMPORARY TABLE nodes_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM nodes_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE nodes_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM nodes_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
      ) tags
  FROM nodes a
  INNER JOIN nodes_name_cnt b ON a.id = b.id
  INNER JOIN nodes_name_cnt_distinct d ON b.id = d.id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE h.id IS NULL
    OR NOT a.tags ? 'place'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways. In Latgale, exclude keys "place", "natural" and "waterway".
CREATE TEMPORARY TABLE ways_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM ways a
INNER JOIN ways_unnest t ON a.id = t.id
WHERE t.tag = 'name'
  OR t.tag LIKE 'name:%';

CREATE TEMPORARY TABLE ways_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM ways_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE ways_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM ways_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
      ) tags
  FROM ways a
  INNER JOIN ways_name_cnt b ON a.id = b.id
  INNER JOIN ways_name_cnt_distinct d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE h.id IS NULL
    OR NOT a.tags ?| ARRAY['place', 'natural', 'waterway']
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations. In Latgale, exclude keys "place", "natural" and "waterway".
CREATE TEMPORARY TABLE relations_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM relations a
INNER JOIN relations_unnest t ON a.id = t.id
WHERE t.tag = 'name'
  OR t.tag LIKE 'name:%';

CREATE TEMPORARY TABLE relations_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM relations_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE relations_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM relations_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
      ) tags
  FROM relations a
  INNER JOIN relations_name_cnt b ON a.id = b.id
  INNER JOIN relations_name_cnt_distinct d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE h.id IS NULL
    OR NOT a.tags ?| ARRAY['place', 'natural', 'waterway']
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

---In Latgale, keep *name:lv and *name:ltg keys as in some cases Latgalian might be used as name and otherwise it might be impossible to distinguish which language is used.
----Nodes. Only key "place".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
        AND tag NOT LIKE 'name:lv'
        AND tag NOT LIKE 'name:ltg'
      ) tags
  FROM nodes a
  INNER JOIN nodes_name_cnt b ON a.id = b.id
  INNER JOIN nodes_name_cnt_distinct d ON b.id = d.id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE a.tags ? 'place'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways. Only keys "place", "natural" and "waterway".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
        AND tag NOT LIKE 'name:lv'
        AND tag NOT LIKE 'name:ltg'
      ) tags
  FROM ways a
  INNER JOIN ways_name_cnt b ON a.id = b.id
  INNER JOIN ways_name_cnt_distinct d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags ?| ARRAY['place', 'natural', 'waterway']
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations. Only keys "place", "natural" and "waterway".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
      ) tags
  FROM relations a
  INNER JOIN relations_name_cnt b ON a.id = b.id
  INNER JOIN relations_name_cnt_distinct d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags ?| ARRAY['place', 'natural', 'waterway']
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--Remove multilingual alt_names if all match default alt_name. Identical principles to name except for ways and relations exclude cross border elements having name in more than one language.
---Exclude some keys in Latgale.
----Nodes. In Latgale, exclude key "place".
CREATE TEMPORARY TABLE nodes_alt_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM nodes a
INNER JOIN nodes_unnest t ON a.id = t.id
WHERE t.tag = 'alt_name'
  OR t.tag LIKE 'alt_name:%';

CREATE TEMPORARY TABLE nodes_alt_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM nodes_alt_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE nodes_alt_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM nodes_alt_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name:%'
        AND tag NOT LIKE 'alt_name'
      ) tags
  FROM nodes a
  INNER JOIN nodes_alt_name_cnt b ON a.id = b.id
  INNER JOIN nodes_alt_name_cnt_distinct d ON b.id = d.id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE h.id IS NULL
    OR NOT a.tags ? 'place'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways. In Latgale, exclude keys "place", "natural" and "waterway".
CREATE TEMPORARY TABLE ways_alt_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM ways a
INNER JOIN ways_unnest t ON a.id = t.id
WHERE t.tag = 'alt_name'
  OR t.tag LIKE 'alt_name:%';

CREATE TEMPORARY TABLE ways_alt_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM ways_alt_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE ways_alt_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM ways_alt_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name:%'
        AND tag NOT LIKE 'alt_name'
      ) tags
  FROM ways a
  INNER JOIN ways_alt_name_cnt b ON a.id = b.id
  INNER JOIN ways_alt_name_cnt_distinct d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE (
      h.id IS NULL
      OR NOT a.tags ?| ARRAY ['place', 'natural', 'waterway']
      )
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations.
CREATE TEMPORARY TABLE relations_alt_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM relations a
INNER JOIN relations_unnest t ON a.id = t.id
WHERE t.tag = 'alt_name'
  OR t.tag LIKE 'alt_name:%';

CREATE TEMPORARY TABLE relations_alt_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM relations_alt_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE relations_alt_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM relations_alt_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name:%'
        AND tag NOT LIKE 'alt_name'
      ) tags
  FROM relations a
  INNER JOIN relations_alt_name_cnt b ON a.id = b.id
  INNER JOIN relations_alt_name_cnt_distinct d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE (
      h.id IS NULL
      OR NOT a.tags ?| ARRAY ['place', 'natural', 'waterway']
      )
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

---In Latgale, keep alt_name:lv and alt_name:ltg keys as in some cases Latgalian might be used as alt_name and otherwise it might be impossible to distinguish which language is used.
----Nodes. Only key "place".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name:%'
        AND tag NOT LIKE 'alt_name'
        AND tag NOT LIKE 'alt_name:lv'
        AND tag NOT LIKE 'alt_name:ltg'
      ) tags
  FROM nodes a
  INNER JOIN nodes_alt_name_cnt b ON a.id = b.id
  INNER JOIN nodes_alt_name_cnt_distinct d ON b.id = d.id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE a.tags ? 'place'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways. Only keys "place", "natural" and "waterway".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name:%'
        AND tag NOT LIKE 'alt_name'
        AND tag NOT LIKE 'alt_name:lv'
        AND tag NOT LIKE 'alt_name:ltg'
      ) tags
  FROM ways a
  INNER JOIN ways_alt_name_cnt b ON a.id = b.id
  INNER JOIN ways_alt_name_cnt_distinct d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags ?| ARRAY ['place', 'natural', 'waterway']
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations. Only keys "place", "natural" and "waterway".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name:%'
        AND tag NOT LIKE 'alt_name'
      ) tags
  FROM relations a
  INNER JOIN relations_alt_name_cnt b ON a.id = b.id
  INNER JOIN relations_alt_name_cnt_distinct d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags ?| ARRAY['place', 'natural', 'waterway']
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--Remove multilingual old_names if all match default old_name. Identical principles to alt_name.
---Exclude some keys in Latgale.
----Nodes. In Latgale, exclude key "place".
CREATE TEMPORARY TABLE nodes_old_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM nodes a
INNER JOIN nodes_unnest t ON a.id = t.id
WHERE t.tag = 'old_name'
  OR t.tag LIKE 'old_name:%';

CREATE TEMPORARY TABLE nodes_old_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM nodes_old_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE nodes_old_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM nodes_old_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'old_name:%'
        AND tag NOT LIKE 'old_name'
      ) tags
  FROM nodes a
  INNER JOIN nodes_old_name_cnt b ON a.id = b.id
  INNER JOIN nodes_old_name_cnt_distinct d ON b.id = d.id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE h.id IS NULL
    OR NOT a.tags ? 'place'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways. In Latgale, exclude keys "place", "natural" and "waterway".
CREATE TEMPORARY TABLE ways_old_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM ways a
INNER JOIN ways_unnest t ON a.id = t.id
WHERE t.tag = 'old_name'
  OR t.tag LIKE 'old_name:%';

CREATE TEMPORARY TABLE ways_old_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM ways_old_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE ways_old_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM ways_old_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'old_name:%'
        AND tag NOT LIKE 'old_name'
      ) tags
  FROM ways a
  INNER JOIN ways_old_name_cnt b ON a.id = b.id
  INNER JOIN ways_old_name_cnt_distinct d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE (
      h.id IS NULL
      OR NOT a.tags ?| ARRAY ['place', 'natural', 'waterway']
      )
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations. In Latgale, exclude keys "place", "natural" and "waterway".
CREATE TEMPORARY TABLE relations_old_name AS
SELECT a.id
  ,t.tag
  ,t.val
FROM relations a
INNER JOIN relations_unnest t ON a.id = t.id
WHERE t.tag = 'old_name'
  OR t.tag LIKE 'old_name:%';

CREATE TEMPORARY TABLE relations_old_name_cnt AS
SELECT id
  ,COUNT(*) cnt
FROM relations_old_name
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE relations_old_name_cnt_distinct AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM relations_old_name
GROUP BY id
HAVING COUNT(DISTINCT val) = 1;

WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'old_name:%'
        AND tag NOT LIKE 'old_name'
      ) tags
  FROM relations a
  INNER JOIN relations_old_name_cnt b ON a.id = b.id
  INNER JOIN relations_old_name_cnt_distinct d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE (
      h.id IS NULL
      OR NOT a.tags ?| ARRAY ['place', 'natural', 'waterway']
      )
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

---In Latgale, keep old_name:lv and old_name:ltg keys as in some cases Latgalian might be used as old_name and otherwise it might be impossible to distinguish which language is used.
----Nodes. Only key "place".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'old_name:%'
        AND tag NOT LIKE 'old_name'
        AND tag NOT LIKE 'old_name:lv'
        AND tag NOT LIKE 'old_name:ltg'
      ) tags
  FROM nodes a
  INNER JOIN nodes_old_name_cnt b ON a.id = b.id
  INNER JOIN nodes_old_name_cnt_distinct d ON b.id = d.id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE a.tags ? 'place'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways. Only keys "place", "natural" and "waterway".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'old_name:%'
        AND tag NOT LIKE 'old_name'
        AND tag NOT LIKE 'old_name:lv'
        AND tag NOT LIKE 'old_name:ltg'
      ) tags
  FROM ways a
  INNER JOIN ways_old_name_cnt b ON a.id = b.id
  INNER JOIN ways_old_name_cnt_distinct d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags ?| ARRAY ['place', 'natural', 'waterway']
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations. Only keys "place", "natural" and "waterway".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'old_name:%'
        AND tag NOT LIKE 'old_name'
      ) tags
  FROM relations a
  INNER JOIN relations_old_name_cnt b ON a.id = b.id
  INNER JOIN relations_old_name_cnt_distinct d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags ?| ARRAY['place', 'natural', 'waterway']
    AND a.tags -> 'name' NOT LIKE '% / %' --Exclude cross border elements having name in more than one language.
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--6. From history, restore multilingual names all matching default name if multilingual names that differ from the default name have been added.
---Nodes.
----Retrieve all historical multilingual names deleted by the bot. In case of multiple values for the same key, retrieve the latest.
-----id and version of nodes not having name:* tags.
CREATE TEMPORARY TABLE nodes_wo_name AS
WITH c
AS (
  SELECT id
    ,version
    ,COUNT(*) cnt
  FROM nodes_unnest_his
  WHERE tag NOT LIKE 'name:%'
  GROUP BY id
    ,version
  )
  ,ct
AS (
  SELECT id
    ,version
    ,COUNT(*) cnt
  FROM nodes_unnest_his
  GROUP BY id
    ,version
  )
SELECT c.id
  ,c.version
FROM c
INNER JOIN ct ON c.id = ct.id
  AND c.version = ct.version
WHERE c.cnt = ct.cnt;

-----id and version of nodes having name:* tags.
CREATE TEMPORARY TABLE nodes_name_2 AS
SELECT DISTINCT id
  ,tag
  ,version
FROM nodes_unnest_his
WHERE tag LIKE 'name:%';

-----id and version of nodes having the latest multilingual names all matching default name deleted by the bot.
CREATE TEMPORARY TABLE nodes_name_del AS
SELECT a.id
  ,y.tag
  ,MAX(y.version) "version"
FROM history.nodes a
INNER JOIN nodes_wo_name x ON a.id = x.id
  AND a.version = x.version
INNER JOIN nodes_name_2 y ON a.id = y.id
  AND a.version - 1 = y.version
WHERE a.user_id = 15008076
  AND a.tags ? 'name'
GROUP BY a.id
  ,y.tag;

-----Tags to be restored if multilingual names that differ from the default name have been added.
CREATE TEMPORARY TABLE nodes_restore AS
SELECT t.id
  ,t.version
  ,hstore(array_agg(array [t.tag, t.val])) tags
FROM nodes_name_del a
INNER JOIN nodes_unnest_his t ON a.id = t.id
  AND a.tag = t.tag
  AND a.version = t.version
LEFT OUTER JOIN nodes_unnest n ON a.id = n.id
WHERE n.id IS NULL --Exclude newly added tags.
GROUP BY t.id
  ,t.version;

-----Restore tags if multilingual names that differ from the default name have been added.
CREATE TEMPORARY TABLE nodes_name_cnt_multiple AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM nodes_name
GROUP BY id
HAVING COUNT(DISTINCT val) > 1;

WITH s
AS (
  SELECT a.id
    ,a.tags || b.tags tags
  FROM nodes a
  INNER JOIN nodes_restore b ON a.id = b.id
  INNER JOIN nodes_name_cnt_multiple c ON a.id = c.id
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
----Retrieve all historical multilingual names deleted by the bot. In case of multiple values for the same key, retrieve the latest.
-----id and version of ways not having name:* tags.
CREATE TEMPORARY TABLE ways_wo_name AS
WITH c
AS (
  SELECT id
    ,version
    ,COUNT(*) cnt
  FROM ways_unnest_his
  WHERE tag NOT LIKE 'name:%'
  GROUP BY id
    ,version
  )
  ,ct
AS (
  SELECT id
    ,version
    ,COUNT(*) cnt
  FROM ways_unnest_his
  GROUP BY id
    ,version
  )
SELECT c.id
  ,c.version
FROM c
INNER JOIN ct ON c.id = ct.id
  AND c.version = ct.version
WHERE c.cnt = ct.cnt;

-----id and version of ways having name:* tags.
CREATE TEMPORARY TABLE ways_name_2 AS
SELECT DISTINCT id
  ,tag
  ,version
FROM ways_unnest_his
WHERE tag LIKE 'name:%';

-----id and version of ways having the latest multilingual names all matching default name deleted by the bot.
CREATE TEMPORARY TABLE ways_name_del AS
SELECT a.id
  ,y.tag
  ,MAX(y.version) "version"
FROM history.ways a
INNER JOIN ways_wo_name x ON a.id = x.id
  AND a.version = x.version
INNER JOIN ways_name_2 y ON a.id = y.id
  AND a.version - 1 = y.version
WHERE a.user_id = 15008076
  AND a.tags ? 'name'
GROUP BY a.id
  ,y.tag;

-----Tags to be restored if multilingual names that differ from the default name have been added.
CREATE TEMPORARY TABLE ways_restore AS
SELECT t.id
  ,t.version
  ,hstore(array_agg(array [t.tag, t.val])) tags
FROM ways_name_del a
INNER JOIN ways_unnest_his t ON a.id = t.id
  AND a.tag = t.tag
  AND a.version = t.version
LEFT OUTER JOIN ways_unnest n ON a.id = n.id
WHERE n.id IS NULL --Exclude newly added tags.
GROUP BY t.id
  ,t.version;

-----Restore tags if multilingual names that differ from the default name have been added.
CREATE TEMPORARY TABLE ways_name_cnt_multiple AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM ways_name
GROUP BY id
HAVING COUNT(DISTINCT val) > 1;

WITH s
AS (
  SELECT a.id
    ,a.tags || b.tags tags
  FROM ways a
  INNER JOIN ways_restore b ON a.id = b.id
  INNER JOIN ways_name_cnt_multiple c ON a.id = c.id
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
----Retrieve all historical multilingual names deleted by the bot. In case of multiple values for the same key, retrieve the latest.
-----id and version of relations not having name:* tags.
CREATE TEMPORARY TABLE relations_wo_name AS
WITH c
AS (
  SELECT id
    ,version
    ,COUNT(*) cnt
  FROM relations_unnest_his
  WHERE tag NOT LIKE 'name:%'
  GROUP BY id
    ,version
  )
  ,ct
AS (
  SELECT id
    ,version
    ,COUNT(*) cnt
  FROM relations_unnest_his
  GROUP BY id
    ,version
  )
SELECT c.id
  ,c.version
FROM c
INNER JOIN ct ON c.id = ct.id
  AND c.version = ct.version
WHERE c.cnt = ct.cnt;

-----id and version of relations having name:* tags.
CREATE TEMPORARY TABLE relations_name_2 AS
SELECT DISTINCT id
  ,tag
  ,version
FROM relations_unnest_his
WHERE tag LIKE 'name:%';

-----id and version of relations having the latest multilingual names all matching default name deleted by the bot.
CREATE TEMPORARY TABLE relations_name_del AS
SELECT a.id
  ,y.tag
  ,MAX(y.version) "version"
FROM history.relations a
INNER JOIN relations_wo_name x ON a.id = x.id
  AND a.version = x.version
INNER JOIN relations_name_2 y ON a.id = y.id
  AND a.version - 1 = y.version
WHERE a.user_id = 15008076
  AND a.tags ? 'name'
GROUP BY a.id
  ,y.tag;

-----Tags to be restored if multilingual names that differ from the default name have been added.
CREATE TEMPORARY TABLE relations_restore AS
SELECT t.id
  ,t.version
  ,hstore(array_agg(array [t.tag, t.val])) tags
FROM relations_name_del a
INNER JOIN relations_unnest_his t ON a.id = t.id
  AND a.tag = t.tag
  AND a.version = t.version
LEFT OUTER JOIN relations_unnest n ON a.id = n.id
WHERE n.id IS NULL --Exclude newly added tags.
GROUP BY t.id
  ,t.version;

-----Restore tags if multilingual names that differ from the default name have been added.
CREATE TEMPORARY TABLE relations_name_cnt_multiple AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM relations_name
GROUP BY id
HAVING COUNT(DISTINCT val) > 1;

WITH s
AS (
  SELECT a.id
    ,a.tags || b.tags tags
  FROM relations a
  INNER JOIN relations_restore b ON a.id = b.id
  INNER JOIN relations_name_cnt_multiple c ON a.id = c.id
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--7. Remove alt_name if it matches name:ltg.
---Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name'
      ) tags
  FROM nodes a
  INNER JOIN nodes_lv b ON a.id = b.id
  WHERE a.tags -> 'alt_name' = a.tags -> 'name:ltg'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

---Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name'
      ) tags
  FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
  WHERE a.tags -> 'alt_name' = a.tags -> 'name:ltg'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

---Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'alt_name'
      ) tags
  FROM relations a
  INNER JOIN relations_lv b ON a.id = b.id
  WHERE a.tags -> 'alt_name' = a.tags -> 'name:ltg'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--8. For isolated dwellings, remove multilingual names.
---Exclude Latgale.
----Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
      ) tags_new
  FROM nodes a
  INNER JOIN nodes_name_cnt b ON a.id = b.id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE h.id IS NULL
    AND a.tags -> 'place' = 'isolated_dwelling'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
      ) tags_new
  FROM ways a
  INNER JOIN ways_name_cnt b ON a.id = b.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE h.id IS NULL
    AND a.tags -> 'place' = 'isolated_dwelling'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
      ) tags_new
  FROM relations a
  INNER JOIN relations_name_cnt b ON a.id = b.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE h.id IS NULL
    AND a.tags -> 'place' = 'isolated_dwelling'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

---In Latgale, keep only name:lv and name:ltg.
----Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
        AND tag NOT LIKE 'name:lv'
        AND tag NOT LIKE 'name:ltg'
      ) tags_new
  FROM nodes a
  INNER JOIN nodes_name_cnt b ON a.id = b.id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE a.tags -> 'place' = 'isolated_dwelling'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
        AND tag NOT LIKE 'name:lv'
        AND tag NOT LIKE 'name:ltg'
      ) tags_new
  FROM ways a
  INNER JOIN ways_name_cnt b ON a.id = b.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags -> 'place' = 'isolated_dwelling'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE 'name:%'
        AND tag NOT LIKE 'name'
        AND tag NOT LIKE 'name:lv'
        AND tag NOT LIKE 'name:ltg'
      ) tags_new
  FROM relations a
  INNER JOIN relations_name_cnt b ON a.id = b.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags -> 'place' = 'isolated_dwelling'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--9. If missing, add name:lv that equals default name if multilingual names that differ from the default name exist.
---Exclude Latgale.
----Nodes.
CREATE TEMPORARY TABLE nodes_name_cnt_lv AS
SELECT id
  ,COUNT(*) cnt
FROM nodes_name
WHERE id NOT IN (
    SELECT id
    FROM nodes_name
    WHERE tag = 'name:lv'
    )
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE nodes_name_cnt_distinct_lv AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM nodes_name
WHERE id NOT IN (
    SELECT id
    FROM nodes_name
    WHERE tag = 'name:lv'
    )
GROUP BY id
HAVING COUNT(DISTINCT val) > 1;

WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM nodes a
  INNER JOIN nodes_name_cnt_lv b ON a.id = b.id
  INNER JOIN nodes_name_cnt_distinct_lv d ON b.id = d.id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE h.id IS NULL
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways.
CREATE TEMPORARY TABLE ways_name_cnt_lv AS
SELECT id
  ,COUNT(*) cnt
FROM ways_name
WHERE id NOT IN (
    SELECT id
    FROM ways_name
    WHERE tag = 'name:lv'
    )
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE ways_name_cnt_distinct_lv AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM ways_name
WHERE id NOT IN (
    SELECT id
    FROM ways_name
    WHERE tag = 'name:lv'
    )
GROUP BY id
HAVING COUNT(DISTINCT val) > 1;

WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM ways a
  INNER JOIN ways_name_cnt_lv b ON a.id = b.id
  INNER JOIN ways_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE h.id IS NULL
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations.
CREATE TEMPORARY TABLE relations_name_cnt_lv AS
SELECT id
  ,COUNT(*) cnt
FROM relations_name
WHERE id NOT IN (
    SELECT id
    FROM relations_name
    WHERE tag = 'name:lv'
    )
GROUP BY id
HAVING COUNT(*) > 1;

CREATE TEMPORARY TABLE relations_name_cnt_distinct_lv AS
SELECT id
  ,COUNT(DISTINCT val) cnt
FROM relations_name
WHERE id NOT IN (
    SELECT id
    FROM relations_name
    WHERE tag = 'name:lv'
    )
GROUP BY id
HAVING COUNT(DISTINCT val) > 1;

WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM relations a
  INNER JOIN relations_name_cnt_lv b ON a.id = b.id
  INNER JOIN relations_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  LEFT OUTER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE h.id IS NULL
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

---In Latgale, don't add name:lv if name matches name:lgt as some names use Latgalian as default name.
----Nodes.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM nodes a
  INNER JOIN nodes_name_cnt_lv b ON a.id = b.id
  INNER JOIN nodes_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE NOT a.tags ? 'name:ltg'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM nodes a
  INNER JOIN nodes_name_cnt_lv b ON a.id = b.id
  INNER JOIN nodes_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(a.geom, h.geom)
  WHERE a.tags -> 'name' != a.tags -> 'name:ltg'
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

----Ways.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM ways a
  INNER JOIN ways_name_cnt_lv b ON a.id = b.id
  INNER JOIN ways_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE NOT a.tags ? 'name:ltg'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM ways a
  INNER JOIN ways_name_cnt_lv b ON a.id = b.id
  INNER JOIN ways_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags -> 'name' != a.tags -> 'name:ltg'
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

----Relations.
WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM relations a
  INNER JOIN relations_name_cnt_lv b ON a.id = b.id
  INNER JOIN relations_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE NOT a.tags ? 'name:ltg'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

WITH s
AS (
  SELECT a.id
    ,a.tags || hstore('name:lv', a.tags -> 'name') tags
  FROM relations a
  INNER JOIN relations_name_cnt_lv b ON a.id = b.id
  INNER JOIN relations_name_cnt_distinct_lv d ON b.id = d.id
  INNER JOIN relations_geometry g ON a.id = g.relation_id
  INNER JOIN (
    SELECT *
    FROM csp.hl
    WHERE code = 'LVL'
    ) h ON ST_Intersects(g.geom, h.geom)
  WHERE a.tags -> 'name' != a.tags -> 'name:ltg'
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

END;
$BODY$;

ALTER PROCEDURE public.tags()
    OWNER TO osm;

GRANT EXECUTE ON PROCEDURE public.tags() TO osm;

REVOKE ALL ON PROCEDURE public.tags() FROM PUBLIC;