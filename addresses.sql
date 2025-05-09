-- PROCEDURE: public.addresses()

-- DROP PROCEDURE IF EXISTS public.addresses();

CREATE OR REPLACE PROCEDURE public.addresses(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN

/*
--In case materialized view vzd.state is used and smaller territory than state is selected in it, create temporary table to contain data from table vzd.adreses_ekas_sadalitas only within selected territory. Replace vzd.adreses_ekas_sadalitas with adreses_ekas_sadalitas elsewhere in the procedure.
CREATE TEMPORARY TABLE adreses_ekas_sadalitas AS
SELECT a.*
FROM vzd.adreses_ekas_sadalitas a
INNER JOIN vzd.state b ON ST_Within(a.geom, b.geom);
CREATE INDEX adreses_ekas_sadalitas_geom_idx ON adreses_ekas_sadalitas USING GIST (geom);
*/

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

---Insert all nodes in Latvia that have at least one tag containing "addr", except "addr:unit", "addr:door", "addr:flats", "addr:floor" and "operator:addr*".
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
      AND tag NOT LIKE 'addr:unit'
      AND tag NOT LIKE 'addr:door'
      AND tag NOT LIKE 'addr:flats'
      AND tag NOT LIKE 'addr:floor'
      AND tag NOT LIKE 'operator:addr%'
    )
ORDER BY id;

--Delete all tags in Latvia from nodes containing "addr", except "addr:unit", "addr:door", "addr:flats", "addr:floor" and "operator:addr*".
CREATE TEMPORARY TABLE nodes_ids AS
SELECT a.id
  ,a.tags - (
    SELECT array_agg(tag)
    FROM tags
    WHERE tag LIKE '%addr%'
      AND tag NOT LIKE 'addr:unit'
      AND tag NOT LIKE 'addr:door'
      AND tag NOT LIKE 'addr:flats'
      AND tag NOT LIKE 'addr:floor'
      AND tag NOT LIKE 'operator:addr%'
    ) tags
FROM nodes a
INNER JOIN nodes_lv b ON a.id = b.id
WHERE a.tags ?| (
    SELECT array_agg(tag)
    FROM tags
    WHERE tag LIKE '%addr%'
      AND tag NOT LIKE 'addr:unit'
      AND tag NOT LIKE 'addr:door'
      AND tag NOT LIKE 'addr:flats'
      AND tag NOT LIKE 'addr:floor'
      AND tag NOT LIKE 'operator:addr%'
    );

ALTER TABLE nodes_ids ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
FROM nodes_ids s
WHERE nodes.id = s.id;

--Delete tags that resemble addresses or indicate that there is no address.
CREATE TEMPORARY TABLE nodes_update AS
SELECT a.id
FROM nodes a
INNER JOIN nodes_lv b ON a.id = b.id
WHERE a.tags ?| ARRAY ['city', 'county', 'district', 'housename', 'housenumber', 'parish', 'postal_code', 'postcode', 'street', 'subdistrict', 'noaddress', 'nohousenumber'];

UPDATE nodes
SET tags = tags - 'city'::TEXT - 'county'::TEXT - 'district'::TEXT - 'housename'::TEXT - 'housenumber'::TEXT - 'parish'::TEXT - 'postal_code'::TEXT - 'postcode'::TEXT - 'street'::TEXT - 'subdistrict'::TEXT - 'noaddress'::TEXT - 'nohousenumber'::TEXT
WHERE id IN (
    SELECT id
    FROM nodes_update
    );

CREATE TEMPORARY TABLE nodes_update_2 AS
SELECT a.id
FROM nodes a
INNER JOIN nodes_lv b ON a.id = b.id
WHERE a.tags ? 'country'
  AND NOT (a.tags ? 'office')
  AND NOT (a.tags ? 'man_made');

UPDATE nodes
SET tags = tags - 'country'::TEXT
WHERE id IN (
    SELECT id
    FROM nodes_update_2
    );

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

---Insert all ways in Latvia that have at least one tag containing "addr", except "addr:unit", "addr:floor" and "operator:addr*".
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
      AND tag NOT LIKE 'addr:unit'
      AND tag NOT LIKE 'addr:floor'
      AND tag NOT LIKE 'operator:addr%'
    )
ORDER BY id;

--Delete all tags in Latvia from ways containing "addr", except "addr:unit", "addr:floor" and "operator:addr*".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'addr:unit'
        AND tag NOT LIKE 'addr:floor'
        AND tag NOT LIKE 'operator:addr%'
      ) tags
  FROM ways a
  INNER JOIN ways_lv b ON a.id = b.id
  WHERE a.tags ?| (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'addr:unit'
        AND tag NOT LIKE 'addr:floor'
        AND tag NOT LIKE 'operator:addr%'
      )
  )
UPDATE ways
SET tags = s.tags
FROM s
WHERE ways.id = s.id;

--Delete tags that resemble addresses or indicate that there is no address.
CREATE TEMPORARY TABLE ways_update AS
SELECT a.id
FROM ways a
INNER JOIN ways_lv b ON a.id = b.id
WHERE a.tags ?| ARRAY ['city', 'county', 'district', 'housename', 'housenumber', 'parish', 'postal_code', 'postcode', 'street', 'subdistrict', 'noaddress', 'nohousenumber'];

UPDATE ways
SET tags = tags - 'city'::TEXT - 'county'::TEXT - 'district'::TEXT - 'housename'::TEXT - 'housenumber'::TEXT - 'parish'::TEXT - 'postal_code'::TEXT - 'postcode'::TEXT - 'street'::TEXT - 'subdistrict'::TEXT - 'noaddress'::TEXT - 'nohousenumber'::TEXT
WHERE id IN (
    SELECT id
    FROM ways_update
    );

CREATE TEMPORARY TABLE ways_update_2 AS
SELECT a.id
FROM ways a
INNER JOIN ways_lv b ON a.id = b.id
WHERE a.tags ? 'country'
  AND NOT (a.tags ? 'office')
  AND NOT (a.tags ? 'man_made');

UPDATE ways
SET tags = tags - 'country'::TEXT
WHERE id IN (
    SELECT id
    FROM ways_update_2
    );

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

---Insert all relations in Latvia that have at least one tag containing "addr", except "addr:region" and "operator:addr*".
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
      AND tag NOT LIKE 'addr:region'
      AND tag NOT LIKE 'operator:addr%'
    )
ORDER BY id;

--Delete all tags in Latvia from relations containing "addr", except "addr:region" and "operator:addr*".
WITH s
AS (
  SELECT a.id
    ,a.tags - (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'addr:region'
        AND tag NOT LIKE 'operator:addr%'
      ) tags
  FROM relations a
  INNER JOIN relations_lv b ON a.id = b.id
  WHERE a.tags ?| (
      SELECT array_agg(tag)
      FROM tags
      WHERE tag LIKE '%addr%'
        AND tag NOT LIKE 'addr:region'
        AND tag NOT LIKE 'operator:addr%'
      )
  )
UPDATE relations
SET tags = s.tags
FROM s
WHERE relations.id = s.id;

--Add address for the closest isolated dwelling whose name matches and is located no more than 25 m from the address point. While data quality of isolated dwellings is being improved, only for nodes that list the Place Names Database as source.
CREATE TEMPORARY TABLE nodes_addr_add_iso_dw AS
SELECT a.id
  ,a.tags || hstore('name', COALESCE(v.nosaukums, v.nr)) || (hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
FROM nodes a
INNER JOIN nodes_lv l ON a.id = l.id
CROSS JOIN LATERAL(SELECT b.*, b.geom <-> a.geom AS dist FROM vzd.adreses_ekas_sadalitas b WHERE b.iela IS NULL ORDER BY dist LIMIT 1) v
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
WHERE a.tags -> 'place' LIKE 'isolated_dwelling'
  AND LOWER(a.tags -> 'source') LIKE 'lģia vietvārdu db'
  AND (
    LOWER(a.tags -> 'name') = LOWER(v.nosaukums)
    OR LOWER(a.tags -> 'name') = LOWER(v.nr)
    )
  AND ST_Transform(v.geom, 3059) <-> ST_Transform(a.geom, 3059) <= 25;

ALTER TABLE nodes_addr_add_iso_dw ADD PRIMARY KEY (id);

UPDATE nodes_addr_add_iso_dw
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE nodes_addr_add_iso_dw
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE nodes_addr_add_iso_dw
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

UPDATE nodes
SET tags = s.tags
FROM nodes_addr_add_iso_dw s
WHERE nodes.id = s.id;

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

--Add addresses for building polygons from the State Address Register. Polygon contains only one address point. Only address codes not already assigned to isolated dwellings.
---Ways.
CREATE TEMPORARY TABLE ways_addr_add AS
WITH c
AS (
  SELECT a.id
  FROM ways a
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  WHERE a.tags ? 'building'
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM nodes
  WHERE tags ? 'ref:LV:addr'
  ) n ON v.adr_cd::TEXT = n.adr_cd
WHERE a.tags ? 'building'
  AND n.adr_cd IS NULL;

ALTER TABLE ways_addr_add ADD PRIMARY KEY (id);

UPDATE ways_addr_add
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE ways_addr_add
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE ways_addr_add
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

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
  INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  WHERE a.tags ? 'building'
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM nodes
  WHERE tags ? 'ref:LV:addr'
  ) n ON v.adr_cd::TEXT = n.adr_cd
WHERE a.tags ? 'building'
  AND n.adr_cd IS NULL;

ALTER TABLE relations_addr_add ADD PRIMARY KEY (id);

UPDATE relations_addr_add
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE relations_addr_add
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE relations_addr_add
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

UPDATE relations
SET tags = s.tags
FROM relations_addr_add s
WHERE relations.id = s.id;

--Add remaining addresses for building polygons from the State Address Register. Polygon covers more than half of building polygon in cadaster containing address point from which the address is taken. Only address codes not already assigned to isolated dwellings.
---Ways.
CREATE TEMPORARY TABLE ways_addr_add_2_ids AS
SELECT a.id
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
LEFT OUTER JOIN (
  SELECT id
  FROM ways
  WHERE tags ? 'ref:LV:addr'
  ) f ON a.id = f.id
WHERE a.tags ? 'building'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5
  AND f.id IS NULL
GROUP BY a.id
HAVING COUNT(*) = 1;

ALTER TABLE ways_addr_add_2_ids ADD PRIMARY KEY (id);

CREATE TEMPORARY TABLE ways_addr_add_2 AS
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
INNER JOIN ways_addr_add_2_ids c ON a.id = c.id
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
LEFT OUTER JOIN nodes d ON v.adr_cd::TEXT = d.tags -> 'ref:LV:addr'
  AND d.tags ? 'ref:LV:addr'
WHERE a.tags ? 'building'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5
  AND d.id IS NULL;

ALTER TABLE ways_addr_add_2 ADD PRIMARY KEY (id);

UPDATE ways_addr_add_2
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE ways_addr_add_2
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE ways_addr_add_2
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

UPDATE ways
SET tags = s.tags
FROM ways_addr_add_2 s
WHERE ways.id = s.id;

---Relations.
CREATE TEMPORARY TABLE relations_addr_add_2_ids AS
SELECT a.id
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
LEFT OUTER JOIN (
  SELECT id
  FROM relations
  WHERE tags ? 'ref:LV:addr'
  ) f ON a.id = f.id
WHERE a.tags ? 'building'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5
  AND f.id IS NULL
GROUP BY a.id
HAVING COUNT(*) = 1;

ALTER TABLE relations_addr_add_2_ids ADD PRIMARY KEY (id);

CREATE TEMPORARY TABLE relations_addr_add_2 AS
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN vzd.nivkis_buves n ON ST_Intersects(g.geom, n.geom)
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, n.geom)
INNER JOIN relations_addr_add_2_ids c ON a.id = c.id
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
WHERE a.tags ? 'building'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, n.geom)) / ST_Area(g.geom) > 0.5
  AND v.adr_cd::TEXT NOT IN (
    SELECT tags -> 'ref:LV:addr' adr_cd
    FROM nodes
    WHERE tags ? 'ref:LV:addr'
    );

ALTER TABLE relations_addr_add_2 ADD PRIMARY KEY (id);

UPDATE relations_addr_add_2
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE relations_addr_add_2
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE relations_addr_add_2
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

UPDATE relations
SET tags = s.tags
FROM relations_addr_add_2 s
WHERE relations.id = s.id;

--Table for deleted ways and relations to facilitate object identification as in some cases such objects are buildings that miss building tags and have only address tags added by other users.
DROP TABLE IF EXISTS ways_relations_del;

CREATE TABLE ways_relations_del (
  id SERIAL PRIMARY KEY
  ,link TEXT NOT NULL
  );

--Delete relations that have no tags except type, but previously besides type had only address tags.
CREATE TEMPORARY TABLE relations_del AS
SELECT id
FROM relations
WHERE tags - 'type'::text = ''::hstore
  AND id IN (
    SELECT id
    FROM relations_old
    );

INSERT INTO ways_relations_del (link)
SELECT 'https://www.openstreetmap.org/relation/' || id || '/history'
FROM relations_del;

--Commented according to suggestion at https://osmlatvija.github.io/zulip-archive/stream/360959-adreses/topic/Bots.20nodz.C4.93sa.20.22m.C4.81ju.22.html#396575119. As such cases are not common and mostly relations with only address tags are buildings missing building tags, it makes more sense not to delete them but forward to Zulip for manual review.
/*
DELETE
FROM relations
WHERE id IN (
    SELECT id
    FROM relations_del
    );

CREATE TEMPORARY TABLE relation_members_del AS
SELECT *
FROM relation_members
WHERE relation_id IN (
    SELECT id
    FROM relations_del
    );

DELETE
FROM relation_members
WHERE relation_id IN (
    SELECT id
    FROM relations_del
    );
*/

--Delete ways that are not part of relations, have no tags, but previously had only address tags.
CREATE TEMPORARY TABLE ways_del AS
SELECT id
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

INSERT INTO ways_relations_del (link)
SELECT 'https://www.openstreetmap.org/way/' || id || '/history'
FROM ways_del;

--Commented due to bug in smarter-sort.py. Should be fixed manually by inspecting ways_relations_del.
/*
--Delete ways that were only part of previously deleted relations and have no tags.
INSERT INTO ways_del
SELECT a.id
FROM ways a
LEFT OUTER JOIN (
  SELECT DISTINCT member_id
  FROM relation_members
  WHERE member_type = 'W'
  ) c ON a.id = c.member_id
WHERE a.tags = ''::hstore
  AND c.member_id IS NULL
  AND a.id IN (
    SELECT member_id
    FROM relation_members_del
    WHERE member_type = 'W'
    );
*/

--Commented according to suggestion at https://osmlatvija.github.io/zulip-archive/stream/360959-adreses/topic/Bots.20nodz.C4.93sa.20.22m.C4.81ju.22.html#396575119. As such cases are not common and mostly ways with only address tags are buildings missing building tags, it makes more sense not to delete them but forward to Zulip for manual review.
/*
DELETE
FROM ways
WHERE id IN (
    SELECT id
    FROM ways_del
    );

CREATE TEMPORARY TABLE way_nodes_del AS
SELECT *
FROM way_nodes
WHERE way_id IN (
    SELECT id
    FROM ways_del
    );

DELETE
FROM way_nodes
WHERE way_id IN (
    SELECT id
    FROM ways_del
    );
*/

--Add addresses for address points (nodes containing only addr:* tags) from the State Address Register. Only address codes not already assigned to isolated dwellings, ways and relations (buildings).
---Address code matches (address points added previously).
CREATE TEMPORARY TABLE nodes_addr_add_5 AS
SELECT a.id
  ,(hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:housename', v.nosaukums) || hstore('addr:street', v.iela) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:housename=>NULL, addr:street=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
  ,v.geom
FROM nodes a
INNER JOIN nodes_old o ON a.id = o.id
INNER JOIN vzd.adreses_ekas_sadalitas v ON o.tags -> 'ref:LV:addr' = v.adr_cd::TEXT
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
LEFT OUTER JOIN nodes_unnest t ON a.id = t.id
  AND t.tag NOT LIKE 'addr:%'
  AND t.tag NOT LIKE 'old_addr:%'
  AND t.tag NOT LIKE 'ref:LV:addr'
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM ways
  WHERE tags ? 'ref:LV:addr'
  ) w ON v.adr_cd::TEXT = w.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM relations
  WHERE tags ? 'ref:LV:addr'
  ) r ON v.adr_cd::TEXT = r.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM nodes
  WHERE tags ? 'ref:LV:addr'
  ) n ON v.adr_cd::TEXT = n.adr_cd
WHERE t.id IS NULL
  AND w.adr_cd IS NULL
  AND r.adr_cd IS NULL
  AND n.adr_cd IS NULL;

ALTER TABLE nodes_addr_add_5 ADD PRIMARY KEY (id);

UPDATE nodes_addr_add_5
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE nodes_addr_add_5
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE nodes_addr_add_5
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

----IDs of nodes that have become a part of ways or relations by manual user edits.
CREATE TEMPORARY TABLE nodes_altered AS
SELECT id
FROM nodes_addr_add_5
WHERE id IN (
    SELECT node_id
    FROM way_nodes
    );

--IDs of nodes containing duplicate address codes (in case address codes have been added manually, keep only the oldest node).
CREATE TEMPORARY TABLE nodes_dup AS
WITH c
AS (
  SELECT t2.val
    ,MIN(a.id) id_keep
  FROM nodes a
  INNER JOIN nodes_unnest t2 ON a.id = t2.id
  LEFT OUTER JOIN nodes_unnest t ON a.id = t.id
    AND t.tag NOT LIKE 'addr:%'
    AND t.tag NOT LIKE 'old_addr:%'
    AND t.tag NOT LIKE 'ref:LV:addr'
  WHERE t.id IS NULL
    AND t2.tag LIKE 'ref:LV:addr'
  GROUP BY t2.val
  HAVING COUNT(*) > 1
  )
SELECT a.id
FROM nodes a
INNER JOIN nodes_unnest t ON a.id = t.id
WHERE t.tag LIKE 'ref:LV:addr'
  AND t.val IN (
    SELECT val
    FROM c
    )
  AND a.id NOT IN (
    SELECT id_keep
    FROM c
    );

UPDATE nodes
SET tags = s.tags
  ,geom = s.geom
FROM nodes_addr_add_5 s
WHERE nodes.id = s.id
  AND nodes.id NOT IN (
    SELECT id
    FROM nodes_altered
    
    UNION
    
    SELECT id
    FROM nodes_dup
    );

---House names matches, distance up to 0.01 decimal degree (~1.1 km). Can be commented after pre-bot OSM address data has been entirely replaced for the whole territory.
----Since house names that look like numbers are treated as numbers and vice versa, direct usage of vzd.adreses_ekas_sadalitas takes too long to execute. Recreate as temporary table in previous structure.
CREATE TEMPORARY TABLE adreses_ekas_sadalitas_tmp AS
SELECT adr_cd
  ,nosaukums
  ,nr
  ,iela
  ,ciems
  ,pilseta
  ,pagasts
  ,novads
  ,atrib
  ,std
  ,geom
FROM vzd.adreses_ekas_sadalitas
WHERE (
    iela IS NULL
    AND nosaukums IS NOT NULL
    )
  OR (
    iela IS NOT NULL
    AND nr IS NOT NULL
    )

UNION

SELECT adr_cd
  ,nr nosaukums
  ,nosaukums nr
  ,iela
  ,ciems
  ,pilseta
  ,pagasts
  ,novads
  ,atrib
  ,std
  ,geom
FROM vzd.adreses_ekas_sadalitas
WHERE (
    iela IS NOT NULL
    AND nosaukums IS NOT NULL
    )
  OR (
    iela IS NULL
    AND nr IS NOT NULL
    );

CREATE INDEX adreses_ekas_sadalitas_tmp_geom_idx ON adreses_ekas_sadalitas_tmp USING GIST (geom);

CREATE TEMPORARY TABLE nodes_addr_add AS
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:housename', v.nosaukums) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:housename=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
  ,v.geom
FROM nodes a
INNER JOIN nodes_old o ON a.id = o.id
  AND o.tags ? 'addr:housename'
LEFT OUTER JOIN nodes_unnest t ON a.id = t.id
  AND t.tag NOT LIKE 'addr:%'
  AND t.tag NOT LIKE 'old_addr:%'
  AND t.tag NOT LIKE 'ref:LV:addr'
  AND t.tag NOT LIKE 'source:addr'
CROSS JOIN LATERAL(SELECT v.*, v.geom <-> a.geom AS dist FROM adreses_ekas_sadalitas_tmp v WHERE REPLACE(o.tags -> 'addr:housename'::TEXT, ' ', '') LIKE REPLACE(v.nosaukums, ' ', '') ORDER BY dist LIMIT 1) v
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM ways
  WHERE tags ? 'ref:LV:addr'
  ) w ON v.adr_cd::TEXT = w.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM relations
  WHERE tags ? 'ref:LV:addr'
  ) r ON v.adr_cd::TEXT = r.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM nodes
  WHERE tags ? 'ref:LV:addr'
  ) n ON v.adr_cd::TEXT = n.adr_cd
WHERE t.id IS NULL
  AND v.dist < 0.01
  AND w.adr_cd IS NULL
  AND r.adr_cd IS NULL
  AND n.adr_cd IS NULL;

ALTER TABLE nodes_addr_add ADD PRIMARY KEY (id);

UPDATE nodes_addr_add
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE nodes_addr_add
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE nodes_addr_add
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

UPDATE nodes
SET tags = s.tags
  ,geom = s.geom
FROM nodes_addr_add s
WHERE nodes.id = s.id
  AND nodes.id NOT IN (
    SELECT id
    FROM nodes_altered
    
    UNION
    
    SELECT id
    FROM nodes_dup
    );

---House number and street matches, distance up to 0.01 decimal degree (~1.1 km). Can be commented after pre-bot OSM address data has been entirely replaced for the whole territory.
CREATE TEMPORARY TABLE nodes_addr_add_2 AS
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
  ,v.geom
FROM nodes a
INNER JOIN nodes_old o ON a.id = o.id
  AND o.tags ?& ARRAY['addr:housenumber', 'addr:street']
LEFT OUTER JOIN nodes_unnest t ON a.id = t.id
  AND t.tag NOT LIKE 'addr:%'
  AND t.tag NOT LIKE 'old_addr:%'
  AND t.tag NOT LIKE 'ref:LV:addr'
  AND t.tag NOT LIKE 'source:addr'
CROSS JOIN LATERAL(SELECT v.*, v.geom <-> a.geom AS dist FROM vzd.adreses_ekas_sadalitas v WHERE REPLACE(o.tags -> 'addr:housenumber'::TEXT, ' ', '') LIKE REPLACE(v.nr, ' ', '')
    AND REPLACE(o.tags -> 'addr:street'::TEXT, ' ', '') LIKE REPLACE(v.iela, ' ', '') ORDER BY dist LIMIT 1) v
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON v.adr_cd = p.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM ways
  WHERE tags ? 'ref:LV:addr'
  ) w ON v.adr_cd::TEXT = w.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM relations
  WHERE tags ? 'ref:LV:addr'
  ) r ON v.adr_cd::TEXT = r.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM nodes
  WHERE tags ? 'ref:LV:addr'
  ) n ON v.adr_cd::TEXT = n.adr_cd
WHERE t.id IS NULL
  AND v.dist < 0.01
  AND w.adr_cd IS NULL
  AND r.adr_cd IS NULL
  AND n.adr_cd IS NULL;

ALTER TABLE nodes_addr_add_2 ADD PRIMARY KEY (id);

UPDATE nodes_addr_add_2
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE nodes_addr_add_2
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE nodes_addr_add_2
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

UPDATE nodes
SET tags = s.tags
  ,geom = s.geom
FROM nodes_addr_add_2 s
WHERE nodes.id = s.id
  AND nodes.id NOT IN (
    SELECT id
    FROM nodes_altered
    
    UNION
    
    SELECT id
    FROM nodes_dup
    );

--Delete nodes that are not part of ways or relations, have no tags, but previously had only address tags.
CREATE TEMPORARY TABLE nodes_del AS
SELECT a.id
FROM nodes a
INNER JOIN nodes_old b ON a.id = b.id
LEFT OUTER JOIN (
  SELECT DISTINCT member_id
  FROM relation_members
  WHERE member_type = 'N'
  ) c ON a.id = c.member_id
LEFT OUTER JOIN (
  SELECT DISTINCT node_id
  FROM way_nodes
  ) d ON a.id = d.node_id
WHERE a.tags = ''::hstore
  AND c.member_id IS NULL
  AND d.node_id IS NULL;

--Commented due to bug in smarter-sort.py. Should be fixed manually by inspecting ways_relations_del.
/*
--Delete nodes that were only part of previously deleted ways or relations and have no tags.
INSERT INTO nodes_del
SELECT a.id
FROM nodes a
LEFT OUTER JOIN (
  SELECT DISTINCT member_id
  FROM relation_members
  WHERE member_type = 'N'
  ) c ON a.id = c.member_id
LEFT OUTER JOIN (
  SELECT DISTINCT node_id
  FROM way_nodes
  ) d ON a.id = d.node_id
WHERE a.tags = ''::hstore
  AND c.member_id IS NULL
  AND d.node_id IS NULL
  AND (
    a.id IN (
      SELECT member_id
      FROM relation_members_del
      WHERE member_type = 'N'
      )
    OR a.id IN (
      SELECT node_id
      FROM way_nodes_del
      )
    );
*/

DELETE
FROM nodes
WHERE id IN (
    SELECT id
    FROM nodes_del
    );

--Delete tags of nodes that have become a part of ways or relations by manual user edits or contain duplicate manually added address codes.
UPDATE nodes
SET tags = ''
WHERE id IN (
    SELECT id
    FROM nodes_altered
    
    UNION
    
    SELECT id
    FROM nodes_dup
    );

--Insert missing addresses.
CREATE TEMPORARY TABLE nodes_addr_add_6 AS
SELECT - ROW_NUMBER() OVER() id
  ,(hstore('addr:country', 'LV') || hstore('addr:district', a.novads) || hstore('addr:city', COALESCE(a.pilseta, a.ciems)) || hstore('addr:subdistrict', a.pagasts) || hstore('addr:street', a.iela) || hstore('addr:housename', a.nosaukums) || hstore('addr:housenumber', a.nr) || hstore('addr:postcode', a.atrib) || hstore('ref:LV:addr', a.adr_cd::TEXT) || hstore('old_addr:housename', p.nosaukums) || hstore('old_addr:housenumber', p.nr) || hstore('old_addr:street', p.iela)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL, old_addr:housename=>NULL, old_addr:housenumber=>NULL, old_addr:street=>NULL'::hstore tags
  ,geom
FROM vzd.adreses_ekas_sadalitas a
LEFT OUTER JOIN vzd.adreses_his_ekas_previous p ON a.adr_cd = p.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM ways
  WHERE tags ? 'ref:LV:addr'
  ) w ON a.adr_cd::TEXT = w.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM relations
  WHERE tags ? 'ref:LV:addr'
  ) r ON a.adr_cd::TEXT = r.adr_cd
LEFT OUTER JOIN (
  SELECT tags -> 'ref:LV:addr' adr_cd
  FROM nodes
  WHERE tags ? 'ref:LV:addr'
  ) n ON a.adr_cd::TEXT = n.adr_cd
WHERE w.adr_cd IS NULL
  AND r.adr_cd IS NULL
  AND n.adr_cd IS NULL;

ALTER TABLE nodes_addr_add_6 ADD PRIMARY KEY (id);

UPDATE nodes_addr_add_6
SET tags = tags - 'old_addr:housename'::TEXT
WHERE tags -> 'addr:housename' = tags -> 'old_addr:housename';

UPDATE nodes_addr_add_6
SET tags = tags - 'old_addr:housenumber'::TEXT
WHERE tags -> 'addr:housenumber' = tags -> 'old_addr:housenumber';

UPDATE nodes_addr_add_6
SET tags = tags - 'old_addr:street'::TEXT
WHERE tags -> 'addr:street' = tags -> 'old_addr:street';

INSERT INTO nodes (
  id
  ,version
  ,user_id
  ,tstamp
  ,changeset_id
  ,tags
  ,geom
  )
SELECT id
  ,1
  ,15008076
  ,NOW()::TIMESTAMP
  ,- 1
  ,tags
  ,geom
FROM nodes_addr_add_6;

--Add addresses for other objects beside buildings and address points.
---Relations containing polygons of other objects beside buildings that can have an address.
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

---Ways.
CREATE TEMPORARY TABLE tags_4_addresses_ways AS
WITH t
AS (
  SELECT a.id
    ,UNNEST((%# a.tags) [1:999] [1]) tag
    ,UNNEST((%# a.tags) [1:999] [2:2]) val
  FROM ways a
  LEFT OUTER JOIN (
    SELECT id
    FROM ways
    WHERE tags ? 'ref:LV:addr'
    ) b ON a.id = b.id
  WHERE b.id IS NULL
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

----Polygon contains only one address point.
CREATE TEMPORARY TABLE ways_addr_add_3 AS
WITH c
AS (
  SELECT a.id
  FROM ways a
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_ways t ON a.id = t.id
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id;

ALTER TABLE ways_addr_add_3 ADD PRIMARY KEY (id);

UPDATE ways
SET tags = s.tags
FROM ways_addr_add_3 s
WHERE ways.id = s.id;

----More than half of the polygon is covered with a building polygon in OSM having an address. Polygon doesn't contain any address points.
-----Building polygon is a way.
CREATE TEMPORARY TABLE ways_addr_add_4 AS
WITH c
AS (
  SELECT a.id
  FROM ways a
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN way_geometry g2 ON ST_Intersects(g.geom, g2.geom)
  INNER JOIN ways a2 ON g2.way_id = a2.id
  LEFT OUTER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_ways t ON a.id = t.id
  WHERE a.id != a2.id
    AND a2.tags ? 'building'
    AND a2.tags ? 'ref:LV:addr'
    AND ST_Area(g.geom) > 0
    AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5
    AND v.adr_cd IS NULL
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', a2.tags -> 'addr:district') || hstore('addr:city', a2.tags -> 'addr:city') || hstore('addr:subdistrict', a2.tags -> 'addr:subdistrict') || hstore('addr:street', a2.tags -> 'addr:street') || hstore('addr:housename', a2.tags -> 'addr:housename') || hstore('addr:housenumber', a2.tags -> 'addr:housenumber') || hstore('addr:postcode', a2.tags -> 'addr:postcode') || hstore('ref:LV:addr', a2.tags -> 'ref:LV:addr')) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN way_geometry g2 ON ST_Intersects(g.geom, g2.geom)
INNER JOIN ways a2 ON g2.way_id = a2.id
INNER JOIN c ON a.id = c.id
WHERE a.id != a2.id
  AND a2.tags ? 'building'
  AND a2.tags ? 'ref:LV:addr'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5;

ALTER TABLE ways_addr_add_4 ADD PRIMARY KEY (id);

UPDATE ways
SET tags = s.tags
FROM ways_addr_add_4 s
WHERE ways.id = s.id;

-----Building polygon is a relation.
CREATE TEMPORARY TABLE ways_addr_add_5 AS
WITH c
AS (
  SELECT a.id
  FROM ways a
  INNER JOIN way_geometry g ON a.id = g.way_id
  INNER JOIN relations_geometry g2 ON ST_Intersects(g.geom, g2.geom)
  INNER JOIN relations a2 ON g2.id = a2.id
  LEFT OUTER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_ways t ON a.id = t.id
  WHERE a2.tags ? 'building'
    AND a2.tags ? 'ref:LV:addr'
    AND ST_Area(g.geom) > 0
    AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5
    AND v.adr_cd IS NULL
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', a2.tags -> 'addr:district') || hstore('addr:city', a2.tags -> 'addr:city') || hstore('addr:subdistrict', a2.tags -> 'addr:subdistrict') || hstore('addr:street', a2.tags -> 'addr:street') || hstore('addr:housename', a2.tags -> 'addr:housename') || hstore('addr:housenumber', a2.tags -> 'addr:housenumber') || hstore('addr:postcode', a2.tags -> 'addr:postcode') || hstore('ref:LV:addr', a2.tags -> 'ref:LV:addr')) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM ways a
INNER JOIN way_geometry g ON a.id = g.way_id
INNER JOIN relations_geometry g2 ON ST_Intersects(g.geom, g2.geom)
INNER JOIN relations a2 ON g2.id = a2.id
INNER JOIN c ON a.id = c.id
WHERE a.id != a2.id
  AND a2.tags ? 'building'
  AND a2.tags ? 'ref:LV:addr'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5;

ALTER TABLE ways_addr_add_5 ADD PRIMARY KEY (id);

UPDATE ways
SET tags = s.tags
FROM ways_addr_add_5 s
WHERE ways.id = s.id;

---Relations containing ways.
----Polygon contains only one address point.
CREATE TEMPORARY TABLE relations_addr_add_3 AS
WITH c
AS (
  SELECT a.id
  FROM relations a
  INNER JOIN relations_geometry_2 g ON a.id = g.id
  INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_relations t ON a.id = t.id
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry_2 g ON a.id = g.id
INNER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
INNER JOIN c ON a.id = c.id;

ALTER TABLE relations_addr_add_3 ADD PRIMARY KEY (id);

UPDATE relations
SET tags = s.tags
FROM relations_addr_add_3 s
WHERE relations.id = s.id;

----More than half of the polygon is covered with a building polygon in OSM having an address. Polygon doesn't contain any address points.
-----Building polygon is a way.
CREATE TEMPORARY TABLE relations_addr_add_4 AS
WITH c
AS (
  SELECT a.id
  FROM relations a
  INNER JOIN relations_geometry g ON a.id = g.id
  INNER JOIN way_geometry g2 ON ST_Intersects(g.geom, g2.geom)
  INNER JOIN ways a2 ON g2.way_id = a2.id
  LEFT OUTER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_relations t ON a.id = t.id
  WHERE a2.tags ? 'building'
    AND a2.tags ? 'ref:LV:addr'
    AND ST_Area(g.geom) > 0
    AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5
    AND v.adr_cd IS NULL
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', a2.tags -> 'addr:district') || hstore('addr:city', a2.tags -> 'addr:city') || hstore('addr:subdistrict', a2.tags -> 'addr:subdistrict') || hstore('addr:street', a2.tags -> 'addr:street') || hstore('addr:housename', a2.tags -> 'addr:housename') || hstore('addr:housenumber', a2.tags -> 'addr:housenumber') || hstore('addr:postcode', a2.tags -> 'addr:postcode') || hstore('ref:LV:addr', a2.tags -> 'ref:LV:addr')) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN way_geometry g2 ON ST_Intersects(g.geom, g2.geom)
INNER JOIN ways a2 ON g2.way_id = a2.id
INNER JOIN c ON a.id = c.id
WHERE a.id != a2.id
  AND a2.tags ? 'building'
  AND a2.tags ? 'ref:LV:addr'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5;

ALTER TABLE relations_addr_add_4 ADD PRIMARY KEY (id);

UPDATE relations
SET tags = s.tags
FROM relations_addr_add_4 s
WHERE relations.id = s.id;

-----Building polygon is a relation.
CREATE TEMPORARY TABLE relations_addr_add_5 AS
WITH c
AS (
  SELECT a.id
  FROM relations a
  INNER JOIN relations_geometry g ON a.id = g.id
  INNER JOIN relations_geometry g2 ON ST_Intersects(g.geom, g2.geom)
  INNER JOIN relations a2 ON g2.id = a2.id
  LEFT OUTER JOIN vzd.adreses_ekas_sadalitas v ON ST_Within(v.geom, g.geom)
  INNER JOIN tags_4_addresses_relations t ON a.id = t.id
  WHERE a.id != a2.id
    AND a2.tags ? 'building'
    AND a2.tags ? 'ref:LV:addr'
    AND ST_Area(g.geom) > 0
    AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5
    AND v.adr_cd IS NULL
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', a2.tags -> 'addr:district') || hstore('addr:city', a2.tags -> 'addr:city') || hstore('addr:subdistrict', a2.tags -> 'addr:subdistrict') || hstore('addr:street', a2.tags -> 'addr:street') || hstore('addr:housename', a2.tags -> 'addr:housename') || hstore('addr:housenumber', a2.tags -> 'addr:housenumber') || hstore('addr:postcode', a2.tags -> 'addr:postcode') || hstore('ref:LV:addr', a2.tags -> 'ref:LV:addr')) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN relations_geometry g2 ON ST_Intersects(g.geom, g2.geom)
INNER JOIN relations a2 ON g2.id = a2.id
INNER JOIN c ON a.id = c.id
WHERE a.id != a2.id
  AND a2.tags ? 'building'
  AND a2.tags ? 'ref:LV:addr'
  AND ST_Area(g.geom) > 0
  AND ST_Area(ST_Intersection(g.geom, g2.geom)) / ST_Area(g.geom) > 0.5;

ALTER TABLE relations_addr_add_5 ADD PRIMARY KEY (id);

UPDATE relations
SET tags = s.tags
FROM relations_addr_add_5 s
WHERE relations.id = s.id;

---Nodes.
----Address taken from the OSM building polygon (way or relation) where node is located. Node contained by only one polygon.
CREATE TEMPORARY TABLE tags_4_addresses_nodes AS
WITH t
AS (
  SELECT a.*
  FROM nodes_unnest a
  LEFT OUTER JOIN (
    SELECT id
    FROM nodes
    WHERE tags ? 'ref:LV:addr'
    ) b ON a.id = b.id
  WHERE b.id IS NULL
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
INNER JOIN lv_border b ON ST_Intersects(g.geom, b.geom)
WHERE a.tags ?& ARRAY ['building', 'ref:LV:addr']

UNION

SELECT a.id
  ,a.tags
  ,g.geom
FROM relations a
INNER JOIN relations_geometry g ON a.id = g.id
INNER JOIN lv_border b ON ST_Intersects(g.geom, b.geom)
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
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.tags -> 'addr:district') || hstore('addr:city', v.tags -> 'addr:city') || hstore('addr:subdistrict', v.tags -> 'addr:subdistrict') || hstore('addr:street', v.tags -> 'addr:street') || hstore('addr:housename', v.tags -> 'addr:housename') || hstore('addr:housenumber', v.tags -> 'addr:housenumber') || hstore('addr:postcode', v.tags -> 'addr:postcode') || hstore('ref:LV:addr', v.tags -> 'ref:LV:addr')) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM nodes a
INNER JOIN building_addr_geom v ON ST_Contains(v.geom, a.geom)
INNER JOIN c ON a.id = c.id;

ALTER TABLE nodes_addr_add_3 ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
FROM nodes_addr_add_3 s
WHERE nodes.id = s.id;

----Address taken from the address of the building from the State Immovable Property Cadastre Information System where node is located. Node contained by only one polygon.
CREATE TEMPORARY TABLE nivkis_buves_addr_geom AS
SELECT c.adr_cd
  ,c.nr
  ,c.nosaukums
  ,c.iela
  ,c.ciems
  ,c.pagasts
  ,c.pilseta
  ,c.novads
  ,c.atrib
  ,a.geom
FROM vzd.nivkis_buves a
INNER JOIN vzd.nivkis_adreses b ON a.code = b."ObjectCadastreNr"
INNER JOIN vzd.adreses_ekas_sadalitas c ON b."ARCode" = c.adr_cd;

CREATE INDEX nivkis_buves_addr_geom_geom_idx ON nivkis_buves_addr_geom USING GIST (geom);

CREATE TEMPORARY TABLE nodes_addr_add_7 AS
WITH c
AS (
  SELECT a.id
  FROM nodes a
  INNER JOIN nivkis_buves_addr_geom v ON ST_Contains(v.geom, a.geom)
  INNER JOIN tags_4_addresses_nodes t ON a.id = t.id
  GROUP BY a.id
  HAVING COUNT(*) = 1
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM nodes a
INNER JOIN nivkis_buves_addr_geom v ON ST_Contains(v.geom, a.geom)
INNER JOIN c ON a.id = c.id;

ALTER TABLE nodes_addr_add_7 ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
FROM nodes_addr_add_7 s
WHERE nodes.id = s.id;

----Address taken from the address of the land parcel from the State Immovable Property Cadastre Information System where node is located.
CREATE TEMPORARY TABLE tags_4_addresses_nodes_2 AS
WITH t
AS (
  SELECT a.*
  FROM nodes_unnest a
  LEFT OUTER JOIN (
    SELECT id
    FROM nodes
    WHERE tags ? 'ref:LV:addr'
    ) b ON a.id = b.id
  WHERE b.id IS NULL
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
    ,c.atrib
    ,a.geom
  FROM vzd.nivkis_zemes_vienibas a
  INNER JOIN vzd.nivkis_adreses b ON a.code = b."ObjectCadastreNr"
  INNER JOIN vzd.adreses_ekas_sadalitas c ON b."ARCode" = c.adr_cd
  )
SELECT a.id
  ,(a.tags || hstore('addr:country', 'LV') || hstore('addr:district', v.novads) || hstore('addr:city', COALESCE(v.pilseta, v.ciems)) || hstore('addr:subdistrict', v.pagasts) || hstore('addr:street', v.iela) || hstore('addr:housename', v.nosaukums) || hstore('addr:housenumber', v.nr) || hstore('addr:postcode', v.atrib) || hstore('ref:LV:addr', v.adr_cd::TEXT)) - 'addr:district=>NULL, addr:city=>NULL, addr:subdistrict=>NULL, addr:street=>NULL, addr:housename=>NULL, addr:housenumber=>NULL, addr:postcode=>NULL'::hstore tags
FROM nodes a
INNER JOIN tags_4_addresses_nodes_2 t ON a.id = t.id
INNER JOIN v ON ST_Contains(v.geom, a.geom);

ALTER TABLE nodes_addr_add_4 ADD PRIMARY KEY (id);

UPDATE nodes
SET tags = s.tags
FROM nodes_addr_add_4 s
WHERE nodes.id = s.id;

--Remove building name if it matches housenumber.
---Nodes.
UPDATE nodes AS u
SET tags = tags - 'name'::TEXT
FROM nodes_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') = LOWER(tags -> 'addr:housenumber')
  AND tags ? 'building';

---Ways.
UPDATE ways AS u
SET tags = tags - 'name'::TEXT
FROM ways_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') = LOWER(tags -> 'addr:housenumber')
  AND tags ? 'building';

---Relations.
UPDATE relations AS u
SET tags = tags - 'name'::TEXT
FROM relations_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') = LOWER(tags -> 'addr:housenumber')
  AND tags ? 'building';

--Remove building name if it matches street + housenumber.
---Nodes.
UPDATE nodes AS u
SET tags = tags - 'name'::TEXT
FROM nodes_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') LIKE LOWER(tags -> 'addr:street' || ' ' || (tags -> 'addr:housenumber')::TEXT)
  AND tags ? 'building';

UPDATE nodes AS u
SET tags = tags - 'name'::TEXT
FROM nodes_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') LIKE REPLACE(LOWER(tags -> 'addr:street' || ' ' || (tags -> 'addr:housenumber')::TEXT), 'iela', 'street')
  AND tags ? 'building';

---Ways.
UPDATE ways AS u
SET tags = tags - 'name'::TEXT
FROM ways_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') LIKE LOWER(tags -> 'addr:street' || ' ' || (tags -> 'addr:housenumber')::TEXT)
  AND tags ? 'building';

UPDATE ways AS u
SET tags = tags - 'name'::TEXT
FROM ways_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') LIKE REPLACE(LOWER(tags -> 'addr:street' || ' ' || (tags -> 'addr:housenumber')::TEXT), 'iela', 'street')
  AND tags ? 'building';

---Relations.
UPDATE relations AS u
SET tags = tags - 'name'::TEXT
FROM relations_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') LIKE LOWER(tags -> 'addr:street' || ' ' || (tags -> 'addr:housenumber')::TEXT)
  AND tags ? 'building';

UPDATE relations AS u
SET tags = tags - 'name'::TEXT
FROM relations_lv AS b
WHERE u.id = b.id
  AND LOWER(tags -> 'name') LIKE REPLACE(LOWER(tags -> 'addr:street' || ' ' || (tags -> 'addr:housenumber')::TEXT), 'iela', 'street')
  AND tags ? 'building';

END;
$BODY$;

ALTER PROCEDURE public.addresses()
    OWNER TO osm;

GRANT EXECUTE ON PROCEDURE public.addresses() TO osm;

REVOKE ALL ON PROCEDURE public.addresses() FROM PUBLIC;
