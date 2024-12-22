#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=

cd $DIRECTORY

# Download open data of the Central Statistical Bureau of Latvia.
cd csp
wget -q https://data.gov.lv/dati/dataset/f4c3be02-cca3-4fd1-b3ea-c3050a155852/resource/6d8624c4-e75a-4080-88eb-c755b5de230a/download/atu_nuts_codes.csv

## Densely populated areas.
wget -q https://data.gov.lv/dati/dataset/2c07c211-0d78-49d3-9500-20b6f54f2a63/resource/93c8a5ed-0930-45f1-afeb-1105b6d5a7ca/download/dpa_2019_public.zip
7za x dpa_2019_public.zip -y -bsp0 -bso0
rm *.zip
mv dpa_2019_public dpa
cd dpa
for f in dpa_2019_public.*; do
  mv  -- "$f" "dpa${f#dpa_2019_public}"
done

## Historical lands.
cd ..
mkdir hl
cd hl
wget -q https://data.gov.lv/dati/dataset/c615b96a-4ae2-4a0b-bf22-7b67f7e9bbf4/resource/ae8ce5f6-2120-430e-a2fb-1fd7df1e7b85/download/vesturiskas_zemes.zip
7za x vesturiskas_zemes.zip -y -bsp0 -bso0
rm *.zip

# Download the Place Names Database of the Latvian Geospatial Information Agency.
cd ../..
cd lgia
wget -q -O - https://www.lgia.gov.lv/lv/place-names-data-open-data | grep -o '<a href="https://s3.storage.pub.lvdc.gov.lv/lgia-opendata/citi/vdb/CSV_[0-9]\{8\}.zip".*>' | sed -E 's/^.*href=["'"'"']([^"'"'"']*)["'"'"'].*$/\1/' | wget -i -
7za x *.zip -y -bsp0 -bso0
rm *.zip
iconv -f Windows-1257 -t UTF-8 */*.csv -o vdb_orig.csv
rm -rf -- */

# Download open data of the State Land Service.
cd ..
cd vzd

## Borders of administrative and territorial units.
wget -q https://data.gov.lv/dati/dataset/0c5e1a3b-0097-45a9-afa9-7f7262f3f623/resource/f539e8df-d4e4-4fc1-9f94-d25b662a4c38/download/aw_shp.zip
7za x aw_shp.zip -y -bsp0 -bso0
rm *.zip
rm Autoceli.*
rm Pilsetas.*
rm Ekas.*
rm Ielas.*
rm Mazciemi.*
rm Novadi.*
rm Pagasti.*

## Addresses (points).
cd aw_csv
wget -q https://data.gov.lv/dati/dataset/0c5e1a3b-0097-45a9-afa9-7f7262f3f623/resource/1d3cbdf2-ee7d-4743-90c7-97d38824d0bf/download/aw_csv.zip
7za x aw_csv.zip -y -bsp0 -bso0
rm *.zip
wget -q https://data.gov.lv/dati/dataset/0c5e1a3b-0097-45a9-afa9-7f7262f3f623/resource/c3d36546-f92c-4822-a0c4-ee7f1b7760a4/download/aw_his_csv.zip
7za x aw_his_csv.zip -y -bsp0 -bso0
rm *.zip

## Coordinates of deleted addresses of buildings. Script based on https://gist.github.com/laacz/8dfb7b69221790eb8d88e5fb91b9b088.
cd ..
mkdir aw_del
cd aw_del

FILES=$(curl https://data.gov.lv/dati/lv/dataset/f0624a01-4612-4092-a04e-5e1b6489668c.jsonld | jq -r '."@graph"[]."dcat:accessURL"."@id" | select(. != null)')

for FILE in $FILES
do
  curl "$FILE" -o ${FILE##*/}
done

mv dzestas_ek_koordinates_*.xlsx aw_eka_del.xlsx
