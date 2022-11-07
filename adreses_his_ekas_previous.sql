CREATE OR REPLACE PROCEDURE vzd.adreses_his_ekas_previous(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DROP TABLE IF EXISTS vzd.adreses_his_ekas_previous;

CREATE TABLE vzd.adreses_his_ekas_previous (
  adr_cd INTEGER PRIMARY KEY
  ,nosaukums TEXT
  ,nr TEXT
  ,iela TEXT
  );

--Changed address notation (house name/number and street name).
WITH c
AS (
  SELECT id
    ,nosaukums
    ,nr
    ,iela
    ,ciems
    ,pilseta
    ,pagasts
  FROM vzd.adreses_his_ekas_split
  )
  ,b
AS (
  SELECT a.adr_cd
    ,c.nosaukums
    ,c.nr
    ,c.iela
    ,c.ciems
    ,b.dat_beig
  FROM vzd.adreses_ekas_sadalitas a
  INNER JOIN vzd.adreses_his b ON a.adr_cd = b.adr_cd
  INNER JOIN c ON b.id = c.id
  WHERE COALESCE(LOWER(a.nosaukums), '') NOT LIKE COALESCE(LOWER(c.nosaukums), '')
    OR COALESCE(LOWER(a.nr), '') NOT LIKE COALESCE(LOWER(c.nr), '')
    OR COALESCE(LOWER(a.iela), '') NOT LIKE COALESCE(LOWER(c.iela), '')
    --OR COALESCE(LOWER(a.ciems), '') NOT LIKE COALESCE(LOWER(c.ciems), '')
  )
  ,a
AS (
  SELECT adr_cd
    ,MAX(dat_beig) dat_beig
  FROM b
  GROUP BY adr_cd
  )
  ,a1 --Only one address change per date.
AS (
  SELECT b.adr_cd
  FROM b
  INNER JOIN a ON b.adr_cd = a.adr_cd
    AND b.dat_beig = a.dat_beig
  GROUP BY b.adr_cd
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_previous
SELECT b.adr_cd
  ,b.nosaukums
  ,b.nr
  ,b.iela
--,b.ciems
FROM b
INNER JOIN a ON b.adr_cd = a.adr_cd
  AND b.dat_beig = a.dat_beig
INNER JOIN a1 ON b.adr_cd = a1.adr_cd;
--WHERE (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', a.dat_beig)) * 12 + (DATE_PART('month', CURRENT_DATE) - DATE_PART('month', a.dat_beig)) <= 3--Address changed within last three months.

--Address previously assigned to multiple objects. In case of multiple matching addresses, none are used.
---Address notation current.
WITH a
AS (
  SELECT a.adr_cd
    ,a.adr_cd_his
    ,b.nosaukums
    ,b.nr
    ,b.iela
    ,b.ciems
  FROM vzd.adreses_his a
  INNER JOIN vzd.adreses_ekas_sadalitas b ON a.adr_cd_his = b.adr_cd
  WHERE a.dat_beig IS NULL
    --AND (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', a.dat_sak)) * 12 + (DATE_PART('month', CURRENT_DATE) - DATE_PART('month', a.dat_sak)) <= 3 --Address changed within last three months.
  )
  /*,b --In case of multiple matching addresses, use only the newest.
AS (
  SELECT a.adr_cd
    ,MAX(c.dat_sak) dat_sak
  FROM a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  GROUP BY a.adr_cd
  )*/
  ,d
AS (
  SELECT a.adr_cd
  FROM a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  /*INNER JOIN b ON a.adr_cd = b.adr_cd
    AND c.dat_sak = b.dat_sak*/
  GROUP BY a.adr_cd
    --,b.dat_sak
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_previous
SELECT a.adr_cd
  ,a.nosaukums
  ,a.nr
  ,a.iela
  --,a.ciems
FROM a
INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
/*INNER JOIN b ON a.adr_cd = b.adr_cd
  AND c.dat_sak = b.dat_sak*/
INNER JOIN d ON a.adr_cd = d.adr_cd
WHERE a.adr_cd NOT IN (
    SELECT adr_cd
    FROM vzd.adreses_his_ekas_previous
    );

---Address notation has been changed.
----Date adr_cd_his deleted less or equal, use newest.
WITH a2
AS (
  SELECT adr_cd
    ,MAX(dat_beig) dat_beig
  FROM vzd.adreses_his
  WHERE dat_beig IS NOT NULL
    AND tips_cd = 108
  GROUP BY adr_cd
  )
  ,x
AS (
  SELECT b.adr_cd
    ,MAX(b.dat_beig) dat_beig
  FROM vzd.adreses_his a
  INNER JOIN a2 ON a.adr_cd = a2.adr_cd
    AND a.dat_beig = a2.dat_beig
  INNER JOIN vzd.adreses_his b ON a.adr_cd_his = b.adr_cd
  WHERE b.dat_beig <= a.dat_beig
    AND b.adr_cd_his IS NULL
  GROUP BY b.adr_cd
  )
  ,a
AS (
  SELECT DISTINCT a.adr_cd
    ,a.adr_cd_his
    ,c.nosaukums
    ,c.nr
    ,c.iela
  --,c.ciems
  FROM vzd.adreses_his a
  INNER JOIN a2 ON a.adr_cd = a2.adr_cd
    AND a.dat_beig = a2.dat_beig
  INNER JOIN vzd.adreses_his b ON a.adr_cd_his = b.adr_cd
  INNER JOIN x ON b.adr_cd = x.adr_cd
    AND b.dat_beig = x.dat_beig
  INNER JOIN vzd.adreses_his_ekas_split c ON b.id = c.id
  WHERE b.adr_cd_his IS NULL
    --AND (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', a.dat_sak)) * 12 + (DATE_PART('month', CURRENT_DATE) - DATE_PART('month', a.dat_sak)) <= 3 --Address changed within last three months.
  )
  /*,b --In case of multiple matching addresses, use only the newest.
AS (
  SELECT a.adr_cd
    ,MAX(c.dat_sak) dat_sak
  FROM a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  GROUP BY a.adr_cd
  )*/
  ,d2
AS (
  SELECT DISTINCT adr_cd
    ,adr_cd_his
  FROM vzd.adreses_his
  WHERE dat_beig IS NOT NULL
    AND tips_cd = 108
  )
  ,d
AS (
  SELECT a.adr_cd
  FROM d2 a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  /*INNER JOIN b ON a.adr_cd = b.adr_cd
    AND c.dat_sak = b.dat_sak*/
  GROUP BY a.adr_cd
    --,b.dat_sak
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_previous
SELECT a.adr_cd
  ,a.nosaukums
  ,a.nr
  ,a.iela
  --,a.ciems
FROM a
INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
/*INNER JOIN b ON a.adr_cd = b.adr_cd
  AND c.dat_sak = b.dat_sak*/
INNER JOIN d ON a.adr_cd = d.adr_cd
WHERE a.adr_cd NOT IN (
    SELECT adr_cd
    FROM vzd.adreses_his_ekas_previous
    );

----Date adr_cd_his deleted greater, use oldest.
WITH a2
AS (
  SELECT adr_cd
    ,MAX(dat_beig) dat_beig
  FROM vzd.adreses_his
  WHERE dat_beig IS NOT NULL
    AND tips_cd = 108
  GROUP BY adr_cd
  )
  ,x
AS (
  SELECT b.adr_cd
    ,MIN(b.dat_beig) dat_beig
  FROM vzd.adreses_his a
  INNER JOIN a2 ON a.adr_cd = a2.adr_cd
    AND a.dat_beig = a2.dat_beig
  INNER JOIN vzd.adreses_his b ON a.adr_cd_his = b.adr_cd
  WHERE b.dat_beig > a.dat_beig
    AND b.adr_cd_his IS NULL
  GROUP BY b.adr_cd
  )
  ,a
AS (
  SELECT DISTINCT a.adr_cd
    ,a.adr_cd_his
    ,c.nosaukums
    ,c.nr
    ,c.iela
  --,c.ciems
  FROM vzd.adreses_his a
  INNER JOIN a2 ON a.adr_cd = a2.adr_cd
    AND a.dat_beig = a2.dat_beig
  INNER JOIN vzd.adreses_his b ON a.adr_cd_his = b.adr_cd
  INNER JOIN x ON b.adr_cd = x.adr_cd
    AND b.dat_beig = x.dat_beig
  INNER JOIN vzd.adreses_his_ekas_split c ON b.id = c.id
  WHERE b.adr_cd_his IS NULL
    --AND (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', a.dat_sak)) * 12 + (DATE_PART('month', CURRENT_DATE) - DATE_PART('month', a.dat_sak)) <= 3 --Address changed within last three months.
  )
  /*,b --In case of multiple matching addresses, use only the newest.
AS (
  SELECT a.adr_cd
    ,MAX(c.dat_sak) dat_sak
  FROM a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  GROUP BY a.adr_cd
  )*/
  ,d2
AS (
  SELECT DISTINCT adr_cd
    ,adr_cd_his
  FROM vzd.adreses_his
  WHERE dat_beig IS NOT NULL
    AND tips_cd = 108
  )
  ,d
AS (
  SELECT a.adr_cd
  FROM d2 a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  /*INNER JOIN b ON a.adr_cd = b.adr_cd
    AND c.dat_sak = b.dat_sak*/
  GROUP BY a.adr_cd
    --,b.dat_sak
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_previous
SELECT a.adr_cd
  ,a.nosaukums
  ,a.nr
  ,a.iela
  --,a.ciems
FROM a
INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
/*INNER JOIN b ON a.adr_cd = b.adr_cd
  AND c.dat_sak = b.dat_sak*/
INNER JOIN d ON a.adr_cd = d.adr_cd
WHERE a.adr_cd NOT IN (
    SELECT adr_cd
    FROM vzd.adreses_his_ekas_previous
    );

----adr_cd_his not in vzd.adreses_his.
WITH a
AS (
  SELECT DISTINCT a.adr_cd
    ,a.adr_cd_his
    ,b.nosaukums
    ,b.nr
    ,b.iela
    ,b.ciems
  FROM vzd.adreses_his a
  INNER JOIN vzd.adreses_ekas_sadalitas b ON a.adr_cd_his = b.adr_cd
  LEFT OUTER JOIN vzd.adreses_his c ON a.adr_cd_his = c.adr_cd
  WHERE a.dat_beig IS NOT NULL
    AND c.adr_cd IS NULL
    OR (
      c.adr_cd IS NOT NULL
      AND c.adr_cd_his IS NOT NULL
      )
    --AND (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', a.dat_sak)) * 12 + (DATE_PART('month', CURRENT_DATE) - DATE_PART('month', a.dat_sak)) <= 3 --Address changed within last three months.
  )
  /*,b --In case of multiple matching addresses, use only the newest.
AS (
  SELECT a.adr_cd
    ,MAX(c.dat_sak) dat_sak
  FROM a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  GROUP BY a.adr_cd
  )*/
  ,d2
AS (
  SELECT DISTINCT adr_cd
    ,adr_cd_his
  FROM vzd.adreses_his
  WHERE dat_beig IS NOT NULL
    AND tips_cd = 108
  )
  ,d
AS (
  SELECT a.adr_cd
  FROM d2 a
  INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
  /*INNER JOIN b ON a.adr_cd = b.adr_cd
    AND c.dat_sak = b.dat_sak*/
  GROUP BY a.adr_cd
    --,b.dat_sak
  HAVING COUNT(*) = 1
  )
INSERT INTO vzd.adreses_his_ekas_previous
SELECT a.adr_cd
  ,a.nosaukums
  ,a.nr
  ,a.iela
  --,a.ciems
FROM a
INNER JOIN vzd.adreses c ON a.adr_cd_his = c.adr_cd
/*INNER JOIN b ON a.adr_cd = b.adr_cd
  AND c.dat_sak = b.dat_sak*/
INNER JOIN d ON a.adr_cd = d.adr_cd
WHERE a.adr_cd NOT IN (
    SELECT adr_cd
    FROM vzd.adreses_his_ekas_previous
    );

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.adreses_his_ekas_previous() FROM PUBLIC;
