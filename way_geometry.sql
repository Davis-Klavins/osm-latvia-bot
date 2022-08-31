CREATE OR REPLACE PROCEDURE way_geometry(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

--Downloaded from https://github.com/openstreetmap/osmosis/blob/master/package/script/contrib/CreateGeometryForWays.sql, replaced Collect with ST_Collect, increased ST_NumPoints to 4 and excluded ways that have been clipped (don't have all nodes) during osmupdate with *.poly file.

-------------------------------------------------------------------------------
-- The following script creates a new table for the pgsql simple schema for storing full way geometries.
-- Author: Ralf
-------------------------------------------------------------------------------

-- Drop table if it exists.
DROP TABLE IF EXISTS way_geometry;

-- Create table.
CREATE TABLE way_geometry (
  way_id BIGINT NOT NULL
  ,geom geometry(Geometry, 4326)
  );

-------------------------------------------------------------------------------
-- The following might go into the POST_LOAD_SQL-array in the class "PostgreSqlWriter"?
-------------------------------------------------------------------------------

-- Add a linestring for every way (create a polyline).
INSERT INTO way_geometry
SELECT id
  ,(
    SELECT ST_LineFromMultiPoint(ST_Collect(nodes.geom))
    FROM nodes
    LEFT JOIN way_nodes ON nodes.id = way_nodes.node_id
    WHERE way_nodes.way_id = ways.id
    )
FROM ways;

-- After creating a line for every way (polyline), we want closed ways to be stored as polygones. 
-- So we need to delete the previously created polylines for these ways first.
DELETE
FROM way_geometry
WHERE way_id IN (
    SELECT ways.id
    FROM ways
    WHERE ST_IsClosed((
          SELECT ST_LineFromMultiPoint(ST_Collect(n.geom))
          FROM nodes n
          LEFT JOIN way_nodes wn ON n.id = wn.node_id
          WHERE ways.id = wn.way_id
          ))
      AND ST_NumPoints((
          SELECT ST_LineFromMultiPoint(ST_Collect(n.geom))
          FROM nodes n
          LEFT JOIN way_nodes wn ON n.id = wn.node_id
          WHERE ways.id = wn.way_id
          )) >= 4
    );

-- Now we need to add the polyline geometry for every closed way.
INSERT INTO way_geometry
SELECT ways.id
  ,(
    SELECT ST_MakePolygon(ST_LineFromMultiPoint(ST_Collect(nodes.geom)))
    FROM nodes
    LEFT JOIN way_nodes ON nodes.id = way_nodes.node_id
    WHERE way_nodes.way_id = ways.id
    )
FROM ways
LEFT JOIN (
  SELECT way_id
  FROM way_nodes a
  LEFT JOIN nodes b ON a.node_id = b.id
  GROUP BY way_id
  HAVING COUNT(*) != COUNT(CASE 
        WHEN b.id IS NOT NULL
          THEN 1
        ELSE NULL
        END)
  ) b ON ways.id = b.way_id
WHERE ST_IsClosed((
      SELECT ST_LineFromMultiPoint(ST_Collect(n.geom))
      FROM nodes n
      LEFT JOIN way_nodes wn ON n.id = wn.node_id
      WHERE ways.id = wn.way_id
      ))
  AND ST_NumPoints((
      SELECT ST_LineFromMultiPoint(ST_Collect(n.geom))
      FROM nodes n
      LEFT JOIN way_nodes wn ON n.id = wn.node_id
      WHERE ways.id = wn.way_id
      )) >= 4
  AND b.way_id IS NULL; -- Exclude ways that have been clipped (don't have all nodes) during osmupdate with *.poly file.

--Make geometries valid.
UPDATE way_geometry
SET geom = ST_MakeValid(geom)
WHERE ST_IsValid(geom) = FALSE;

-------------------------------------------------------------------------------

-- Create index on way_geometry.
CREATE INDEX idx_way_geometry_way_id ON way_geometry USING btree (way_id);

CREATE INDEX idx_way_geometry_geom ON way_geometry USING gist (geom);

END;
$BODY$;

REVOKE ALL ON PROCEDURE way_geometry() FROM PUBLIC;
