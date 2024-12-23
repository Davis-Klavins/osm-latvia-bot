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

cd $DIRECTORY

# Download the Place Names Database of the Latvian Geospatial Information Agency.
cd lgia
wget -q -O - https://www.lgia.gov.lv/lv/place-names-data-open-data | grep -o '<a href="https://s3.storage.pub.lvdc.gov.lv/lgia-opendata/citi/vdb/CSV_[0-9]\{8\}.zip".*>' | sed -E 's/^.*href=["'"'"']([^"'"'"']*)["'"'"'].*$/\1/' | wget -i -
7za x *.zip -y -bsp0 -bso0
rm *.zip
iconv -f Windows-1257 -t UTF-8 */*.csv -o vdb_orig.csv
rm -rf -- */

psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL lgia.vdb()"
