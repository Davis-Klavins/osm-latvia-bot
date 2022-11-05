#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=
# Password of PostgreSQL user osm.
export PGPASSWORD=
# PostgreSQL IP address.
export IP_ADDRESS=
# PostgreSQL port.
export PORT=

cd $DIRECTORY/osm-latvia-bot

# Update local repository.
# git pull origin main

# Import data of tags that allow object to have address tags.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE tags_4_addresses;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c '\COPY tags_4_addresses FROM tags_4_addresses.csv CSV HEADER'

cd ..

# Download latest internal OSM data.
py oauth_cookie_client.py -o cookie.txt -s settings.json
# Workaround from https://pavie.info/2020/08/12/complete-full-history-osm/ because command "wget -O latvia-latest-internal.osm.pbf --load-cookies cookie.txt --max-redirect 0 https://osm-internal.download.geofabrik.de/europe/latvia-latest-internal.osm.pbf" returns "ERROR 403: Forbidden".
wget -q -O latvia-latest-internal.osm.pbf -N --no-cookies --header "Cookie: $(cat cookie.txt | cut -d ';' -f 1)" https://osm-internal.download.geofabrik.de/europe/latvia-latest-internal.osm.pbf

# Apply changes made after Geofabrik extract has been created.
osmupdate latvia-latest-internal.osm.pbf latvia-latest-internal-updated.osm.pbf --base-url=http://download.openstreetmap.fr/replication/europe/minute/ -B=latvia.poly
mv latvia-latest-internal-updated.osm.pbf latvia-latest-internal.osm.pbf
