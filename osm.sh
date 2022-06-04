#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=
# Password of PostgreSQL user osm.
export PGPASSWORD=
# PostgreSQL IP address.
export IP_ADDRESS=
# PostgreSQL port.
export PORT=
# Password of OSM user latvia-bot.
export OSMPASSWORD=

cd $DIRECTORY

# Download and import data of tags that allow object to have address tags.
wget -q -O tags_4_addresses.csv https://github.com/Davis-Klavins/osm-latvia-bot/blob/main/tags_4_addresses.csv
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE tags_4_addresses;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c '\COPY tags_4_addresses FROM tags_4_addresses.csv CSV HEADER'

# Download latest internal OSM data.
python oauth_cookie_client.py -o cookie.txt -s settings.json
# Workaround from https://pavie.info/2020/08/12/complete-full-history-osm/ because command "wget -O latvia-latest-internal.osm.pbf --load-cookies cookie.txt --max-redirect 0 https://osm-internal.download.geofabrik.de/europe/latvia-latest-internal.osm.pbf" returns "ERROR 403: Forbidden".
wget -q -O latvia-latest-internal.osm.pbf -N --no-cookies --header "Cookie: $(cat cookie.txt | cut -d ';' -f 1)" https://osm-internal.download.geofabrik.de/europe/latvia-latest-internal.osm.pbf

# Execute PostgreSQL procedure that recreates tables and functions needed to maintain OSM data.
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL pgsnapshot_schema()"

# Renew OSM data in the local PostgreSQL database.
cd C:/Program\ Files\ \(x86\)/Osmosis/bin
cmd

# Set again variables to be used within Windows Command Prompt.
set DIRECTORY=
set PGPASSWORD=
set IP_ADDRESS=
set PORT=

osmosis --read-pbf %DIRECTORY%\latvia-latest-internal.osm.pbf --write-pgsql host="%IP_ADDRESS%:%PORT%" database="osm" user="osm" password="%PGPASSWORD%"
# osmosis --read-pbf %DIRECTORY%\latvia-latest-internal.osm.pbf --write-pgsql-change host="%IP_ADDRESS%:%PORT%" database="osm" user="osm" password="%PGPASSWORD%"

# Execute PostgreSQL procedure that creates geometry columns of ways.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "CALL way_geometry()"

# Execute PostgreSQL procedure that creates tables with IDs and summary of tags that are located in Latvia.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "CALL in_latvia()"

# Execute PostgreSQL data processing procedure of addresses.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "CALL addresses()"

# Get OsmChange file.
# osmosis --read-pgsql host="%IP_ADDRESS%:%PORT%" database="osm" user="osm" password="%PGPASSWORD%" --dataset-dump --sort type="TypeThenId" --read-pbf %DIRECTORY%\latvia-latest-internal.osm.pbf --sort type="TypeThenId" --derive-change --write-xml-change file="%DIRECTORY%\latvia-diff.osc"
exit

# Delete bounds element (3rd line) from the OsmChange file.
# cd $DIRECTORY
# sed -i '4d' latvia-diff.osc

# Upload changes (https://wiki.openstreetmap.org/wiki/Upload.py).
# python upload.py -u latvia-bot -p $OSMPASSWORD -c yes -m "Comment." -y "Valsts adrešu reģistra informācijas sistēmas atvērtie dati" D:\osm\latvia-diff-for-upload.osc
