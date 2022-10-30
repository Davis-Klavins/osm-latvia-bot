CREATE OR REPLACE PROCEDURE vzd.adreses(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

/*
--Types of addressation objects.
DROP TABLE IF EXISTS vzd.adreses_tips;

CREATE TABLE vzd.adreses_tips (
  id serial PRIMARY KEY
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT
  );

COMMENT ON TABLE vzd.adreses_tips IS 'Adresācijas objektu tipi.';

COMMENT ON COLUMN vzd.adreses_tips.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses_tips.tips_cd IS 'Kods.';

COMMENT ON COLUMN vzd.adreses_tips.nosaukums IS 'Adresācijas objekta tips.';

INSERT INTO vzd.adreses_tips (
  tips_cd
  ,nosaukums
  )
VALUES (
  101
  ,'Latvijas Republika'
  )
  ,(
  102
  ,'Rajons'
  )
  ,(
  104
  ,'Pilsēta'
  )
  ,(
  105
  ,'Pagasts'
  )
  ,(
  106
  ,'Ciems/mazciems'
  )
  ,(
  107
  ,'Iela'
  )
  ,(
  108
  ,'Ēka, apbūvei paredzēta zemes vienība'
  )
  ,(
  109
  ,'Telpu grupa'
  )
  ,(
  113
  ,'Novads'
  );

--Levels of approval of addressation objects.
DROP TABLE IF EXISTS vzd.adreses_apst_pak;

CREATE TABLE vzd.adreses_apst_pak (
  id serial PRIMARY KEY
  ,apst_pak SMALLINT NOT NULL
  ,nosaukums TEXT
  ,apraksts TEXT
  );

COMMENT ON TABLE vzd.adreses_apst_pak IS 'Adresācijas objektu apstiprinājuma pakāpes.';

COMMENT ON COLUMN vzd.adreses_apst_pak.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses_apst_pak.apst_pak IS 'Kods.';

COMMENT ON COLUMN vzd.adreses_apst_pak.nosaukums IS 'Saīsinājums.';

COMMENT ON COLUMN vzd.adreses_apst_pak.apraksts IS 'Apstiprinājuma pakāpe.';

INSERT INTO vzd.adreses_apst_pak (
  apst_pak
  ,nosaukums
  ,apraksts
  )
VALUES (
  251
  ,'Kļūdains apstiprinājums'
  ,'Kļūdains apstiprinājums.'
  )
  ,(
  252
  ,'Oficiāls apstiprinājums'
  ,'Apstiprinājums, pamatojoties uz oficiālu informāciju, ja par adresācijas objekta reģistrāciju vai datu aktualizāciju iesniegts normatīvajos aktos norādītais dokuments.'
  )
  ,(
  253
  ,'Daļējs apstiprinājums'
  ,'Apstiprinājums, pamatojoties uz dokumentiem bez atbilstoša juridiska statusa vai, ja par adresācijas objekta reģistrāciju vai datu aktualizāciju iesniegts pašvaldības cita veida rakstisks tā pastāvēšanas apliecinājums.'
  )
  ,(
  254
  ,'Citu reģistru apstiprinājums'
  ,'Saņemta (nepārbaudīta) no ārējiem reģistriem, ja dati par adresācijas objektu iegūti no citām valsts informācijas sistēmām (piemēram, datu sākotnējās uzkrāšanas laikā).'
  );
*/

--Table to accumulate coordinates of addressation objects of deleted buildings and land parcels intended for building.
/*
DROP TABLE IF EXISTS vzd.adreses_ekas_koord_del;

CREATE TABLE vzd.adreses_ekas_koord_del (
  id serial PRIMARY KEY
  ,adr_cd INT NOT NULL
  ,geom geometry(Point, 3059)
  );

COMMENT ON TABLE vzd.adreses_ekas_koord_del IS 'Dzēsto ēku un apbūvei paredzēto zemes vienību adresācijas objektu koordinātas.';

COMMENT ON COLUMN vzd.adreses_ekas_koord_del.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses_ekas_koord_del.adr_cd IS 'Adresācijas objekta kods.';

COMMENT ON COLUMN vzd.adreses_ekas_koord_del.geom IS 'Ģeometrija.';
*/

INSERT INTO vzd.adreses_ekas_koord_del (
  adr_cd
  ,geom
  )
SELECT a.adr_cd
  ,a.geom
FROM vzd.adreses_ekas a
INNER JOIN vzd.aw_eka b ON a.adr_cd = b.kods
WHERE a.geom IS NOT NULL
  AND b.koord_x IS NULL;

--Current, erroneous and deleted addresses.
---Main table with objects of addressation.
DROP TABLE IF EXISTS vzd.adreses CASCADE;

CREATE TABLE vzd.adreses (
  id serial PRIMARY KEY
  ,adr_cd INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,statuss CHAR(3) NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,std TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,sort_nos TEXT NOT NULL
  ,atrib TEXT
  ,dat_sak DATE NOT NULL
  ,dat_mod TIMESTAMP NOT NULL
  ,dat_beig DATE
  );

COMMENT ON TABLE vzd.adreses IS 'Adresācijas objekti.';

COMMENT ON COLUMN vzd.adreses.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses.adr_cd IS 'Adresācijas objekta kods.';

COMMENT ON COLUMN vzd.adreses.tips_cd IS 'Adresācijas objekta tipa kods.';

COMMENT ON COLUMN vzd.adreses.statuss IS 'Adresācijas objekta statuss (EKS – eksistējošs, DEL – likvidēts, ERR – kļūdains).';

COMMENT ON COLUMN vzd.adreses.apstipr IS 'Vai adresācijas objekts ir apstiprināts.';

COMMENT ON COLUMN vzd.adreses.apst_pak IS 'Adresācijas objekta apstiprinājuma pakāpes kods.';

COMMENT ON COLUMN vzd.adreses.std IS 'Adresācijas objekta pilnais adreses pieraksts.';

COMMENT ON COLUMN vzd.adreses.vkur_cd IS 'Tā adresācijas objekta kods, kuram hierarhiski pakļauts attiecīgais adresācijas objekts.';

COMMENT ON COLUMN vzd.adreses.vkur_tips IS 'Tā adresācijas objekta tipa kods, kuram hierarhiski pakļauts attiecīgais adresācijas objekts.';

COMMENT ON COLUMN vzd.adreses.nosaukums IS 'Adresācijas objekta aktuālais nosaukums.';

COMMENT ON COLUMN vzd.adreses.sort_nos IS 'Kārtošanas nosacījums adresācijas objekta nosaukumam (ja nosaukumā ir tikai teksts, kārtošanas nosacījums ir identisks nosaukumam).';

COMMENT ON COLUMN vzd.adreses.atrib IS 'Rajoniem, novadiem, pagastiem un pilsētām ATVK kods; ciemiem vērtība "1" norāda, ka objekts ir mazciems (ciems, kuram nav robeža); ēkām un apbūvei paredzētām zemes vienībām pasta indekss.';

COMMENT ON COLUMN vzd.adreses.dat_sak IS 'Adresācijas objekta izveidošanas vai pirmreizējās reģistrācijas datums, ja nav zināms precīzs adresācijas objekta izveides datums.';

COMMENT ON COLUMN vzd.adreses.dat_mod IS 'Datums un laiks, kad pēdējo reizi informācijas sistēmā tehniski modificēts ieraksts/dati par adresācijas objektu (piemēram, aktualizēts statuss, apstiprinājuma pakāpe, pievienots atribūts u.c.) vai mainīts pilnais adreses pieraksts.';

COMMENT ON COLUMN vzd.adreses.dat_beig IS 'Adresācijas objekta likvidācijas datums, ja adresācijas objekts beidza pastāvēt.';

---Flats.
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_dziv;

---Buildings.
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_eka;

---Streets.
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_iela;

---Villages.
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_ciems;

---Cities and towns.
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_pilseta;

---Rural territories.
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_pagasts;

---Municipalities.
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_novads;

---Districts (until June 30 2009).
INSERT INTO vzd.adreses (
  adr_cd
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,std
  ,vkur_cd
  ,vkur_tips
  ,nosaukums
  ,sort_nos
  ,atrib
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,statuss
  ,apstipr
  ,apst_pak
  ,nosaukums
  ,vkur_cd
  ,vkur_tips
  ,TRIM(nosaukums)
  ,TRIM(sort_nos)
  ,CASE 
    WHEN atrib LIKE ''
      THEN NULL
    ELSE atrib
    END
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_rajons;

---Administrative districts of Riga.
DROP TABLE IF EXISTS vzd.adreses_pp;

CREATE TABLE vzd.adreses_pp (
  id serial PRIMARY KEY
  ,adr_cd INT NOT NULL
  ,ppils TEXT NOT NULL
  );

COMMENT ON TABLE vzd.adreses_pp IS 'Sasaiste starp ēku vai apbūvei paredzētu zemes vienību adresēm ar priekšpilsētām Rīgā.';

COMMENT ON COLUMN vzd.adreses_pp.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses_pp.adr_cd IS 'Adresācijas objekta kods ēkai vai apbūvei paredzētai zemes vienībai.';

COMMENT ON COLUMN vzd.adreses_pp.ppils IS 'Priekšpilsētas nosaukums.';

INSERT INTO vzd.adreses_pp (
  adr_cd
  ,ppils
  )
SELECT kods
  ,TRIM(ppils)
FROM vzd.aw_ppils;

---Additional data on buildings.
DROP TABLE IF EXISTS vzd.adreses_ekas;

CREATE TABLE vzd.adreses_ekas (
  id serial PRIMARY KEY
  ,adr_cd INT NOT NULL
  ,pnod_cd INT
  ,for_build BOOLEAN NOT NULL
  ,plan_adr BOOLEAN NOT NULL
  ,geom geometry(Point, 3059)
  );

COMMENT ON TABLE vzd.adreses_ekas IS 'Papildus dati par ēku un apbūvei paredzētu zemes vienību adresācijas objektiem.';

COMMENT ON COLUMN vzd.adreses_ekas.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses_ekas.adr_cd IS 'Adresācijas objekta kods.';

COMMENT ON COLUMN vzd.adreses_ekas.pnod_cd IS 'Pasta nodaļas apkalpes teritorijas kods.';

COMMENT ON COLUMN vzd.adreses_ekas.for_build IS 'Pazīme, ka adresācijas objekts ir apbūvei paredzēta zemes vienība (true – apbūvei paredzēta zemes vienība, false – ēka).';

COMMENT ON COLUMN vzd.adreses_ekas.plan_adr IS 'Pazīme, ka adrese ir plānota (true – plānotā adrese nav piesaistīta nevienam objektam Kadastra informācijas sistēmā, false – plānotā adrese ir piesaistīta nekustamā īpašuma objektam Kadastra informācijas sistēmā).';

COMMENT ON COLUMN vzd.adreses_ekas.geom IS 'Ģeometrija.';

INSERT INTO vzd.adreses_ekas (
  adr_cd
  ,pnod_cd
  ,for_build
  ,plan_adr
  ,geom
  )
SELECT kods
  ,pnod_cd
  ,for_build
  ,plan_adr
  ,ST_SetSRID(ST_MakePoint(koord_y, koord_x), 3059)
FROM vzd.aw_eka;

CREATE INDEX adreses_ekas_geom_idx ON vzd.adreses_ekas USING GIST (geom);

--Buildings with current address notation separated by fields. Code based on https://github.com/laacz/vzd-importer.
DROP MATERIALIZED VIEW IF EXISTS vzd.adreses_ekas_sadalitas;

CREATE MATERIALIZED VIEW vzd.adreses_ekas_sadalitas
AS
SELECT a.adr_cd
  ,CASE 
    WHEN iela.nosaukums IS NOT NULL
      THEN NULL
    ELSE a.nosaukums
    END nosaukums
  ,CASE 
    WHEN iela.nosaukums IS NOT NULL
      THEN a.nosaukums
    ELSE NULL
    END nr
  ,iela.nosaukums iela
  ,COALESCE(ciems.nosaukums, ciems_no_ielas.nosaukums) ciems
  ,COALESCE(pilseta.nosaukums, pilseta_no_ielas.nosaukums) pilseta
  ,REPLACE(COALESCE(pagasts.nosaukums, pagasts_no_ciema.nosaukums, pagasts_no_ciema_no_ielas.nosaukums), 'pag.', 'pagasts') pagasts
  ,REPLACE(COALESCE(novads_no_pagasta.nosaukums, novads_no_pagasta_no_ciema.nosaukums, novads_no_pagasta_no_ciema_no_ielas.nosaukums, novads_no_pilsetas.nosaukums, novads_no_pilsetas_no_ielas.nosaukums), 'nov.', 'novads') novads
  ,a.atrib
  ,a.std
  ,ST_Transform(b.geom, 4326) geom
FROM vzd.adreses a
LEFT JOIN vzd.adreses_ekas b ON a.adr_cd = b.adr_cd
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 107
  ) iela ON iela.adr_cd = a.vkur_cd
---Building is directly in a village.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 106
  ) ciems ON ciems.adr_cd = a.vkur_cd
---Building is on a street in a village.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 106
  ) ciems_no_ielas ON ciems_no_ielas.adr_cd = iela.vkur_cd
---Building is directly in a city.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 104
  ) pilseta ON pilseta.adr_cd = a.vkur_cd
---Building is on a street in a city.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 104
  ) pilseta_no_ielas ON pilseta_no_ielas.adr_cd = iela.vkur_cd
---Building is directly in a rural territory.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 105
  ) pagasts ON pagasts.adr_cd = a.vkur_cd
---Building is directly in a village in a rural territory.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 105
  ) pagasts_no_ciema ON pagasts_no_ciema.adr_cd = ciems.vkur_cd
---Building is on a street in a village in a rural territory.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 105
  ) pagasts_no_ciema_no_ielas ON pagasts_no_ciema_no_ielas.adr_cd = ciems_no_ielas.vkur_cd
---Building is in a rural territory in a municipality.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 113
  ) novads_no_pagasta ON novads_no_pagasta.adr_cd = pagasts.vkur_cd
---Building is in a village in a rural territory in a municipality.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 113
  ) novads_no_pagasta_no_ciema ON novads_no_pagasta_no_ciema.adr_cd = pagasts_no_ciema.vkur_cd
---Building is on a street in a village in a rural territory in a municipality.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 113
  ) novads_no_pagasta_no_ciema_no_ielas ON novads_no_pagasta_no_ciema_no_ielas.adr_cd = pagasts_no_ciema_no_ielas.vkur_cd
---Building is directly in a town in a municipality.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 113
  ) novads_no_pilsetas ON novads_no_pilsetas.adr_cd = pilseta.vkur_cd
---Building is on a street in a town in a municipality.
LEFT JOIN (
  SELECT *
  FROM vzd.adreses
  WHERE tips_cd = 113
  ) novads_no_pilsetas_no_ielas ON novads_no_pilsetas_no_ielas.adr_cd = pilseta_no_ielas.vkur_cd
WHERE a.tips_cd = 108
  AND a.statuss LIKE 'EKS'
  AND b.geom IS NOT NULL;

COMMENT ON MATERIALIZED VIEW vzd.adreses_ekas_sadalitas IS 'Ēku un apbūvei paredzēto zemes vienību adresācijas objekti ar aktuālo adreses pierakstu, kas sadalīts pa laukiem.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.adr_cd IS 'Adresācijas objekta kods.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.nosaukums IS 'Ēkas nosaukums.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.nr IS 'Ēkas Nr.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.iela IS 'Ielas nosaukums.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.ciems IS 'Ciema/mazciema nosaukums.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.pilseta IS 'Pilsētas nosaukums.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.pagasts IS 'Pagasta nosaukums.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.novads IS 'Novada nosaukums.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.atrib IS 'Pasta indekss.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.std IS 'Adresācijas objekta pilnais adreses pieraksts.';

COMMENT ON COLUMN vzd.adreses_ekas_sadalitas.geom IS 'Ģeometrija.';

CREATE INDEX adreses_ekas_sadalitas_geom_idx ON vzd.adreses_ekas_sadalitas USING GIST (geom);

--Historical notations of addresses.
/*
DROP TABLE IF EXISTS vzd.adreses_his;

CREATE TABLE vzd.adreses_his (
  id serial PRIMARY KEY
  ,adr_cd INT NOT NULL
  ,adr_cd_his INT
  ,tips_cd SMALLINT NOT NULL
  ,std TEXT
  ,dat_sak DATE NOT NULL
  ,dat_mod TIMESTAMP NOT NULL
  ,dat_beig DATE NULL
  );

COMMENT ON TABLE vzd.adreses_his IS 'Adrešu vēsturiskie pieraksti.';

COMMENT ON COLUMN vzd.adreses_his.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses_his.adr_cd IS 'Adresācijas objekta kods.';

COMMENT ON COLUMN vzd.adreses_his.adr_cd_his IS 'Adresācijas objekta vēsturiskais kods (gadījumos, kad viena adrese bija lietota vairākiem objektiem).';

COMMENT ON COLUMN vzd.adreses_his.tips_cd IS 'Adresācijas objekta tipa kods.';

COMMENT ON COLUMN vzd.adreses_his.std IS 'Adresācijas objekta pilnais vēsturiskais adreses pieraksts.';

COMMENT ON COLUMN vzd.adreses_his.dat_sak IS 'Adresācijas objekta izveidošanas vai pirmreizējās reģistrācijas datums, ja nav zināms precīzs adresācijas objekta izveides datums.';

COMMENT ON COLUMN vzd.adreses_his.dat_mod IS 'Datums un laiks, kad pēdējo reizi informācijas sistēmā tehniski modificēts ieraksts/dati par adresācijas objektu (piemēram, aktualizēts statuss, apstiprinājuma pakāpe, pievienots atribūts u.c.) vai mainīts pilnais adreses pieraksts.';

COMMENT ON COLUMN vzd.adreses_his.dat_beig IS 'Adresācijas objekta likvidācijas datums.';
*/

---Flats.
INSERT INTO vzd.adreses_his (
  adr_cd
  ,tips_cd
  ,std
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,std
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_dziv_his
WHERE to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP > (
    SELECT MAX(dat_mod)
    FROM vzd.adreses_his
    WHERE tips_cd = 109
    );

---Buildings.
INSERT INTO vzd.adreses_his (
  adr_cd
  ,adr_cd_his
  ,tips_cd
  ,std
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,kods_his
  ,tips_cd
  ,std
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_eka_his
WHERE to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP > (
    SELECT MAX(dat_mod)
    FROM vzd.adreses_his
    WHERE tips_cd = 108
    );

---Streets.
INSERT INTO vzd.adreses_his (
  adr_cd
  ,tips_cd
  ,std
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,std
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_iela_his
WHERE to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP > (
    SELECT MAX(dat_mod)
    FROM vzd.adreses_his
    WHERE tips_cd = 107
    );

---Villages.
INSERT INTO vzd.adreses_his (
  adr_cd
  ,tips_cd
  ,std
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,std
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_ciems_his
WHERE to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP > (
    SELECT MAX(dat_mod)
    FROM vzd.adreses_his
    WHERE tips_cd = 106
    );

---Cities and towns.
INSERT INTO vzd.adreses_his (
  adr_cd
  ,tips_cd
  ,std
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,std
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_pilseta_his
WHERE to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP > (
    SELECT MAX(dat_mod)
    FROM vzd.adreses_his
    WHERE tips_cd = 104
    );

---Rural territories.
INSERT INTO vzd.adreses_his (
  adr_cd
  ,tips_cd
  ,std
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,std
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_pagasts_his
WHERE to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP > (
    SELECT MAX(dat_mod)
    FROM vzd.adreses_his
    WHERE tips_cd = 105
    );

---Municipalities.
INSERT INTO vzd.adreses_his (
  adr_cd
  ,tips_cd
  ,std
  ,dat_sak
  ,dat_mod
  ,dat_beig
  )
SELECT kods
  ,tips_cd
  ,std
  ,dat_sak::DATE
  ,to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP
  ,CASE 
    WHEN dat_beig LIKE ''
      THEN NULL
    ELSE dat_beig::DATE
    END
FROM vzd.aw_novads_his
WHERE to_timestamp(dat_mod, 'dd.mm.yyyy HH24:MI:SS')::TIMESTAMP > (
    SELECT MAX(dat_mod)
    FROM vzd.adreses_his
    WHERE tips_cd = 113
    );

DELETE
FROM vzd.adreses_his
WHERE adr_cd = adr_cd_his;

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.adreses() FROM PUBLIC;
