CREATE OR REPLACE PROCEDURE vzd.adreses_his_ekas_split(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

/*
DROP TABLE IF EXISTS vzd.adreses_his_ekas_split;

CREATE TABLE vzd.adreses_his_ekas_split (
  id INT NOT NULL PRIMARY KEY
  ,nosaukums TEXT
  ,nr TEXT
  ,iela TEXT
  ,ciems TEXT
  ,pilseta TEXT
  ,pagasts TEXT
  ,novads TEXT
  ,rajons TEXT
  );

COMMENT ON TABLE vzd.adreses_his_ekas_split IS 'Adrešu vēsturiskie pieraksti sadalīti pa laukiem.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.id IS 'ID.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.nosaukums IS 'Ēkas nosaukums.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.nr IS 'Ēkas Nr.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.iela IS 'Ielas nosaukums.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.ciems IS 'Ciema/mazciema nosaukums.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.pilseta IS 'Pilsētas nosaukums.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.pagasts IS 'Pagasta nosaukums.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.novads IS 'Novada nosaukums.';

COMMENT ON COLUMN vzd.adreses_his_ekas_split.rajons IS 'Rajona nosaukums.';
*/

--Temporary table with corrected beginnig dates to match the creation date of an address notation instead of an addressation object.
CREATE TEMPORARY TABLE adreses_his_dat_sak AS
SELECT id
  ,adr_cd
  ,adr_cd_his
  ,tips_cd
  ,std
  ,COALESCE(LAG(dat_beig) OVER (
      PARTITION BY adr_cd ORDER BY dat_beig
        ,dat_mod
      ) + 1, dat_sak) dat_sak
  ,dat_mod
  ,dat_beig
FROM vzd.adreses_his;

--Correct entries where postal code doesn't have prefix "LV-".
UPDATE adreses_his_dat_sak
SET std = LEFT(std, LENGTH(std) - 4) || 'LV-' || RIGHT(std, 4)
WHERE std NOT LIKE '%, LV-%'
  AND RIGHT(std, 4) ~ '^[0-9]*$';

--Temporary table with upper addressation objects.
CREATE TEMPORARY TABLE adreses_his_upper AS
SELECT tips_cd
  ,std
  ,NULL::DATE dat_sak
  ,NULL::DATE dat_beig
FROM vzd.adreses_his
WHERE tips_cd NOT IN (
    109
    ,108
    ,107
    )

UNION

SELECT tips_cd
  ,std
  ,NULL::DATE dat_sak
  ,NULL::DATE dat_beig
FROM vzd.adreses
WHERE tips_cd NOT IN (
    109
    ,108
    ,107
    )
  AND (
    statuss NOT LIKE 'ERR'
    OR tips_cd = 106
    );

--Add beginning and end dates to towns and villages with the same address notation. Dates are not used for all entries because in some cases they don't match with lower addressation objects. Due to erroneous beginning dates of lower addressation objects, beginning date of the oldest entry is chosen old enough to include all entries.
UPDATE adreses_his_upper
SET dat_sak = '1918-11-18'
  ,dat_beig = '2021-06-30'
WHERE std LIKE 'Mārupe, Mārupes nov.'
  AND tips_cd = 106;

UPDATE adreses_his_upper
SET dat_sak = '2022-07-01'
WHERE std LIKE 'Mārupe, Mārupes nov.'
  AND tips_cd = 104;

UPDATE adreses_his_upper
SET dat_sak = '1918-11-18'
  ,dat_beig = '2021-06-30'
WHERE std LIKE 'Ādaži, Ādažu nov.'
  AND tips_cd = 106;

UPDATE adreses_his_upper
SET dat_sak = '2022-07-01'
WHERE std LIKE 'Ādaži, Ādažu nov.'
  AND tips_cd = 104;

--Add missing entries.
INSERT INTO adreses_his_upper (
  tips_cd
  ,std
  )
VALUES (
  105
  ,'Aizkraukles pag., Aizkraukles raj.'
  )
  ,(
  105
  ,'Amatas pag., Cēsu raj.'
  )
  ,(
  105
  ,'Ciblas pag., Ludzas raj.'
  )
  ,(
  105
  ,'Kandavas pag., Tukuma raj.'
  )
  ,(
  105
  ,'Krāslavas pag., Krāslavas raj.'
  )
  ,(
  105
  ,'Preiļu pag., Preiļu raj.'
  )
  ,(
  105
  ,'Tērvetes pag., Dobeles raj.'
  )
  ,(
  106
  ,'Aizkraukle, Aizkraukles pag., Aizkraukles raj.'
  )
  ,(
  106
  ,'Aizkraukles muiža, Aizkraukles pag., Aizkraukles raj.'
  )
  ,(
  106
  ,'Aizpuri, Aizkraukles pag., Aizkraukles raj.'
  )
  ,(
  106
  ,'Anspoki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Babri, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Balalaiki, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Barisi, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Beči, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Briškas, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Buki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Cibla, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Cimoškas, Krāslavas pag., Krāslavas raj.'
  )
  ,(
  106
  ,'Ciši, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Dambīši, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Dzeņkalns, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Dzervaniški, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Eversmuiža, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Ezerkalns, Krāslavas pag., Krāslavas raj.'
  )
  ,(
  106
  ,'Felicianova, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Gavarčiki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Greči, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Gribuški, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Ģikši, Amatas pag., Cēsu raj.'
  )
  ,(
  106
  ,'Ivdrīši, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Jaunsaimnieki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Jermaki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Jurāni, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Kondrati, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Korsikova, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Kozlovski, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Krapiški, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Krejāni, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Kroņauce, Tērvetes pag., Dobeles raj.'
  )
  ,(
  106
  ,'Kumbuļi'
  )
  ,(
  106
  ,'Lielie Leiči, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Lielie Mūrnieki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Lielie Pupāji, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Lielie Trukšāni, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Lielie Urči, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Liepas, Kandavas pag., Tukuma raj.'
  )
  ,(
  106
  ,'Litavnieki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Līči, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Maļinovka, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Mazie Gavari, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Mazie Leiči, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Mazie Mūrnieki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Mazie Pupāji, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Meža Kocki, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Mjaiši, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Morozovka, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Moskvina, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Nīcgale'
  )
  ,(
  106
  ,'Noviki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Otrie Bluzmi, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Ozupiene, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Papardes, Aizkraukles pag., Aizkraukles raj.'
  )
  ,(
  106
  ,'Pastari, Krāslavas pag., Krāslavas raj.'
  )
  ,(
  106
  ,'Pelši, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Pirmie Bluzmi, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Placinski, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Plivdas, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Polockieši, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Rubeņi, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Rumpīši, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Runči, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Rūmene, Kandavas pag., Tukuma raj.'
  )
  ,(
  106
  ,'Sanauža, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Seiļi, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Skrini, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Sondori, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Stocinova, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Šoldri, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Tērvete, Tērvetes pag., Dobeles raj.'
  )
  ,(
  106
  ,'Tridņa, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Tumova, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Upenieki, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Vacumnieki, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Vaivodi, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Vilcāni, Preiļu pag., Preiļu raj.'
  )
  ,(
  106
  ,'Višķi'
  )
  ,(
  106
  ,'Voloji, Ciblas pag., Ludzas raj.'
  )
  ,(
  106
  ,'Zeltiņi, Ciblas pag., Ludzas raj.'
  );

--Special case with a comma in the house name.
INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nosaukums
  ,ciems
  ,novads
  ,rajons
  )
SELECT a.id
  ,LEFT(a.std, STRPOS(a.std, ', Baltezers') - 1)
  ,'Baltezers'
  ,'Garkalnes nov.'
  ,'Rīgas raj.'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE a.std LIKE '"%,%", Baltezers, Garkalnes nov., Rīgas raj.%'
  AND a.tips_cd = 108
  AND x.id IS NULL;

--House names (in quotation marks).
WITH x
AS (
  SELECT DISTINCT a.id
    ,LEFT(a.std, STRPOS(a.std, '", ')) nosaukums
    ,NULL nr
    ,NULL iela
    ,CASE 
      WHEN b.tips_cd = 106
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      ELSE NULL
      END ciems
    ,CASE 
      WHEN b.tips_cd = 104
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 104
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN f.nosaukums IS NOT NULL
        THEN f.nosaukums
      ELSE NULL
      END pilseta
    ,CASE 
      WHEN b.tips_cd = 105
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 105
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      ELSE NULL
      END pagasts
    ,CASE 
      WHEN b.tips_cd = 113
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 113
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN d.tips_cd = 113
        THEN REPLACE(LEFT(d.std, COALESCE(NULLIF(STRPOS(d.std, ','), 0), LENGTH(d.std))), ',', '')
      ELSE NULL
      END novads
    ,CASE 
      WHEN c.tips_cd = 102
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN d.tips_cd = 102
        THEN REPLACE(LEFT(d.std, COALESCE(NULLIF(STRPOS(d.std, ','), 0), LENGTH(d.std))), ',', '')
      WHEN e.tips_cd = 102
        THEN REPLACE(LEFT(e.std, COALESCE(NULLIF(STRPOS(e.std, ','), 0), LENGTH(e.std))), ',', '')
      ELSE NULL
      END rajons
  FROM adreses_his_dat_sak a
  LEFT JOIN adreses_his_upper b ON RIGHT(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std))), LENGTH(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std)))) - STRPOS(a.std, '", ') - 2) = b.std
    AND (
      a.dat_sak >= b.dat_sak
      OR b.dat_sak IS NULL
      )
    AND (
      a.dat_beig <= b.dat_beig
      OR b.dat_beig IS NULL
      ) --Exclude postal code when linking upper addressation object.
  LEFT JOIN adreses_his_upper c ON RIGHT(b.std, LENGTH(b.std) - STRPOS(b.std, ',') - 1) = c.std
  LEFT JOIN adreses_his_upper d ON RIGHT(c.std, LENGTH(c.std) - STRPOS(c.std, ',') - 1) = d.std
  LEFT JOIN adreses_his_upper e ON RIGHT(d.std, LENGTH(d.std) - STRPOS(d.std, ',') - 1) = e.std
  LEFT JOIN (
    SELECT DISTINCT nosaukums
    FROM vzd.adreses
    WHERE tips_cd = 104
    ) f ON RIGHT(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std))), LENGTH(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std)))) - STRPOS(a.std, ',') - 1) = f.nosaukums --Only names of cities and towns in case they are not included in the field std (included only with upper addressation objects).
  LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
  WHERE a.tips_cd = 108
    AND a.std LIKE '"%", %'
    AND x.id IS NULL
  )
  ,x2
AS (
  SELECT id
  FROM x
  GROUP BY id
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_split
SELECT x.*
FROM x
INNER JOIN x2 ON x.id = x2.id;

--Special cases with streets and non-standard erroneous notation.
INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nr
  ,iela
  ,ciems
  ,pagasts
  ,rajons
  )
SELECT a.id
  ,LEFT(a.std, STRPOS(a.std, ', ') - 1)
  ,'Ziemeļu iela'
  ,'Vārzas'
  ,'Skultes pag.'
  ,'Limbažu raj.'
FROM vzd.adreses_his a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE '%, Ziemeļu iela, Vārzas, Skultes pag., Limbažu raj.%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nr
  ,iela
  ,pilseta
  ,rajons
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) + 2, STRPOS(a.std, ', Kuldīga') - LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) - 2)
  ,LEFT(a.std, STRPOS(a.std, ' iela') + 4)
  ,'Kuldīga'
  ,'Kuldīgas raj.'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE '%iela%,%, Kuldīga, Kuldīgas raj.%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nr
  ,iela
  ,pilseta
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH('Klusā iela ') + 1, STRPOS(a.std, ', Daugavpils') - LENGTH('Klusā iela ') - 1)
  ,'Klusā iela'
  ,'Daugavpils'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE 'Klusā iela%,%, Daugavpils%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nr
  ,iela
  ,ciems
  ,pagasts
  ,novads
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) + 2, STRPOS(a.std, ', Saulstari') - LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) - 2)
  ,LEFT(a.std, STRPOS(a.std, ' iela') + 4)
  ,'Saulstari, Ķekava'
  ,'Ķekavas pag.'
  ,'Ķekavas nov.'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE '%iela%, Saulstari, Ķekava, Ķekavas pag., Ķekavas nov.%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nr
  ,iela
  ,ciems
  ,pagasts
  ,novads
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) + 2, STRPOS(a.std, ', Zilgmes') - LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) - 2)
  ,LEFT(a.std, STRPOS(a.std, ' iela') + 4)
  ,'Zilgmes, Ķekava'
  ,'Ķekavas pag.'
  ,'Ķekavas nov.'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE '%iela%, Zilgmes, Ķekava, Ķekavas pag., Ķekavas nov.%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nr
  ,iela
  ,ciems
  ,pagasts
  ,rajons
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) + 2, STRPOS(a.std, ', Saulstari') - LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) - 2)
  ,LEFT(a.std, STRPOS(a.std, ' iela') + 4)
  ,'Saulstari, Ķekava'
  ,'Ķekavas pag.'
  ,'Rīgas raj.'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE '%iela%, Saulstari, Ķekava, Ķekavas pag., Rīgas raj.%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nr
  ,iela
  ,ciems
  ,pagasts
  ,rajons
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) + 2, STRPOS(a.std, ', Zilgmes') - LENGTH(LEFT(a.std, STRPOS(a.std, ' iela') + 4)) - 2)
  ,LEFT(a.std, STRPOS(a.std, ' iela') + 4)
  ,'Zilgmes, Ķekava'
  ,'Ķekavas pag.'
  ,'Rīgas raj.'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE '%iela%, Zilgmes, Ķekava, Ķekavas pag., Rīgas raj.%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

--With streets.
WITH n (nosaukums)
AS (
  VALUES ('aleja')
    ,('apvedceļš')
    ,('bulvāris')
    ,('ceļš')
    ,('ciemats')
    ,('dambis')
    ,('gatve')
    ,('gāte')
    ,('iela')
    ,('krastmala')
    ,('laukums')
    ,('līnija')
    ,('maģistrāle')
    ,('mols')
    ,('perons')
    ,('prospekts')
    ,('sala')
    ,('skvērs')
    ,('stacija')
    ,('sēta')
    ,('šoseja')
    ,('šķērsiela')
    ,('šķērslīnija')
    ,('grava')
    ,('dārzs')
    ,('stūris')
    ,('parks')
    ,('tirgus')
    ,('piekraste')
    ,('valnis')
    ,('taka')
  )
  ,x
AS (
  SELECT DISTINCT a.id
    ,STRPOS(LOWER(a.std), ' ' || n.nosaukums || ' ') n_pos
    ,SUBSTRING(a.std, STRPOS(LOWER(a.std), ' ' || n.nosaukums || ' ') + LENGTH(n.nosaukums) + 2, STRPOS(a.std, ', ') - STRPOS(LOWER(a.std), ' ' || n.nosaukums || ' ') - LENGTH(n.nosaukums) - 2) nr
    ,LEFT(a.std, STRPOS(LOWER(a.std), ' ' || n.nosaukums || ' ') + LENGTH(n.nosaukums)) iela
    ,CASE 
      WHEN b.tips_cd = 106
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      ELSE NULL
      END ciems
    ,CASE 
      WHEN b.tips_cd = 104
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 104
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN f.nosaukums IS NOT NULL
        THEN f.nosaukums
      ELSE NULL
      END pilseta
    ,CASE 
      WHEN b.tips_cd = 105
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 105
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      ELSE NULL
      END pagasts
    ,CASE 
      WHEN b.tips_cd = 113
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 113
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN d.tips_cd = 113
        THEN REPLACE(LEFT(d.std, COALESCE(NULLIF(STRPOS(d.std, ','), 0), LENGTH(d.std))), ',', '')
      ELSE NULL
      END novads
    ,CASE 
      WHEN c.tips_cd = 102
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN d.tips_cd = 102
        THEN REPLACE(LEFT(d.std, COALESCE(NULLIF(STRPOS(d.std, ','), 0), LENGTH(d.std))), ',', '')
      WHEN e.tips_cd = 102
        THEN REPLACE(LEFT(e.std, COALESCE(NULLIF(STRPOS(e.std, ','), 0), LENGTH(e.std))), ',', '')
      ELSE NULL
      END rajons
  FROM adreses_his_dat_sak a
  LEFT JOIN adreses_his_upper b ON RIGHT(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std))), LENGTH(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std)))) - STRPOS(a.std, ', ') - 1) = b.std
    AND (
      a.dat_sak >= b.dat_sak
      OR b.dat_sak IS NULL
      )
    AND (
      a.dat_beig <= b.dat_beig
      OR b.dat_beig IS NULL
      ) --Exclude postal code when linking upper addressation object.
  LEFT JOIN adreses_his_upper c ON RIGHT(b.std, LENGTH(b.std) - STRPOS(b.std, ',') - 1) = c.std
  LEFT JOIN adreses_his_upper d ON RIGHT(c.std, LENGTH(c.std) - STRPOS(c.std, ',') - 1) = d.std
  LEFT JOIN adreses_his_upper e ON RIGHT(d.std, LENGTH(d.std) - STRPOS(d.std, ',') - 1) = e.std
  LEFT JOIN (
    SELECT DISTINCT nosaukums
    FROM vzd.adreses
    WHERE tips_cd = 104
    ) f ON RIGHT(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std))), LENGTH(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std)))) - STRPOS(a.std, ',') - 1) = f.nosaukums --Only names of cities and towns in case they are not included in the field std (included only with upper addressation objects).
  CROSS JOIN n
  LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
  WHERE a.tips_cd = 108
    AND LOWER(a.std) LIKE '% ' || n.nosaukums || ' %'
    AND (
      LOWER(b.std) NOT LIKE '% ' || n.nosaukums || ' %'
      OR b.std IS NULL
      )
    AND a.std NOT LIKE '"%", %'
    AND x.id IS NULL
  )
  ,x2
AS (
  SELECT id
    ,MIN(n_pos) n_pos
  FROM x
  GROUP BY id
  )
  ,x3
AS (
  SELECT x.id
    ,NULL nosaukums
    ,x.nr
    ,x.iela
    ,x.ciems
    ,x.pilseta
    ,x.pagasts
    ,x.novads
    ,x.rajons
  FROM x
  INNER JOIN x2 ON x.id = x2.id
    AND x.n_pos = x2.n_pos
  )
  ,x4
AS (
  SELECT id
  FROM x3
  GROUP BY id
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_split
SELECT x3.*
FROM x3
INNER JOIN x4 ON x3.id = x4.id;

--Streets without nomenclature names.
WITH x
AS (
  SELECT DISTINCT a.id
    ,NULL nosaukums
    ,SUBSTRING(a.std, STRPOS(a.std, (REGEXP_MATCHES(a.std, ' \d+')) [1]) + 1, STRPOS(a.std, ', ') - STRPOS(a.std, (REGEXP_MATCHES(a.std, ' \d+')) [1]) - 1) nr
    ,LEFT(a.std, STRPOS(a.std, (REGEXP_MATCHES(a.std, ' \d+')) [1]) - 1) iela
    ,CASE 
      WHEN b.tips_cd = 106
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      ELSE NULL
      END ciems
    ,CASE 
      WHEN b.tips_cd = 104
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 104
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN f.nosaukums IS NOT NULL
        THEN f.nosaukums
      ELSE NULL
      END pilseta
    ,CASE 
      WHEN b.tips_cd = 105
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 105
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      ELSE NULL
      END pagasts
    ,CASE 
      WHEN b.tips_cd = 113
        THEN REPLACE(LEFT(b.std, COALESCE(NULLIF(STRPOS(b.std, ','), 0), LENGTH(b.std))), ',', '')
      WHEN c.tips_cd = 113
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN d.tips_cd = 113
        THEN REPLACE(LEFT(d.std, COALESCE(NULLIF(STRPOS(d.std, ','), 0), LENGTH(d.std))), ',', '')
      ELSE NULL
      END novads
    ,CASE 
      WHEN c.tips_cd = 102
        THEN REPLACE(LEFT(c.std, COALESCE(NULLIF(STRPOS(c.std, ','), 0), LENGTH(c.std))), ',', '')
      WHEN d.tips_cd = 102
        THEN REPLACE(LEFT(d.std, COALESCE(NULLIF(STRPOS(d.std, ','), 0), LENGTH(d.std))), ',', '')
      WHEN e.tips_cd = 102
        THEN REPLACE(LEFT(e.std, COALESCE(NULLIF(STRPOS(e.std, ','), 0), LENGTH(e.std))), ',', '')
      ELSE NULL
      END rajons
  FROM adreses_his_dat_sak a
  LEFT JOIN adreses_his_upper b ON RIGHT(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std))), LENGTH(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std)))) - STRPOS(a.std, ', ') - 1) = b.std
  AND (
    a.dat_sak >= b.dat_sak
    OR b.dat_sak IS NULL
    )
  AND (
    a.dat_beig <= b.dat_beig
    OR b.dat_beig IS NULL
    ) --Exclude postal code when linking upper addressation object.
  LEFT JOIN adreses_his_upper c ON RIGHT(b.std, LENGTH(b.std) - STRPOS(b.std, ',') - 1) = c.std
  LEFT JOIN adreses_his_upper d ON RIGHT(c.std, LENGTH(c.std) - STRPOS(c.std, ',') - 1) = d.std
  LEFT JOIN adreses_his_upper e ON RIGHT(d.std, LENGTH(d.std) - STRPOS(d.std, ',') - 1) = e.std
  LEFT JOIN (
    SELECT DISTINCT nosaukums
    FROM vzd.adreses
    WHERE tips_cd = 104
    ) f ON RIGHT(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std))), LENGTH(LEFT(a.std, COALESCE(NULLIF(STRPOS(a.std, 'LV-') - 3, - 3), LENGTH(a.std)))) - STRPOS(a.std, ',') - 1) = f.nosaukums --Only names of cities and towns in case they are not included in the field std (included only with upper addressation objects).
  LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
  WHERE a.tips_cd = 108
    AND x.id IS NULL
  )
  ,x2
AS (
  SELECT id
  FROM x
  GROUP BY id
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_split
SELECT x.*
FROM x
INNER JOIN x2 ON x.id = x2.id;

--Special cases when streets with nomenclature names have house names instead of numbers.
INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nosaukums
  ,iela
  ,ciems
  ,pagasts
  ,rajons
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH('Iela uz attīrīšanas iekārtām ') + 1, STRPOS(a.std, ',') - LENGTH('Iela uz attīrīšanas iekārtām ') - 1)
  ,'Iela uz attīrīšanas iekārtām'
  ,'Renda'
  ,'Rendas pag.'
  ,'Kuldīgas raj.'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE 'Iela uz attīrīšanas iekārtām %, Renda, Rendas pag., Kuldīgas raj.%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

INSERT INTO vzd.adreses_his_ekas_split (
  id
  ,nosaukums
  ,iela
  ,pilseta
  )
SELECT a.id
  ,SUBSTRING(a.std, LENGTH('Vakarbuļļi ') + 1, STRPOS(a.std, ',') - LENGTH('Vakarbuļļi ') - 1)
  ,'Vakarbuļļi'
  ,'Rīga'
FROM adreses_his_dat_sak a
LEFT JOIN vzd.adreses_his_ekas_split x ON a.id = x.id
WHERE std LIKE 'Vakarbuļļi %, Rīga%'
  AND x.id IS NULL
  AND a.tips_cd = 108;

--Remove quatation marks from house names.
UPDATE vzd.adreses_his_ekas_split
SET nosaukums = SUBSTRING(nosaukums, 2, LENGTH(nosaukums) - 2)
WHERE nosaukums LIKE '"%"';

--Trim and replace multiple consecutive whitespaces with single ones.
UPDATE vzd.adreses_his_ekas_split
SET nosaukums = TRIM(regexp_replace(nosaukums, '\s+', ' ', 'g'));

UPDATE vzd.adreses_his_ekas_split
SET nr = TRIM(regexp_replace(nr, '\s+', ' ', 'g'));

UPDATE vzd.adreses_his_ekas_split
SET iela = TRIM(regexp_replace(iela, '\s+', ' ', 'g'));

UPDATE vzd.adreses_his_ekas_split
SET ciems = TRIM(regexp_replace(ciems, '\s+', ' ', 'g'));

UPDATE vzd.adreses_his_ekas_split
SET pilseta = TRIM(regexp_replace(pilseta, '\s+', ' ', 'g'));

UPDATE vzd.adreses_his_ekas_split
SET pagasts = TRIM(regexp_replace(pagasts, '\s+', ' ', 'g'));

UPDATE vzd.adreses_his_ekas_split
SET novads = TRIM(regexp_replace(novads, '\s+', ' ', 'g'));

UPDATE vzd.adreses_his_ekas_split
SET rajons = TRIM(regexp_replace(rajons, '\s+', ' ', 'g'));

--Correct typos.
UPDATE vzd.adreses_his_ekas_split
SET nr = REPLACE(nr, ' K-', ' k-')
WHERE nr LIKE '% K-%';

UPDATE vzd.adreses_his_ekas_split
SET nosaukums = REPLACE(nosaukums, ' K-', ' k-')
WHERE nosaukums LIKE '% K-%';

---In numbers, remove space between number and letter.
UPDATE vzd.adreses_his_ekas_split
SET nr = REPLACE(nr, ' ', '')
WHERE (nr ~ '^\d+\s[A-Z]$');

UPDATE vzd.adreses_his_ekas_split
SET nosaukums = REPLACE(nr, ' ', '')
WHERE (nosaukums ~ '^\d+\s[A-Z]$');

--House name looks like a number, move it to "nr".
UPDATE vzd.adreses_his_ekas_split
SET nr = nosaukums
  ,nosaukums = NULL
WHERE iela IS NULL
  AND nosaukums NOT LIKE '% %'
  AND (nosaukums ~ '^-?[0-9]*.?[0-9]*$') = true
  AND (nosaukums ~ '^[a-zA-Z]+$') = false;

--Number contains street name, delete it from the number.
UPDATE vzd.adreses_his_ekas_split
SET nr = LTRIM(RIGHT(nr, LENGTH(nr) - LENGTH(iela)))
WHERE LEFT(nr, LENGTH(iela)) LIKE iela;

--Number starts with a letter, move it to "nosaukums".
UPDATE vzd.adreses_his_ekas_split
SET nosaukums = nr
  ,nr = NULL
WHERE iela IS NOT NULL
  AND nr NOT LIKE '%hip.%'
  AND (nr ~ '^[a-zA-Z]+') = true
  AND (nr ~ '^[a-zA-Z]+-[0-9]+$') = false
  AND (nr ~ '^[a-zA-Z]+[0-9]+$') = false;

UPDATE vzd.adreses_his_ekas_split
SET nosaukums = nr
  ,nr = NULL
WHERE iela IS NOT NULL
  AND nr NOT LIKE '%hip.%'
  AND (nr ~ '^[ā-žĀ-Ž]+') = true
  AND (nr ~ '^[ā-žĀ-Ž]+-[0-9]+$') = false
  AND (nr ~ '^[ā-žĀ-Ž]+[0-9]+$') = false;

--Number contains "km" or "gada parks", move it to "nosaukums".
UPDATE vzd.adreses_his_ekas_split
SET nosaukums = nr
  ,nr = NULL
WHERE iela IS NOT NULL
  AND (
    nr LIKE '%km%'
    OR nr LIKE '%gada parks%'
    );

/*
--Select various non-standard erroneous cases left as "nr".
SELECT *
FROM vzd.adreses_his_ekas_split
WHERE iela IS NOT NULL
  AND nr NOT LIKE '% k-%'
  AND nr NOT LIKE '%/%'
  --AND nr NOT LIKE '%hip.%'
  --AND nr NOT LIKE '%lit.%'
  AND (nr ~ '^-?[0-9]*.?[0-9]*$') = false
ORDER BY nr DESC;
*/

/*
--Check for remaining entries that haven't been splitted.
SELECT *
FROM vzd.adreses_his a
LEFT JOIN vzd.adreses_his_ekas_split b ON a.id = b.id
WHERE a.tips_cd = 108
  AND b.id IS NULL;
*/

/*
--Check for missing upper addressation objects.
SELECT a.*
  ,b.std
FROM vzd.adreses_his_ekas_split a
INNER JOIN vzd.adreses_his b ON a.id = b.id
WHERE --ciems IS NULL AND
  pilseta IS NULL
  AND pagasts IS NULL
  AND novads IS NULL
  AND rajons IS NULL
ORDER BY b.std;
*/

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.adreses_his_ekas_split() FROM PUBLIC;
