@echo off
chcp 65001
REM Directory where data are stored locally.
set DIRECTORY=
REM Password of PostgreSQL user osm.
set PGPASSWORD=
REM PostgreSQL IP address.
set IP_ADDRESS=
REM PostgreSQL port.
set PORT=

REM Execute PostgreSQL procedure that recreates tables and functions needed to maintain OSM data.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "CALL pgsnapshot_schema()"

REM Renew OSM data in the local PostgreSQL database.
C:
cd "C:\Program Files (x86)\Osmosis\bin"
CALL osmosis --read-pbf %DIRECTORY%\latvia-latest-internal.osm.pbf --write-pgsql host="%IP_ADDRESS%:%PORT%" database="osm" user="osm" password="%PGPASSWORD%"
REM CALL osmosis --read-pbf %DIRECTORY%\latvia-latest-internal.osm.pbf --write-pgsql-change host="%IP_ADDRESS%:%PORT%" database="osm" user="osm" password="%PGPASSWORD%"

REM Execute PostgreSQL procedure that creates geometry columns of ways.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "CALL way_geometry()"

REM Execute PostgreSQL procedure that creates tables with IDs and summary of tags that are located in Latvia.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "CALL in_latvia()"

REM Execute PostgreSQL data processing procedure of addresses.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "CALL addresses()"

REM Export table ways_relations_del.
psql -h %IP_ADDRESS% -p %PORT% -U osm -d osm -w -c "\COPY (SELECT type, id FROM ways_relations_del) to '%DIRECTORY%\ways_relations_del.csv' WITH (FORMAT CSV)"

REM Get OsmChange file.
CALL osmosis --read-pgsql host="%IP_ADDRESS%:%PORT%" database="osm" user="osm" password="%PGPASSWORD%" --dataset-dump --sort type="TypeThenId" --read-pbf %DIRECTORY%\latvia-latest-internal.osm.pbf --sort type="TypeThenId" --derive-change --write-xml-change file="%DIRECTORY%\latvia-diff.osc"
