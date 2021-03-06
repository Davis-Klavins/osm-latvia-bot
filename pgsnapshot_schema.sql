CREATE OR REPLACE PROCEDURE pgsnapshot_schema(
	)
LANGUAGE 'plpgsql'
AS $BODY$
BEGIN

-- Downloaded from https://github.com/openstreetmap/osmosis/blob/main/package/script/pgsnapshot_schema_0.6.sql.

-- Database creation script for the snapshot PostgreSQL schema.

-- Drop all tables if they exist.
DROP TABLE IF EXISTS actions;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS nodes;
DROP TABLE IF EXISTS ways;
DROP TABLE IF EXISTS way_nodes;
DROP TABLE IF EXISTS relations;
DROP TABLE IF EXISTS relation_members;
DROP TABLE IF EXISTS schema_info;

-- Drop all stored procedures if they exist.
DROP FUNCTION IF EXISTS osmosisUpdate();

-- Create a table which will contain a single row defining the current schema version.
CREATE TABLE schema_info (
    version integer NOT NULL
);

-- Create a table for users.
CREATE TABLE users (
    id int NOT NULL,
    name text NOT NULL
);

-- Create a table for nodes.
CREATE TABLE nodes (
    id bigint NOT NULL,
    version int NOT NULL,
    user_id int NOT NULL,
    tstamp timestamp without time zone NOT NULL,
    changeset_id bigint NOT NULL,
    tags hstore,
    geom geometry(Point,4326)
);

-- Create a table for ways.
CREATE TABLE ways (
    id bigint NOT NULL,
    version int NOT NULL,
    user_id int NOT NULL,
    tstamp timestamp without time zone NOT NULL,
    changeset_id bigint NOT NULL,
    tags hstore,
    nodes bigint[]
);

-- Create a table for representing way to node relationships.
CREATE TABLE way_nodes (
    way_id bigint NOT NULL,
    node_id bigint NOT NULL,
    sequence_id int NOT NULL
);

-- Create a table for relations.
CREATE TABLE relations (
    id bigint NOT NULL,
    version int NOT NULL,
    user_id int NOT NULL,
    tstamp timestamp without time zone NOT NULL,
    changeset_id bigint NOT NULL,
    tags hstore
);

-- Create a table for representing relation member relationships.
CREATE TABLE relation_members (
    relation_id bigint NOT NULL,
    member_id bigint NOT NULL,
    member_type character(1) NOT NULL,
    member_role text NOT NULL,
    sequence_id int NOT NULL
);

-- Configure the schema version.
INSERT INTO schema_info (version) VALUES (6);

-- Add primary keys to tables.
ALTER TABLE ONLY schema_info ADD CONSTRAINT pk_schema_info PRIMARY KEY (version);

ALTER TABLE ONLY users ADD CONSTRAINT pk_users PRIMARY KEY (id);

ALTER TABLE ONLY nodes ADD CONSTRAINT pk_nodes PRIMARY KEY (id);

ALTER TABLE ONLY ways ADD CONSTRAINT pk_ways PRIMARY KEY (id);

ALTER TABLE ONLY way_nodes ADD CONSTRAINT pk_way_nodes PRIMARY KEY (way_id, sequence_id);

ALTER TABLE ONLY relations ADD CONSTRAINT pk_relations PRIMARY KEY (id);

ALTER TABLE ONLY relation_members ADD CONSTRAINT pk_relation_members PRIMARY KEY (relation_id, sequence_id);

-- Add indexes to tables.
CREATE INDEX idx_nodes_geom ON nodes USING gist (geom);

CREATE INDEX idx_way_nodes_node_id ON way_nodes USING btree (node_id);

CREATE INDEX idx_relation_members_member_id_and_type ON relation_members USING btree (member_id, member_type);

-- Set to cluster nodes by geographical location.
ALTER TABLE ONLY nodes CLUSTER ON idx_nodes_geom;

-- Set to cluster the tables showing relationship by parent ID and sequence
ALTER TABLE ONLY way_nodes CLUSTER ON pk_way_nodes;
ALTER TABLE ONLY relation_members CLUSTER ON pk_relation_members;

-- There are no sensible CLUSTER orders for users or relations.
-- Depending on geometry columns different clustings of ways may be desired.

-- Create the function that provides "unnest" functionality while remaining compatible with 8.3.
CREATE OR REPLACE FUNCTION unnest_bbox_way_nodes() RETURNS void AS $$
DECLARE
	previousId ways.id%TYPE;
	currentId ways.id%TYPE;
	result bigint[];
	wayNodeRow way_nodes%ROWTYPE;
	wayNodes ways.nodes%TYPE;
BEGIN
	FOR wayNodes IN SELECT bw.nodes FROM bbox_ways bw LOOP
		FOR i IN 1 .. array_upper(wayNodes, 1) LOOP
			INSERT INTO bbox_way_nodes (id) VALUES (wayNodes[i]);
		END LOOP;
	END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create customisable hook function that is called within the replication update transaction.
CREATE FUNCTION osmosisUpdate() RETURNS void AS $$
DECLARE
BEGIN
END;
$$ LANGUAGE plpgsql;

-- Manually set statistics for the way_nodes and relation_members table
-- Postgres gets horrible counts of distinct values by sampling random pages
-- and can be off by an 1-2 orders of magnitude

-- Size of the ways table / size of the way_nodes table
ALTER TABLE way_nodes ALTER COLUMN way_id SET (n_distinct = -0.08);

-- Size of the nodes table / size of the way_nodes table * 0.998
-- 0.998 is a factor for nodes not in ways
ALTER TABLE way_nodes ALTER COLUMN node_id SET (n_distinct = -0.83);

-- API allows a maximum of 2000 nodes/way. Unlikely to impact query plans.
ALTER TABLE way_nodes ALTER COLUMN sequence_id SET (n_distinct = 2000);

-- Size of the relations table / size of the relation_members table
ALTER TABLE relation_members ALTER COLUMN relation_id SET (n_distinct = -0.09);

-- Based on June 2013 data
ALTER TABLE relation_members ALTER COLUMN member_id SET (n_distinct = -0.62);

-- Based on June 2013 data. Unlikely to impact query plans.
ALTER TABLE relation_members ALTER COLUMN member_role SET (n_distinct = 6500);

-- Based on June 2013 data. Unlikely to impact query plans.
ALTER TABLE relation_members ALTER COLUMN sequence_id SET (n_distinct = 10000);

END;
$BODY$;

GRANT EXECUTE ON PROCEDURE pgsnapshot_schema() TO osm;

REVOKE ALL ON PROCEDURE pgsnapshot_schema() FROM PUBLIC;
