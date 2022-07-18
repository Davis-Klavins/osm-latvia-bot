#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=

cd $DIRECTORY

# Download and import in the local PostgreSQL database open data of the Central Statistical Bureau of Latvia.
cd csp
wget -q https://data.gov.lv/dati/dataset/f4c3be02-cca3-4fd1-b3ea-c3050a155852/resource/6d8624c4-e75a-4080-88eb-c755b5de230a/download/atu_nuts_codes.csv
wget -q https://data.gov.lv/dati/dataset/2c07c211-0d78-49d3-9500-20b6f54f2a63/resource/93c8a5ed-0930-45f1-afeb-1105b6d5a7ca/download/dpa_2019_public.zip
unzip -o -q dpa_2019_public.zip
rm *.zip

# Download and import in the local PostgreSQL database open data of the State Land Service.
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
