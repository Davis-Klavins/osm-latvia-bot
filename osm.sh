#!/bin/bash

# Stops the execution of the script in case of an error.
set -e

# Directory where data are stored locally.
export DIRECTORY=
# Password of PostgreSQL user osm.
export PGPASSWORD=
# PostgreSQL IP address.
export IP_ADDRESS=
# PostgreSQL port.
export PORT=
export PGCLIENTENCODING=UTF8

# OsmChange file name without extension.
input=latvia-diff
# OSM user name and password.
ident="-u latvia-bot -p "
# Zulip bot e-mail address and API key.
zulip="latvia-bot@osmlatvija.zulipchat.com:"
# Zulip message text.
text="content="
# Path to ways_relations_del.csv.
file_path="ways_relations_del.csv"

cd $DIRECTORY/osm-latvia-bot

# Update local repository.
#git pull origin main

# Import data of tags that allow object to have address tags.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE tags_4_addresses;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c '\COPY tags_4_addresses FROM tags_4_addresses.csv CSV HEADER'

cd ..

# Remove leftovers from incomplete previous executions of the script if exist.
rm -f *.pbf
rm -f *.opl
rm -f *.o5m
rm -f *.osc
rm -f *.comment
rm -f *.diff.xml
rm -f ways_relations_del.csv

# Download Geofabrik authentication cookie.
./oauth_cookie_client.py -o cookie.txt -s settings.json

# Download and process latest internal OSM history data.
wget -q -O latvia-internal.osh.pbf -N --no-cookies --header "Cookie: $(cat cookie.txt | cut -d ';' -f 1)" https://osm-internal.download.geofabrik.de/europe/latvia-internal.osh.pbf
# Convert to the OPL file format (https://osmcode.org/opl-file-format/).
osmium cat latvia-internal.osh.pbf -o latvia-internal.osm.opl
rm latvia-internal.osh.pbf

# Preprocess data.
# Nodes.
grep ^n latvia-internal.osm.opl | sed 's/^.//' | sed 's/ ./ /g' | sed 's/\\/\\\\/g' > latvia-internal-n.osm.opl
# Ways.
grep ^w latvia-internal.osm.opl | sed 's/^.//' | sed 's/ ./ /g' | sed 's/\\/\\\\/g' > latvia-internal-w.osm.opl
# Relations.
grep ^r latvia-internal.osm.opl | sed 's/^.//' | sed 's/ ./ /g' | sed 's/\\/\\\\/g' > latvia-internal-r.osm.opl
rm latvia-internal.osm.opl

# Update data in the local PostgreSQL database.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY history.nodes_import (id, version, deleted, changeset_id, tstamp, user_id, user_name, tags, longitude, latitude) FROM latvia-internal-n.osm.opl WITH (DELIMITER ' ')"
rm latvia-internal-n.osm.opl
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY history.ways_import (id, version, deleted, changeset_id, tstamp, user_id, user_name, tags, way_nodes) FROM latvia-internal-w.osm.opl WITH (DELIMITER ' ')"
rm latvia-internal-w.osm.opl
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY history.relations_import (id, version, deleted, changeset_id, tstamp, user_id, user_name, tags, relation_members) FROM latvia-internal-r.osm.opl WITH (DELIMITER ' ')"
rm latvia-internal-r.osm.opl
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL history.history()"

# Download latest internal OSM data.
# Workaround from https://pavie.info/2020/08/12/complete-full-history-osm/ because command "wget -O latvia-latest-internal.osm.pbf --load-cookies cookie.txt --max-redirect 0 https://osm-internal.download.geofabrik.de/europe/latvia-latest-internal.osm.pbf" returns "ERROR 403: Forbidden".
wget -q -O latvia-latest-internal.osm.pbf -N --no-cookies --header "Cookie: $(cat cookie.txt | cut -d ';' -f 1)" https://osm-internal.download.geofabrik.de/europe/latvia-latest-internal.osm.pbf

# Apply changes made after Geofabrik extract has been created.
osmupdate latvia-latest-internal.osm.pbf latvia-latest-internal-updated.o5m --base-url=http://download.openstreetmap.fr/replication/europe/minute/
osmconvert latvia-latest-internal-updated.o5m -B=latvia.poly --complete-ways --complete-multipolygons --complete-boundaries -o=latvia-latest-internal.osm.pbf
rm latvia-latest-internal-updated.o5m

# Execute PostgreSQL procedure that recreates tables and functions needed to maintain OSM data.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL pgsnapshot_schema()"

# Update data in the local PostgreSQL database.
osmosis --read-pbf latvia-latest-internal.osm.pbf --write-pgsql host=$IP_ADDRESS:$PORT database="osm" user="osm" password=$PGPASSWORD
#osmosis --read-pbf latvia-latest-internal.osm.pbf --write-pgsql-change host=$IP_ADDRESS:$PORT database="osm" user="osm" password=$PGPASSWORD

# Execute PostgreSQL procedure that creates geometry columns of ways.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL way_geometry()"

# Execute PostgreSQL procedure that creates tables with IDs and summary of tags that are located in Latvia.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL in_latvia()"

# Execute PostgreSQL data processing procedure of addresses.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL addresses()"

# Execute PostgreSQL data processing procedure of tags.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL tags()"

# Export table ways_relations_del.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY (SELECT link FROM ways_relations_del) to 'ways_relations_del.csv' WITH (FORMAT CSV)"

# Get OsmChange file. Large amount of changes lead to an error.
osmosis --read-pgsql host=$IP_ADDRESS:$PORT database="osm" user="osm" password=$PGPASSWORD --dataset-dump --sort type="TypeThenId" --read-pbf latvia-latest-internal.osm.pbf --sort type="TypeThenId" --derive-change --write-xml-change file="latvia-diff.osc"
rm latvia-latest-internal.osm.pbf

# Process OsmChange file and upload changes. Based on https://wiki.openstreetmap.org/wiki/Upload.py#Multi-part_uploads.
# Reorder OsmChange file. Commented due to bug in smarter-sort.py.
#./osm-latvia-bot/upload.py/smarter-sort.py "$input.osc"
#mv $input-sorted.osc $input.osc

# Create comment file.
echo "Updated addresses and tags in Latvia." > latvia-diff.comment

# Split OsmChange file in pieces no larger than 10 000 elements (changeset limit).
./osm-latvia-bot/upload.py/split.py "$input.osc" 10000

# Delete bounds element from the 1st OsmChange file. Comment if smarter-sort.py will be fixed and lines 19-20 uncommented.
xmlstarlet ed -d '//osmChange/modify/bounds' latvia-diff-part1.osc > latvia-diff-part1-edited.osc
mv latvia-diff-part1-edited.osc latvia-diff-part1.osc

# Number of parts as count of *-part*.osc files (https://askubuntu.com/a/454568).
parts=`find -maxdepth 1 -type f -name "*-part*.osc" -printf x | wc -c`

# Upload changes. Separate changeset for every 10 000 elements.
. ./.osm/bin/activate
for num in `seq 1 $parts`; do
        ./osm-latvia-bot/upload.py/upload.py $ident -c yes -t -y "Valsts adrešu reģistra informācijas sistēmas atvērtie dati" "$input-part$num.osc"

        for rnum in `seq $num $parts`; do
                ./osm-latvia-bot/upload.py/diffpatch.py "$input-part$num.diff.xml" "$input-part$rnum.osc"
                mv "$input-part$rnum.osc.diffed" "$input-part$rnum.osc"
        done
done
deactivate

# Concatenate Zulip message text and ways_relations_del.csv contents into a variable.
message="${text} $(cat ${file_path})"

# Post message to OSM Latvija Zulip chat on ways and relations with missing tags that previously had only address tags for manual review.
if ! [ -s $file_path ];then
    echo -e "No deleted ways and relations."
    exit
fi

curl -X POST https://osmlatvija.zulipchat.com/api/v1/messages \
    -u $zulip \
    --data-urlencode type=stream \
    --data-urlencode 'to="adreses"' \
    --data-urlencode topic="Ways and relations with missing tags for review" \
`    --data-urlencode topic="Deleted ways and relations by latvia-bot for review" `\
    --data-urlencode "${message}"

# Delete OsmChange (splitted parts) and comment files and ways_relations_del.csv.
rm *part*.osc
rm *.comment
rm *.diff.xml
rm ways_relations_del.csv
