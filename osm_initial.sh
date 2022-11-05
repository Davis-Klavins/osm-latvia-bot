#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=

cd $DIRECTORY

# Download open data of the Central Statistical Bureau of Latvia.
cd csp
wget -q https://data.gov.lv/dati/dataset/f4c3be02-cca3-4fd1-b3ea-c3050a155852/resource/6d8624c4-e75a-4080-88eb-c755b5de230a/download/atu_nuts_codes.csv

## Densely populated areas.
wget -q https://data.gov.lv/dati/dataset/2c07c211-0d78-49d3-9500-20b6f54f2a63/resource/93c8a5ed-0930-45f1-afeb-1105b6d5a7ca/download/dpa_2019_public.zip
unzip -o -q dpa_2019_public.zip
rm *.zip
mv dpa_2019_public dpa
cd dpa
for f in dpa_2019_public.*; do
  mv  -- "$f" "dpa${f#dpa_2019_public}"
done

# Download the Place Names Database of the Latvian Geospatial Information Agency.
cd ../..
cd lgia
wget -q -O index.html https://www.lgia.gov.lv/lv/place-names-data-open-data
# https://stackoverflow.com/a/11826500
cat index.html | grep -o '<a href="https://s3.storage.pub.lvdc.gov.lv/lgia-opendata/citi/vdb/.*.xlsx".*>' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' | xargs wget -q -O VDB_OBJEKTI.xlsx
rm index.html

# Download open data of the State Land Service.
cd ..
cd vzd

## Borders of administrative and territorial units.
wget -q https://data.gov.lv/dati/dataset/0c5e1a3b-0097-45a9-afa9-7f7262f3f623/resource/f539e8df-d4e4-4fc1-9f94-d25b662a4c38/download/aw_shp.zip
unzip -o -q aw_shp.zip
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
unzip -o -q aw_csv.zip
rm *.zip
wget -q https://data.gov.lv/dati/dataset/0c5e1a3b-0097-45a9-afa9-7f7262f3f623/resource/c3d36546-f92c-4822-a0c4-ee7f1b7760a4/download/aw_his_csv.zip
unzip -o -q aw_his_csv.zip
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
