# osm-latvia-bot
Collection of scripts to update and maintain OpenStreetMap data in Latvia (currently only addresses). See https://wiki.openstreetmap.org/wiki/Automated_edits/Latvia-bot.

Prerequisites:
* PostgreSQL with PostGIS,
* Python 2 and 3 (incl. pip and requests package),
* wget,
* [oauth_cookie_client.py](https://github.com/geofabrik/sendfile_osm_oauth_protector/blob/master/oauth_cookie_client.py),
* [osmupdate](https://wiki.openstreetmap.org/wiki/Osmupdate),
* [osmconvert](https://wiki.openstreetmap.org/wiki/Osmconvert),
* [jq](https://stedolan.github.io/jq/),
* [XMLStarlet](http://xmlstar.sourceforge.net/),
* [osmosis](https://github.com/openstreetmap/osmosis) (set path to Java in bin\osmosis.bat on Windows),
* [Osmium Tool](https://osmcode.org/osmium-tool/),
* [upload.py](https://wiki.openstreetmap.org/wiki/Upload.py) (files used have been modified and placed in [upload.py directory](upload.py)),
* If used on Windows, Git to run files with .sh extension.

[tags_4_addresses.csv](tags_4_addresses.csv) - tags that allow object to have address tags.

| Column      | Description                         |
|-------------|-------------------------------------|
| key         | Key                                 |
| value       | Value                               |
| n_parcels   | Nodes within land parcels           |
| n_buildings | Nodes within buildings              |
| w           | Polygons (ways or within relations) |

## Initial setup

Set up local directories (set `DIRECTORY` variable to the directory where data will be stored locally (data directory)):

```sh
export DIRECTORY=
cd $DIRECTORY
mkdir osm
cd osm
mkdir csp
mkdir lgia
mkdir vzd
cd vzd
mkdir aw_csv
```

Clone this repository in the data directory.

Place [oauth_cookie_client.py](https://github.com/geofabrik/sendfile_osm_oauth_protector/blob/master/oauth_cookie_client.py), [settings.json](settings.json) (set `password`) and [latvia.poly](https://download.geofabrik.de/europe/latvia.poly) in the data directory.

Set up PostgreSQL database:

1. Create user for data editing (change `password` to user's password):

   ```sql
   DROP USER IF EXISTS osm;

   CREATE USER osm
     WITH PASSWORD 'password' LOGIN NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
   ```

2. Edit pg_hba.conf file to include the new user. Reload configuration.

3. Create database to store OSM data.

   ```sql
   CREATE DATABASE osm;

   GRANT ALL
     ON DATABASE osm
     TO osm;
   ```

4. In osm database:

   ```sql
   CREATE EXTENSION postgis;

   CREATE EXTENSION hstore;

   CREATE EXTENSION ogr_fdw;

   GRANT USAGE
     ON FOREIGN DATA WRAPPER ogr_fdw
     TO osm;
   ```

5. In osm database, create table to contain tags that allow object to have address tags:

   ```sql
   CREATE TABLE tags_4_addresses (
     key TEXT NOT NULL
     ,value TEXT
     ,n_parcels boolean
     ,n_buildings boolean
     ,w boolean
     );
   ```

6. Run [osm_initial.sh](osm_initial.sh) to download data needed for ogr_fdw (set `DIRECTORY` variable).

7. In osm database, create ogr_fdw foreign servers, schemas and tables (adjust `datasource` if necessary):

   * [ogr_fdw_atu_nuts_codes.sql](ogr_fdw_atu_nuts_codes.sql),
   * [ogr_fdw_dpa.sql](ogr_fdw_dpa.sql),
   * [ogr_fdw_hl.sql](ogr_fdw_hl.sql),
   * [ogr_fdw_vdb.sql](ogr_fdw_vdb.sql),
   * [ogr_fdw_vzd.sql](ogr_fdw_vzd.sql),
   * [ogr_fdw_vzd_aw_del.sql](ogr_fdw_vzd_aw_del.sql),
   * [aw_csv.sql](aw_csv.sql),
   * [history.sql](history.sql).

8. In osm database, create procedures:

   * [vzd.territorial_units()](territorial_units.sql) - maintains borders of administrative and territorial units (data of the State Land Service and the Central Statistical Bureau of Latvia);
   * [vzd.adreses()](adreses.sql) - maintains addresses (points, data of the State Land Service), execute also sections commented out that create tables;
   * [vzd.adreses_his_ekas_split()](adreses_his_ekas_split.sql) - splits historical notations of addresses of buildings.
   * [vzd.adreses_his_ekas_previous()](adreses_his_ekas_previous.sql) - returns previous house name or number and street name of addresses of buildings.
   * [vzd.nivkis_adreses()](nivkis_adreses.sql) - maintains addresses of buildings and land parcels (data of the State Land Service);
   * [vzd.nivkis()](nivkis.sql) - maintains buildings and land parcels (data of the State Land Service);
   * [vzd.nivkis_buves_attr()](nivkis_buves_attr.sql) - maintains attributes of buildings (data of the State Land Service);
   * [lgia.vdb()](vdb.sql) - maintains the Place Names Database (data of the Latvian Geospatial Information Agency);
   * [pgsnapshot_schema()](pgsnapshot_schema.sql) - recreates tables and functions needed to maintain OSM data;
   * [way_geometry()](way_geometry.sql) - creates geometry columns of ways;
   * [in_latvia()](in_latvia.sql) - creates tables with IDs and summary of tags that are located in Latvia;
   * [history.history()](history_proc.sql) - maintains historical OSM data;
   * [addresses()](addresses.sql) - data processing procedure of addresses.

## Source data update

1. [lgia_vdb.sh](lgia_vdb.sh) - download and renew in the local PostgreSQL database open data of the Place Names Database of the Latvian Geospatial Information Agency (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables). To be run occasionally (source data not updated frequently).

2. [vzd_cadastre.sh](vzd_cadastre.sh) - download and import in the local PostgreSQL database open data of the State Land Service Cadastre Information System (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables). Remove `.exe` if run under Linux. To be run weekly.

3. [csp_vzd_borders_addresses.sh](csp_vzd_borders_addresses.sh) - download and import in the local PostgreSQL database open data of the Central Statistical Bureau of Latvia and the State Land Service (borders and address points) (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables). To be run on working days. For the first time, run also [adreses_his.sql](adreses_his.sql).

## OSM historical data update

To be run daily.

1. Download latest internal OSM history data from Geofabrik: `wget -q -O latvia-internal.osh.pbf -N --no-cookies --header "Cookie: $(cat cookie.txt | cut -d ';' -f 1)" https://osm-internal.download.geofabrik.de/europe/latvia-internal.osh.pbf`.
2. Convert to the [OPL file format](https://osmcode.org/opl-file-format/): `osmium cat latvia-internal.osh.pbf -o latvia-internal.osm.opl`.
3. [history.sh](history.sh) - preprocess and update data in the local PostgreSQL database (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables).

## OSM data update

To be run daily.

1. [osm_1.sh](osm_1.sh) - import [tags_4_addresses.csv](tags_4_addresses.csv) in the local PostgreSQL database replacing existing data and download OSM data of Latvia (combine most recent data from Geofabrik and changes made afterwards) (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables, uncomment [line 14](https://github.com/Davis-Klavins/osm-latvia-bot/blob/main/osm_1.sh#L14) in production to use [tags_4_addresses.csv](tags_4_addresses.csv) from GitHub).
2. [osm_2.bat](osm_2.bat) - update OSM data in the local PostgreSQL database and derive osmChange file (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables). Large amount of changes lead to an error. Must be rewritten and merged with [osm_1.sh](osm_1.sh) and [osm_3.sh](osm_3.sh) to run under Linux.
4. [osm_3.sh](osm_3.sh) - split osmChange file and upload changes (set `DIRECTORY` variable and [OSM user password](osm_3.sh#L8)). Separate changeset is created for every 10 000 elements and closed. Post ways and relations with missing tags that previously had only address tags for manual review to [OSM Latvija Zulip chat](https://osmlatvija.zulipchat.com/).

## Optional

To change tags of an open changeset, e.g., comment, run [set-changeset-tag.py](upload.py/optional/set-changeset-tag.py) (change `changeset-id` to changeset ID and edit comment; username and password to be provided interactively): `py set-changeset-tag.py changeset-id comment "Comment."`.

To close changeset, run [close.py](upload.py/optional/close.py) (change `changeset-id` to changeset ID; username and password to be provided interactively): `py close.py changeset-id`.
