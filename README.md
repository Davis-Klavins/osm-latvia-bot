# osm-latvia-bot
Collection of scripts to update and maintain OpenStreetMap data in Latvia (currently only addresses and tags). See https://wiki.openstreetmap.org/wiki/Automated_edits/Latvia-bot.

Written for Ubuntu Server 24.04. Prerequisites that need to be additionally installed:
* PostgreSQL with PostGIS and [PostgreSQL OGR Foreign Data Wrapper](https://github.com/pramsey/pgsql-ogr-fdw),
* GDAL,
* p7zip,
* [XMLStarlet](http://xmlstar.sourceforge.net/),
* [osmctools](https://gitlab.com/osm-c-tools/osmctools),
* [osmosis](https://github.com/openstreetmap/osmosis),
* [Osmium Tool](https://osmcode.org/osmium-tool/),
* [oauth_cookie_client.py](https://github.com/geofabrik/sendfile_osm_oauth_protector/blob/master/oauth_cookie_client.py),
* [upload.py](https://wiki.openstreetmap.org/wiki/Upload.py) (files used have been modified and placed in [upload.py directory](upload.py), except [osmapi.py](https://github.com/Zverik/osm-bulk-upload/blob/master/osmapi.py)),
* text-based web browser to authenticate Upload.py for the first time (tested and works with elinks, after sending authorization request, exit manually by pressing `q`).

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

Install [cli-oauth2](https://github.com/Zverik/cli-oauth2) Python package:

```sh
export DIRECTORY=
cd $DIRECTORY/osm
sudo apt install python3-venv
python3 -m venv .osm
.osm/bin/pip install cli-oauth2
```

Clone this repository in the osm directory.

Place [oauth_cookie_client.py](https://github.com/geofabrik/sendfile_osm_oauth_protector/blob/master/oauth_cookie_client.py), [settings.json](settings.json) (set `password`), [latvia.poly](https://download.geofabrik.de/europe/latvia.poly) and *.sh files used for data update (see [Source data update](README.md#source-data-update) and [OSM data update](README.md#osm-data-update)) in the data directory.

Make shell and Python scripts executable:

```sh
export DIRECTORY=
cd $DIRECTORY/osm
find . -type f -name "*.py" -exec chmod +x {} \;
chmod +x *.sh
```

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

   ALTER DATABASE osm OWNER TO osm;

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
   * [tags()](tags.sql) - data processing procedure of tags.

## Source data update

1. [lgia_vdb.sh](lgia_vdb.sh) - download and renew in the local PostgreSQL database open data of the Place Names Database of the Latvian Geospatial Information Agency (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables). To be run occasionally (source data not updated frequently).

2. [vzd_cadastre.sh](vzd_cadastre.sh) - download and import in the local PostgreSQL database open data of the State Land Service Cadastre Information System (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables). Remove `.exe` if run under Linux. To be run weekly.

3. [csp_vzd_borders_addresses.sh](csp_vzd_borders_addresses.sh) - download and import in the local PostgreSQL database open data of the Central Statistical Bureau of Latvia and the State Land Service (borders and address points) (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables). To be run on working days.

## OSM data update

[osm.sh](osm.sh) - download, process and update OSM data of Latvia (set `DIRECTORY`, `PGPASSWORD`, `IP_ADDRESS` and `PORT` variables, [OSM user password](osm.sh#L19), [Zulip bot API key](osm.sh#L21), uncomment [line 30](https://github.com/Davis-Klavins/osm-latvia-bot/blob/main/osm.sh#L30) in production to use [tags_4_addresses.csv](tags_4_addresses.csv) from GitHub). To be run daily.

## Optional

To change tags of an open changeset, e.g., comment, run [set-changeset-tag.py](upload.py/optional/set-changeset-tag.py) (change `changeset-id` to changeset ID and edit comment; username and password to be provided interactively): `set-changeset-tag.py changeset-id comment "Comment."`.

To close changeset, run [close.py](upload.py/optional/close.py) (change `changeset-id` to changeset ID; username and password to be provided interactively): `close.py changeset-id`.
