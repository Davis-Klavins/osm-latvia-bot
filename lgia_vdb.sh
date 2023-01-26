#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=
# Password of PostgreSQL user osm.
export PGPASSWORD=
# PostgreSQL IP address.
export IP_ADDRESS=
# PostgreSQL port.
export PORT=

cd $DIRECTORY

# Download the Place Names Database of the Latvian Geospatial Information Agency.
cd lgia
# https://stackoverflow.com/a/11826500
wget -q -O - https://www.lgia.gov.lv/en/place-name-data-open-data | grep -o '<a href="https://s3.storage.pub.lvdc.gov.lv/lgia-opendata/citi/vdb/.*.xlsx".*>' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' | xargs wget -q -O VDB_OBJEKTI.xlsx

psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL lgia.vdb()"
