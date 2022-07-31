#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=
# Password of PostgreSQL user osm.
export PGPASSWORD=
# PostgreSQL IP address.
export IP_ADDRESS=
# PostgreSQL port.
export PORT=
export PGCLIENTENCODING=UTF8

cd $DIRECTORY

rm latvia-internal.osh.pbf
# Nodes.
grep ^n latvia-internal.osm.opl | sed 's/^.//' | sed 's/ ./ /g' | sed 's/\\/\\\\/g' > latvia-internal-n.osm.opl
# Ways.
grep ^w latvia-internal.osm.opl | sed 's/^.//' | sed 's/ ./ /g' | sed 's/\\/\\\\/g' > latvia-internal-w.osm.opl
# Relations.
grep ^r latvia-internal.osm.opl | sed 's/^.//' | sed 's/ ./ /g' | sed 's/\\/\\\\/g' > latvia-internal-r.osm.opl
rm latvia-internal.osm.opl

psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY history.nodes_import (id, version, deleted, changeset_id, tstamp, user_id, user_name, tags, longitude, latitude) FROM latvia-internal-n.osm.opl WITH (DELIMITER ' ')"
rm latvia-internal-n.osm.opl
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY history.ways_import (id, version, deleted, changeset_id, tstamp, user_id, user_name, tags, way_nodes) FROM latvia-internal-w.osm.opl WITH (DELIMITER ' ')"
rm latvia-internal-w.osm.opl
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY history.relations_import (id, version, deleted, changeset_id, tstamp, user_id, user_name, tags, relation_members) FROM latvia-internal-r.osm.opl WITH (DELIMITER ' ')"
rm latvia-internal-r.osm.opl
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL history.history()"
