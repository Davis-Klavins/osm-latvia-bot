#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=
# Password of PostgreSQL user osm.
export PGPASSWORD=
# PostgreSQL IP address.
export IP_ADDRESS=
# PostgreSQL port.
export PORT=

# Download and import in the local PostgreSQL database open data of the State Land Service Cadastre Information System.
## Addresses of buildings and parcels.
cd $DIRECTORY/vzd
wget -q https://data.gov.lv/dati/dataset/be841486-4af9-4d38-aa14-6502a2ddb517/resource/2aeea249-6948-4713-92c2-e01543ea0f33/download/address.zip
mkdir address
7za x address.zip -y -bsp0 -bso0 -oaddress
rm *.zip
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CREATE TABLE IF NOT EXISTS vzd.nivkis_adreses_tmp (data XML);"
cd address

for i in $(find . -name "*.xml" -type f); do
  cat $i | psql.exe -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c '\COPY vzd.nivkis_adreses_tmp FROM stdin'
done

cd ..
rm -r address
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL vzd.nivkis_adreses()"

## Buildings and parcels. Script based on https://gist.github.com/laacz/8dfb7b69221790eb8d88e5fb91b9b088.
mkdir kk_shp
cd kk_shp

FILES=$(curl https://data.gov.lv/dati/lv/dataset/b28f0eed-73b0-4e44-94e7-b04b11bf0b69.jsonld | jq -r '."@graph"[]."dcat:accessURL"."@id" | select(. != null)' | dos2unix)

for FILE in $FILES
do
  curl "$FILE" -o ${FILE##*/}
done

7za x /*.zip -y -bsp0 -bso0
rm *.zip
cd ..
APPEND=0
LAYERS="KKBuilding KKParcel"

for type in $LAYERS; do
    APPEND=0
    rm "$LAYERS*";
    target_file="$type.shp"
    target_layer=$(echo "$type" | tr '[:upper:]' '[:lower:]')

    for file in kk_shp/**/"$type".shp; do
        if [ "$APPEND" == 0 ]; then
            echo -n "Create $target_file "
            ogr2ogr -f 'ESRI Shapefile' "$target_file" "$file" -lco ENCODING=UTF-8
            APPEND=1
        else
            echo -n "Update $target_file "
            ogr2ogr -f 'ESRI Shapefile' -update -append "$target_file" "$file" -nln "$target_layer"
        fi
        echo "(${target_file%.shp}; $file)"
    done
done

rm -r kk_shp
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL vzd.nivkis()"

## Attributes of buildings.
#mkdir building
#cd building
#wget -q https://data.gov.lv/dati/dataset/be841486-4af9-4d38-aa14-6502a2ddb517/resource/9fe29b57-07cd-4458-b22c-b0b9f2bc8915/download/building.zip
#7za x building.zip -y -bsp0 -bso0
#rm building.zip
#psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CREATE TABLE IF NOT EXISTS vzd.nivkis_buves_attr_tmp (data XML);"

#for file in */*.xml; do
#  sed -i -e 's/\r//g' -e 's/\t/ /g' -e 's/\\/\//g' "${file}"
#  echo "\COPY vzd.nivkis_buves_attr_tmp FROM" "${file}" >> script.sql
#done

#psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -f script.sql
#rm script.sql
#cd ..
#rm -r building
#psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL vzd.nivkis_buves_attr()"
