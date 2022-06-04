#!/bin/bash
# Directory where data are stored locally.
export DIRECTORY=
# Password of PostgreSQL user osm.
export PGPASSWORD=
# PostgreSQL IP address.
export IP_ADDRESS=
# PostgreSQL port.
export PORT=
export PGCLIENTENCODING=UTF8

cd $DIRECTORY

# Download and import in the local PostgreSQL database open data of the Central Statistical Bureau of Latvia.
cd csp
wget -q -O atu_nuts_codes.csv https://data.gov.lv/dati/dataset/f4c3be02-cca3-4fd1-b3ea-c3050a155852/resource/6d8624c4-e75a-4080-88eb-c755b5de230a/download/atu_nuts_codes.csv

# Download and import in the local PostgreSQL database open data of the State Land Service (borders and address points).
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
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL vzd.territorial_units()"

## Addresses (points).
cd aw_csv
wget -q https://data.gov.lv/dati/dataset/0c5e1a3b-0097-45a9-afa9-7f7262f3f623/resource/1d3cbdf2-ee7d-4743-90c7-97d38824d0bf/download/aw_csv.zip
unzip -o -q aw_csv.zip
rm *.zip
wget -q https://data.gov.lv/dati/dataset/0c5e1a3b-0097-45a9-afa9-7f7262f3f623/resource/c3d36546-f92c-4822-a0c4-ee7f1b7760a4/download/aw_his_csv.zip
unzip -o -q aw_his_csv.zip
rm *.zip
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_ciems RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_ciems (kods, tips_cd, nosaukums, vkur_cd, vkur_tips, apstipr, apst_pak, statuss, sort_nos, dat_sak, dat_mod, dat_beig, atrib, std) FROM AW_CIEMS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_ciems_his RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_ciems_his (kods, tips_cd, dat_sak, dat_mod, dat_beig, std) FROM AW_CIEMS_HIS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER)"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_dziv RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_dziv (kods, tips_cd, statuss, apstipr, apst_pak, vkur_cd, vkur_tips, nosaukums, sort_nos, atrib, dat_sak, dat_mod, dat_beig, std) FROM AW_DZIV.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_dziv_his RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_dziv_his (kods, tips_cd, dat_sak, dat_mod, dat_beig, std) FROM AW_DZIV_HIS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER)"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_eka RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_eka (kods, tips_cd, statuss, apstipr, apst_pak, vkur_cd, vkur_tips, nosaukums, sort_nos, atrib, pnod_cd, dat_sak, dat_mod, dat_beig, for_build, plan_adr, std, koord_x, koord_y, dd_n, dd_e) FROM AW_EKA.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak, pnod_cd, koord_x, koord_y, dd_n, dd_e))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_eka_his RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_eka_his (kods, kods_his, tips_cd, dat_sak, dat_mod, dat_beig, std) FROM AW_EKA_HIS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (kods_his))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_iela RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_iela (kods, tips_cd, nosaukums, vkur_cd, vkur_tips, apstipr, apst_pak, statuss, sort_nos, dat_sak, dat_mod, dat_beig, atrib, std) FROM AW_IELA.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_iela_his RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_iela_his (kods, tips_cd, dat_sak, dat_mod, dat_beig, std) FROM AW_IELA_HIS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER)"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_novads RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_novads (kods, tips_cd, nosaukums, vkur_cd, vkur_tips, apstipr, apst_pak, statuss, sort_nos, dat_sak, dat_mod, dat_beig, atrib, std) FROM AW_NOVADS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_novads_his RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_novads_his (kods, tips_cd, dat_sak, dat_mod, dat_beig, std) FROM AW_NOVADS_HIS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER)"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_pagasts RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_pagasts (kods, tips_cd, nosaukums, vkur_cd, vkur_tips, apstipr, apst_pak, statuss, sort_nos, dat_sak, dat_mod, dat_beig, atrib, std) FROM AW_PAGASTS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_pagasts_his RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_pagasts_his (kods, tips_cd, dat_sak, dat_mod, dat_beig, std) FROM AW_PAGASTS_HIS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER)"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_pilseta RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_pilseta (kods, tips_cd, nosaukums, vkur_cd, vkur_tips, apstipr, apst_pak, statuss, sort_nos, dat_sak, dat_mod, dat_beig, atrib, std) FROM AW_PILSETA.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_pilseta_his RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_pilseta_his (kods, tips_cd, dat_sak, dat_mod, dat_beig, std) FROM AW_PILSETA_HIS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER)"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_ppils RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_ppils (kods, ppils) FROM AW_PPILS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER)"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_rajons RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_rajons (kods, tips_cd, nosaukums, vkur_cd, vkur_tips, apstipr, apst_pak, statuss, sort_nos, dat_sak, dat_mod, dat_beig, atrib) FROM AW_RAJONS.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (apstipr, apst_pak))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "TRUNCATE TABLE vzd.aw_vietu_centroidi RESTART IDENTITY;"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "\COPY vzd.aw_vietu_centroidi (kods, tips_cd, nosaukums, vkur_cd, vkur_tips, std, koord_x, koord_y, dd_n, dd_e) FROM AW_VIETU_CENTROIDI.CSV WITH (FORMAT CSV, DELIMITER ';', QUOTE '#', HEADER, FORCE_NULL (koord_x, koord_y, dd_n, dd_e))"
psql -h $IP_ADDRESS -p $PORT -U osm -d osm -w -c "CALL vzd.adreses()"
