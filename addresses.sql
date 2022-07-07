CREATE OR REPLACE PROCEDURE addresses(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

--Needed in case smaller territory than state is selected in materialized view vzd.state.
CREATE TEMPORARY TABLE adreses_ekas_sadalitas AS
SELECT a.*
FROM vzd.adreses_ekas_sadalitas a
INNER JOIN vzd.state b ON ST_Within(a.geom, b.geom);

CREATE INDEX adreses_ekas_sadalitas_geom_idx ON adreses_ekas_sadalitas USING GIST (geom);

--All tags and values of nodes as a table with a row for each element in the array.
CREATE TEMPORARY TABLE nodes_unnest AS
SELECT id
  ,UNNEST((%# tags) [1:999] [1]) tag
  ,UNNEST((%# tags) [1:999] [2:2]) val
FROM nodes;

/*
--Add name tags and values to streets where names are mistagged as addresses.
WITH c
AS (
  SELECT id
    ,UNNEST((%# tags) [1:999] [1]) tag
    ,UNNEST((%# tags) [1:999] [2:2]) val
  FROM ways
  )
  ,s
AS (
  SELECT a.id
    ,a.tags || hstore('name', c.val) tags
  FROM ways a
  LEFT OUTER JOIN c ON a.id = c.id
    AND c.tag LIKE 'name%'
  WHERE a.tags ? 'addr:street'
    AND a.tags ? 'highway'
    AND c.id IS NULL
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;
*/

--Table for old version of changed nodes for comparison.
DROP TABLE IF EXISTS nodes_old;

CREATE TABLE nodes_old (
  id BIGINT NOT NULL PRIMARY KEY
  ,version INT NOT NULL
  ,user_id INT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tags hstore
  ,geom geometry(Point, 4326)
  );

---Insert all nodes in Latvia that have at least one tag containing "addr", except "old_addr", "addr:unit", "addr:door", "addr:flats" and "addr:floor".
INSERT INTO nodes_old (
  id
  ,version
  ,user_id
  ,tstamp
  ,changeset_id
  ,tags
  ,geom
  )
SELECT a.id
  ,a.version
  ,a.user_id
  ,a.tstamp
  ,a.changeset_id
  ,a.tags
  ,a.geom
FROM nodes a
INNER JOIN nodes_lv b ON a.id = b.id
WHERE a.tags ?| (
    SELECT array_agg(tag)
    FROM tags
    WHERE tag LIKE '%addr%'
      AND tag NOT LIKE 'old_addr%'
      AND tag NOT LIKE 'addr:unit'
      AND tag NOT LIKE 'addr:door'
      AND tag NOT LIKE 'addr:flats'
      AND tag NOT LIKE 'addr:floor'
    )
ORDER BY id;

--Delete all tags in Latvia from nodes containing "addr", except "old_addr", "addr:unit", "addr:door", "addr:flats" and "addr:floor".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'old_addr%'
        AND tag NOT LIKE 'addr:unit'
        AND tag NOT LIKE 'addr:door'
        AND tag NOT LIKE 'addr:flats'
        AND tag NOT LIKE 'addr:floor'
      ) tags
  FROM nodes a
  INNER JOIN nodes_lv b ON a.id = b.id
  WHERE a.tags ?| (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'old_addr%'
        AND tag NOT LIKE 'addr:unit'
        AND tag NOT LIKE 'addr:door'
        AND tag NOT LIKE 'addr:flats'
        AND tag NOT LIKE 'addr:floor'
      )
  )
UPDATE nodes
SET tags = s.tags
FROM s
WHERE nodes.id = s.id;

--Table for old version of changed ways for comparison.
DROP TABLE IF EXISTS ways_old;

CREATE TABLE ways_old (
  id BIGINT NOT NULL PRIMARY KEY
  ,version INT NOT NULL
  ,user_id INT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tags hstore
  ,nodes BIGINT []
  );

---Insert all ways in Latvia that have at least one tag containing "addr", except "old_addr" and "addr:unit".
INSERT INTO ways_old (
  id
  ,version
  ,user_id
  ,tstamp
  ,changeset_id
  ,tags
  ,nodes
  )
SELECT a.id
  ,a.version
  ,a.user_id
  ,a.tstamp
  ,a.changeset_id
  ,a.tags
  ,a.nodes
FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
WHERE a.tags ?| (
    SELECT array_agg(tag)
    FROM tags
    WHERE tag LIKE '%addr%'
      AND tag NOT LIKE 'old_addr%'
      AND tag NOT LIKE 'addr:unit'
    )
ORDER BY id;

--Delete all tags in Latvia from ways containing "addr", except "old_addr" and "addr:unit".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'old_addr%'
        AND tag NOT LIKE 'addr:unit'
      ) tags
  FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
  WHERE a.tags ?| (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'old_addr%'
        AND tag NOT LIKE 'addr:unit'
      )
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

--Table for old version of changed relations for comparison.
DROP TABLE IF EXISTS relations_old;

CREATE TABLE relations_old (
  id BIGINT NOT NULL PRIMARY KEY
  ,version INT NOT NULL
  ,user_id INT NOT NULL
  ,tstamp TIMESTAMP WITHOUT TIME ZONE NOT NULL
  ,changeset_id BIGINT NOT NULL
  ,tags hstore
  );

---Insert all relations in Latvia that have at least one tag containing "addr", except "old_addr" and "addr:region".
INSERT INTO relations_old (
  id
  ,version
  ,user_id
  ,tstamp
  ,changeset_id
  ,tags
  )
SELECT a.id
  ,a.version
  ,a.user_id
  ,a.tstamp
  ,a.changeset_id
  ,a.tags
FROM relations a
INNER JOIN relations_lv b ON a.id = b.id
WHERE a.tags ?| (
    SELECT array_agg(tag)
    FROM tags
    WHERE tag LIKE '%addr%'
      AND tag NOT LIKE 'old_addr%'
      AND tag NOT LIKE 'addr:region'
    )
ORDER BY id;

--Delete all tags in Latvia from relations containing "addr", except "old_addr" and "addr:region".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'old_addr%'
        AND tag NOT LIKE 'addr:region'
      ) tags
  FROM relations a
  INNER JOIN relations_lv b ON a.id = b.id
  WHERE a.tags ?| (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'old_addr%'
        AND tag NOT LIKE 'addr:region'
      )
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--Relations containing building polygons.
CREATE TEMPORARY TABLE relations_geometry AS
WITH i
AS (
  SELECT a.id
    ,ST_Union(c.geom) geom_o
    ,ST_Union(ci.geom) geom_i
  FROM relations a
  INNER JOIN relation_members b ON a.id = b.relation_id
  INNER JOIN way_geometry c ON b.member_id = c.way_id
  INNER JOIN relation_members bi ON a.id = bi.relation_id
  INNER JOIN way_geometry ci ON bi.member_id = ci.way_id
  WHERE tags ? 'building'
    AND b.member_role LIKE 'outer'
    AND ST_GeometryType(c.geom) = 'ST_LineString'
    AND bi.member_role LIKE 'inner'
    AND ST_GeometryType(ci.geom) = 'ST_LineString'
  GROUP BY a.id
  )
  ,o
AS (
  SELECT a.id
    ,ST_Union(c.geom) geom
  FROM relations a
  INNER JOIN relation_members b ON a.id = b.relation_id
  INNER JOIN way_geometry c ON b.member_id = c.way_id
  LEFT OUTER JOIN relation_members bi ON a.id = bi.relation_id
    AND bi.member_role LIKE 'inner'
  WHERE tags ? 'building'
    AND b.member_role LIKE 'outer'
    AND ST_GeometryType(c.geom) = 'ST_LineString'
    AND bi.relation_id IS NULL
  GROUP BY a.id
  )
SELECT id
  ,ST_Difference(ST_Polygonize(geom_o), ST_Polygonize(geom_i)) geom
FROM i
GROUP BY id

UNION

SELECT id
  ,ST_Polygonize(geom) geom
FROM o
GROUP BY id

UNION

SELECT a.id
  ,ST_Difference(c.geom, ST_Union(ci.geom)) geom
FROM relations a
INNER JOIN relation_members b ON a.id = b.relation_id
INNER JOIN way_geometry c ON b.member_id = c.way_id
INNER JOIN relation_members bi ON a.id = bi.relation_id
INNER JOIN way_geometry ci ON bi.member_id = ci.way_id
WHERE tags ? 'building'
  AND b.member_role LIKE 'outer'
  AND ST_GeometryType(c.geom) = 'ST_Polygon'
  AND bi.member_role LIKE 'inner'
  AND ST_GeometryType(ci.geom) = 'ST_Polygon'
GROUP BY a.id
  ,c.geom

UNION

SELECT a.id
  ,c.geom
FROM relations a
INNER JOIN relation_members b ON a.id = b.relation_id
INNER JOIN way_geometry c ON b.member_id = c.way_id
LEFT OUTER JOIN relation_members bi ON a.id = bi.relation_id
  AND bi.member_role LIKE 'inner'
WHERE tags ? 'building'
  AND b.member_role LIKE 'outer'
  AND ST_GeometryType(c.geom) = 'ST_Polygon'
  AND bi.relation_id IS NULL;

--Add addresses for building polygons from the State Address Register. Polygon contains only one address point.
---Ways.
CREATE TEMPORARY TABLE ways_addr_add AS
WITH c
AS (
  SELECT a.id
  FROM ways a
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  WHERE a.tags ? 'building'
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id
WHERE a.tags ? 'building';

ALTER TABLE ways_addr_add ADD PRIMARY KEY (id);

UPDATE ways
SET tags = s.tags
FROM ways_addr_add s
WHERE ways.id = s.id;

---Relations.
CREATE TEMPORARY TABLE relations_addr_add AS
WITH c
AS (
  SELECT a.id
  FROM relations a
  INNER JOIN relations_geometry g ON a.id = g.id
  INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  WHERE a.tags ? 'building'
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id
WHERE a.tags ? 'building';

ALTER TABLE relations_addr_add ADD PRIMARY KEY (id);

UPDATE relations
SET tags = s.tags
FROM relations_addr_add s
WHERE relations.id = s.id;

--Add remaining addresses for building polygons from the State Address Register. Polygon covers more than half of building polygon in cadaster containing address point from which the address is taken.
---Ways.
CREATE TEMPORARY TABLE ways_addr_add_2 AS
WITH c
AS (
  SELECT a.id
  FROM ways a
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
  INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
  LEFT OUTER JOIN (
    SELECT id
    FROM ways
    WHERE tags ? 'ref:LV:addr'
    ) f ON a.id = f.id
  WHERE a.tags ? 'building'
    AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5
    AND f.id IS NULL
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
INNER JOIN c ON a.id = c.id
WHERE a.tags ? 'building'
  AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5;

ALTER TABLE ways_addr_add_2 ADD PRIMARY KEY (id);

UPDATE ways
SET tags = s.tags
FROM ways_addr_add_2 s
WHERE ways.id = s.id;

---Relations.
CREATE TEMPORARY TABLE relations_addr_add_2 AS
WITH c
AS (
  SELECT a.id
  FROM relations a
  INNER JOIN relations_geometry g ON a.id = g.id
  INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
  INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
  LEFT OUTER JOIN (
    SELECT id
    FROM relations
    WHERE tags ? 'ref:LV:addr'
    ) f ON a.id = f.id
  WHERE a.tags ? 'building'
    AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5
    AND f.id IS NULL
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
INNER JOIN c ON a.id = c.id
WHERE a.tags ? 'building'
  AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5;

ALTER TABLE relations_addr_add_2 ADD PRIMARY KEY (id);

UPDATE relations
SET tags = s.tags
FROM relations_addr_add_2 s
WHERE relations.id = s.id;

--Delete ways that are not part of relations, have no tags, but previously had only address tags.
DELETE
FROM ways
WHERE tags = ''::hstore
  AND id NOT IN (
    SELECT DISTINCT member_id
    FROM relation_members
    WHERE member_type = 'W')
      AND id IN (
        SELECT id
        FROM ways_old
        );

--Delete relations that have no tags, but previously had only address tags.
DELETE
FROM relations
WHERE tags = ''::hstore
  AND id IN (
    SELECT id
    FROM relations_old
    );

--Add addresses for address points (nodes containing only addr:* tags) from the State Address Register. Only address codes not already assigned to ways (buildings).
---Address code matches (address points added previously).
CREATE TEMPORARY TABLE nodes_addr_add_5 AS
SELECT a.id
  ,(hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:housename', v.nosaukums) || hstore('addr:street', v.iela) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:housename=>NULL, addr:street=>NULL, addr:housenumber=>NULL'::hstore tags
  ,v.geom
FROM nodes a
INNER JOIN nodes_old o ON a.id = o.id
INNER JOIN adreses_ekas_sadalitas v ON o.tags -> 'ref:LV:addr' = v.adr_cd::TEXT
LEFT OUTER JOIN nodes_unnest t ON a.id = t.id
  AND t.tag NOT LIKE 'addr:%'
  AND t.tag NOT LIKE 'ref:LV:addr'
WHERE t.id IS NULL
  AND v.adr_cd NOT IN (
    SELECT CAST(tags -> 'ref:LV:addr' AS INT) adr_cd
    FROM ways
    WHERE tags ? 'ref:LV:addr'
    );

ALTER TABLE nodes_addr_add_5 ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
  ,geom = s.geom
FROM nodes_addr_add_5 s
WHERE nodes.id = s.id;

---House names matches, distance up to 0.01 decimal degree (~1.1 km).
CREATE TEMPORARY TABLE nodes_addr_add AS
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:housename', v.nosaukums) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:housename=>NULL'::hstore tags
  ,v.geom
FROM nodes a
INNER JOIN nodes_old o ON a.id = o.id
  AND o.tags ? 'addr:housename'
LEFT OUTER JOIN nodes_unnest t ON a.id = t.id
  AND t.tag NOT LIKE 'addr:%'
  AND t.tag NOT LIKE 'ref:LV:addr'
CROSS JOIN LATERAL(SELECT v.*, v.geom <-> a.geom AS dist FROM adreses_ekas_sadalitas v WHERE REPLACE(o.tags -> 'addr:housename'::TEXT, ' ', '') LIKE REPLACE(v.nosaukums, ' ', '') ORDER BY dist LIMIT 1) v
WHERE t.id IS NULL
  AND v.dist < 0.01
  AND v.adr_cd NOT IN (
    SELECT CAST(tags -> 'ref:LV:addr' AS INT) adr_cd
    FROM ways
    WHERE tags ? 'ref:LV:addr'
    )
  AND v.adr_cd NOT IN (
    SELECT CAST(tags -> 'ref:LV:addr' AS INT) adr_cd
    FROM nodes
    WHERE tags ? 'ref:LV:addr'
    );

ALTER TABLE nodes_addr_add ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
  ,geom = s.geom
FROM nodes_addr_add s
WHERE nodes.id = s.id;

---House number and street matches, distance up to 0.01 decimal degree (~1.1 km).
CREATE TEMPORARY TABLE nodes_addr_add_2 AS
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housenumber=>NULL'::hstore tags
  ,v.geom
FROM nodes a
INNER JOIN nodes_old o ON a.id = o.id
  AND o.tags ?& ARRAY['addr:housenumber', 'addr:street']
LEFT OUTER JOIN nodes_unnest t ON a.id = t.id
  AND t.tag NOT LIKE 'addr:%'
  AND t.tag NOT LIKE 'ref:LV:addr'
CROSS JOIN LATERAL(SELECT v.*, v.geom <-> a.geom AS dist FROM adreses_ekas_sadalitas v WHERE REPLACE(o.tags -> 'addr:housenumber'::TEXT, ' ', '') LIKE REPLACE(v.nr, ' ', '')
    AND REPLACE(o.tags -> 'addr:street'::TEXT, ' ', '') LIKE REPLACE(v.iela, ' ', '') ORDER BY dist LIMIT 1) v
WHERE t.id IS NULL
  AND v.dist < 0.01
  AND v.adr_cd NOT IN (
    SELECT CAST(tags -> 'ref:LV:addr' AS INT) adr_cd
    FROM ways
    WHERE tags ? 'ref:LV:addr'
    )
  AND v.adr_cd NOT IN (
    SELECT CAST(tags -> 'ref:LV:addr' AS INT) adr_cd
    FROM nodes
    WHERE tags ? 'ref:LV:addr'
    );

ALTER TABLE nodes_addr_add_2 ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
  ,geom = s.geom
FROM nodes_addr_add_2 s
WHERE nodes.id = s.id;

--Delete nodes that are not part of relations, have no tags, but previously had only address tags.
DELETE
FROM nodes
WHERE tags = ''::hstore
  AND id NOT IN (
    SELECT DISTINCT member_id
    FROM relation_members
    WHERE member_type = 'N')
      AND id IN (
        SELECT id
        FROM nodes_old
        );

--Insert missing addresses.
INSERT INTO nodes (
  id
  ,version
  ,user_id
  ,tstamp
  ,changeset_id
  ,tags
  ,geom
  )
SELECT - ROW_NUMBER() OVER()
  ,1
  ,15008076
  ,NOW()::TIMESTAMP
  ,-1
  ,(hstore('addr:country', 'LV') || hstore('addr:district', novads) || hstore('addr:city', pilseta) || hstore('addr:subdistrict', pagasts) || hstore('addr:place', ciems) || hstore('addr:street', iela) || hstore('addr:housename', nosaukums) || hstore('addr:housenumber', nr) || hstore('addr:postcode', atrib) || hstore('ref:LV:addr', adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore
  ,geom
FROM adreses_ekas_sadalitas
WHERE adr_cd NOT IN (
    SELECT CAST(tags -> 'ref:LV:addr' AS INT) adr_cd
    FROM ways
    WHERE tags ? 'ref:LV:addr'
    )
  AND adr_cd NOT IN (
    SELECT CAST(tags -> 'ref:LV:addr' AS INT) adr_cd
    FROM nodes
    WHERE tags ? 'ref:LV:addr'
    );

--Add addresses for other objects beside buildings and address points.
--Relations containing polygons of other objects beside buildings that can have an address.
CREATE TEMPORARY TABLE tags_4_addresses_relations AS
WITH t
AS (
  SELECT id
    ,UNNEST((%# tags) [1:999] [1]) tag
    ,UNNEST((%# tags) [1:999] [2:2]) val
  FROM relations
  WHERE id NOT IN (
      SELECT id
      FROM relations
      WHERE tags ? 'ref:LV:addr'
      )
  )
SELECT DISTINCT t.id
FROM t
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE w = true
  ) a ON t.tag = a.key
  AND t.val = a.value
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE value IS NULL
    AND w = true
  ) b ON t.tag = b.key
WHERE a.value IS NOT NULL
  OR b.key IS NOT NULL;

CREATE TEMPORARY TABLE relations_geometry_2 AS
WITH i
AS (
  SELECT a.id
    ,ST_Union(c.geom) geom_o
    ,ST_Union(ci.geom) geom_i
  FROM relations a
  INNER JOIN relation_members b ON a.id = b.relation_id
  INNER JOIN way_geometry c ON b.member_id = c.way_id
  INNER JOIN relation_members bi ON a.id = bi.relation_id
  INNER JOIN way_geometry ci ON bi.member_id = ci.way_id
  INNER JOIN tags_4_addresses_relations t ON a.id = t.id
  WHERE b.member_role LIKE 'outer'
    AND ST_GeometryType(c.geom) = 'ST_LineString'
    AND bi.member_role LIKE 'inner'
    AND ST_GeometryType(ci.geom) = 'ST_LineString'
  GROUP BY a.id
  )
  ,o
AS (
  SELECT a.id
    ,ST_Union(c.geom) geom
  FROM relations a
  INNER JOIN relation_members b ON a.id = b.relation_id
  INNER JOIN way_geometry c ON b.member_id = c.way_id
  LEFT OUTER JOIN relation_members bi ON a.id = bi.relation_id
    AND bi.member_role LIKE 'inner'
  INNER JOIN tags_4_addresses_relations t ON a.id = t.id
  WHERE b.member_role LIKE 'outer'
    AND ST_GeometryType(c.geom) = 'ST_LineString'
    AND bi.relation_id IS NULL
  GROUP BY a.id
  )
SELECT id
  ,ST_Difference(ST_Polygonize(geom_o), ST_Polygonize(geom_i)) geom
FROM i
GROUP BY id

UNION

SELECT id
  ,ST_Polygonize(geom) geom
FROM o
GROUP BY id

UNION

SELECT a.id
  ,ST_Difference(c.geom, ST_Union(ci.geom)) geom
FROM relations a
INNER JOIN relation_members b ON a.id = b.relation_id
INNER JOIN way_geometry c ON b.member_id = c.way_id
INNER JOIN relation_members bi ON a.id = bi.relation_id
INNER JOIN way_geometry ci ON bi.member_id = ci.way_id
INNER JOIN tags_4_addresses_relations t ON a.id = t.id
WHERE b.member_role LIKE 'outer'
  AND ST_GeometryType(c.geom) = 'ST_Polygon'
  AND bi.member_role LIKE 'inner'
  AND ST_GeometryType(ci.geom) = 'ST_Polygon'
GROUP BY a.id
  ,c.geom

UNION

SELECT a.id
  ,c.geom
FROM relations a
INNER JOIN relation_members b ON a.id = b.relation_id
INNER JOIN way_geometry c ON b.member_id = c.way_id
LEFT OUTER JOIN relation_members bi ON a.id = bi.relation_id
  AND bi.member_role LIKE 'inner'
INNER JOIN tags_4_addresses_relations t ON a.id = t.id
WHERE b.member_role LIKE 'outer'
  AND ST_GeometryType(c.geom) = 'ST_Polygon'
  AND bi.relation_id IS NULL;

---Ways. Polygon contains only one address point.
CREATE TEMPORARY TABLE tags_4_addresses_ways AS
WITH t
AS (
  SELECT id
    ,UNNEST((%# tags) [1:999] [1]) tag
    ,UNNEST((%# tags) [1:999] [2:2]) val
  FROM ways
  WHERE id NOT IN (
      SELECT id
      FROM ways
      WHERE tags ? 'ref:LV:addr'
      )
  )
SELECT DISTINCT t.id
FROM t
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE w = true
  ) a ON t.tag = a.key
  AND t.val = a.value
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE value IS NULL
    AND w = true
  ) b ON t.tag = b.key
WHERE a.value IS NOT NULL
  OR b.key IS NOT NULL;

CREATE TEMPORARY TABLE ways_addr_add_3 AS
WITH c
AS (
  SELECT a.id
  FROM ways a
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_ways t ON a.id = t.id
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id;

ALTER TABLE ways_addr_add_3 ADD PRIMARY KEY (id);

UPDATE ways
SET tags = s.tags
FROM ways_addr_add_3 s
WHERE ways.id = s.id;

---Relations containing ways. Polygon contains only one address point.
CREATE TEMPORARY TABLE relations_addr_add_3 AS
WITH c
AS (
  SELECT a.id
  FROM relations a
  INNER JOIN relations_geometry_2 g ON a.id = g.id
  INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_relations t ON a.id = t.id
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry_2 g ON a.id = g.id
INNER JOIN adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id;

ALTER TABLE relations_addr_add_3 ADD PRIMARY KEY (id);

UPDATE relations
SET tags = s.tags
FROM relations_addr_add_3 s
WHERE relations.id = s.id;

--Nodes.
---Address taken from the OSM building polygon (way or relation) where node is located. Node contained by only one polygon.
CREATE TEMPORARY TABLE tags_4_addresses_nodes AS
WITH t
AS (
  SELECT *
  FROM nodes_unnest
  WHERE id NOT IN (
      SELECT id
      FROM nodes
      WHERE tags ? 'ref:LV:addr'
      )
  )
SELECT DISTINCT t.id
FROM t
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE n_buildings = true
  ) a ON t.tag = a.key
  AND t.val = a.value
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE value IS NULL
    AND n_buildings = true
  ) b ON t.tag = b.key
WHERE a.value IS NOT NULL
  OR b.key IS NOT NULL;

CREATE TEMPORARY TABLE building_addr_geom AS
SELECT a.id
  ,a.tags
  ,g.geom
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
WHERE a.tags ?& ARRAY ['building', 'ref:LV:addr']

UNION

SELECT a.id
  ,a.tags
  ,g.geom
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
WHERE a.tags ?& ARRAY ['building', 'ref:LV:addr'];

CREATE INDEX building_addr_geom_geom_idx ON building_addr_geom USING GIST (geom);

CREATE TEMPORARY TABLE nodes_addr_add_3 AS
WITH c
AS (
  SELECT a.id
  FROM nodes a
  INNER JOIN building_addr_geom v ON ST_Contains(v.geom, a.geom)
  INNER JOIN tags_4_addresses_nodes t ON a.id = t.id
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.tags -> 'addr:district') || hstore('addr:city', v.tags -> 'addr:city') || hstore('addr:subdistrict', v.tags -> 'addr:subdistrict') || hstore('addr:place', v.tags -> 'addr:place') || hstore('addr:street', v.tags -> 'addr:street') || hstore('addr:housename', v.tags -> 'addr:housename') || hstore('addr:housenumber', v.tags -> 'addr:housenumber') || hstore('addr:postcode', v.tags -> 'addr:postcode') || hstore('ref:LV:addr', v.tags -> 'ref:LV:addr')) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM nodes a
INNER JOIN building_addr_geom v ON ST_Contains(v.geom, a.geom)
INNER JOIN c ON a.id = c.id;

ALTER TABLE nodes_addr_add_3 ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
FROM nodes_addr_add_3 s
WHERE nodes.id = s.id;

---Address taken from the address of the land parcel from the State Immovable Property Cadastre Information System where node is located.
CREATE TEMPORARY TABLE tags_4_addresses_nodes_2 AS
WITH t
AS (
  SELECT *
  FROM nodes_unnest
  WHERE id NOT IN (
      SELECT id
      FROM nodes
      WHERE tags ? 'ref:LV:addr'
      )
  )
SELECT DISTINCT t.id
FROM t
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE n_parcels = true
  ) a ON t.tag = a.key
  AND t.val = a.value
LEFT OUTER JOIN (
  SELECT *
  FROM tags_4_addresses
  WHERE value IS NULL
    AND n_parcels = true
  ) b ON t.tag = b.key
WHERE a.value IS NOT NULL
  OR b.key IS NOT NULL;

CREATE TEMPORARY TABLE nodes_addr_add_4 AS
WITH v
AS (
  SELECT c.adr_cd
    ,c.nr
    ,c.nosaukums
    ,c.iela
    ,c.ciems
    ,c.pagasts
    ,c.pilseta
    ,c.novads
    ,a.geom
  FROM vzd.nivkis_zemes_vienibas a
  INNER JOIN vzd.nivkis_adreses b ON a.code = b."ObjectCadastreNr"
  INNER JOIN adreses_ekas_sadalitas c ON b."ARCode" = c.adr_cd
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', v.pilseta) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:place', v.ciems) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:place=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL'::hstore tags
FROM nodes a
INNER JOIN tags_4_addresses_nodes_2 t ON a.id = t.id
INNER JOIN v ON ST_Contains(v.geom, a.geom);

ALTER TABLE nodes_addr_add_4 ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
FROM nodes_addr_add_4 s
WHERE nodes.id = s.id;

END;
$BODY$;

REVOKE ALL ON PROCEDURE addresses() FROM PUBLIC;
