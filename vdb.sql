CREATE OR REPLACE PROCEDURE lgia.vdb(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$
BEGIN

SET datestyle = 'German';

DROP TABLE IF EXISTS lgia.forma
  ,lgia.vdb;

CREATE TABLE lgia.forma (
  id SMALLINT NOT NULL PRIMARY KEY
  ,forma TEXT
  );

CREATE TABLE lgia.vdb (
  objektaid INTEGER NOT NULL PRIMARY KEY
  ,pamatnosaukums TEXT NOT NULL
  ,pamatnosaukums2 TEXT
  ,stavoklis TEXT NOT NULL
  ,atkkods TEXT NOT NULL
  ,veids TEXT NOT NULL
  ,oficials_nosaukums TEXT
  ,oficials_avots TEXT
  ,nosaukumaid INTEGER NOT NULL
  ,nosaukums TEXT NOT NULL
  ,izskana TEXT
  ,galvenais SMALLINT NOT NULL
  ,izruna TEXT
  ,pardevets TEXT
  ,sakumalaiks TEXT
  ,beigulaiks TEXT
  ,lietosanasvide TEXT
  ,lietosanasbiezums TEXT
  ,komentari TEXT
  ,kartesnos BOOLEAN NOT NULL
  ,visi_nos TEXT []
  ,oficials BOOLEAN NOT NULL
  ,forma SMALLINT
  ,geom geometry(Point, 4326) NOT NULL
  ,datumsizm TIMESTAMP NOT NULL
  );

INSERT INTO lgia.forma
SELECT DISTINCT formasid::SMALLINT
  ,forma
FROM lgia.vdb_orig
WHERE formasid != '6'
ORDER BY formasid::SMALLINT;

INSERT INTO lgia.vdb (
  objektaid
  ,pamatnosaukums
  ,pamatnosaukums2
  ,stavoklis
  ,atkkods
  ,veids
  ,oficials_nosaukums
  ,oficials_avots
  ,nosaukumaid
  ,nosaukums
  ,izskana
  ,galvenais
  ,izruna
  ,pardevets
  ,sakumalaiks
  ,beigulaiks
  ,lietosanasvide
  ,lietosanasbiezums
  ,komentari
  ,kartesnos
  ,visi_nos
  ,oficials
  ,forma
  ,geom
  ,datumsizm
  )
SELECT objektaid::INT
  ,TRIM(pamatnosaukums)
  ,CASE 
    WHEN TRIM(pamatnosaukums2) = ''
      THEN NULL
    ELSE TRIM(pamatnosaukums2)
    END
  ,stavoklis
  ,atkkods
  ,veids
  ,CASE 
    WHEN TRIM(oficials_nosaukums) = ''
      THEN NULL
    ELSE TRIM(oficials_nosaukums)
    END
  ,CASE 
    WHEN oficials_avots = ''
      THEN NULL
    ELSE oficials_avots
    END
  ,nosaukumaid::INT
  ,TRIM(nosaukums)
  ,CASE 
    WHEN TRIM(izskana) = ''
      THEN NULL
    ELSE TRIM(izskana)
    END
  ,galvenais::SMALLINT
  ,CASE 
    WHEN izruna = ''
      OR izruna = '<Null>'
      THEN NULL
    ELSE izruna
    END
  ,CASE 
    WHEN pardevets = ''
      THEN NULL
    ELSE pardevets
    END
  ,CASE 
    WHEN sakumalaiks = ''
      THEN NULL
    ELSE sakumalaiks
    END
  ,CASE 
    WHEN beigulaiks = ''
      THEN NULL
    ELSE beigulaiks
    END
  ,CASE 
    WHEN lietosanasvide = ''
      THEN NULL
    ELSE lietosanasvide
    END
  ,CASE 
    WHEN lietosanasbiezums = ''
      OR lietosanasbiezums = '...'
      THEN NULL
    ELSE lietosanasbiezums
    END
  ,CASE 
    WHEN TRIM(komentari) = ''
      THEN NULL
    ELSE TRIM(komentari)
    END
  ,kartesnos::BOOLEAN
  ,STRING_TO_ARRAY(TRIM(visi_nos), ',')
  ,CASE 
    WHEN oficials = 'Oficiāls'
      THEN true
    ELSE false
    END
  ,CASE 
    WHEN formasid = '6'
      THEN NULL
    ELSE formasid::SMALLINT
    END
  ,ST_SetSRID(ST_MakePoint(geogarums::NUMERIC, geoplatums::NUMERIC), 4326)
  ,REPLACE(datumsizm, ',', '.')::TIMESTAMP
FROM lgia.vdb_orig;

CREATE INDEX vdb_geom_idx ON lgia.vdb USING GIST (geom);

COMMENT ON TABLE lgia.forma IS 'LĢIA Vietvārdu datubāzes formas';

COMMENT ON COLUMN lgia.forma.id IS 'Formas ID';

COMMENT ON COLUMN lgia.forma.forma IS 'Forma';

COMMENT ON TABLE lgia.vdb IS 'LĢIA Vietvārdu datubāze';

COMMENT ON COLUMN lgia.vdb.objektaid IS 'ID';

COMMENT ON COLUMN lgia.vdb.pamatnosaukums IS 'Nosaukums, kas no visiem datubāzē uzkrātajiem ir atzīts par lietošanai vai oficiālai apstiprināšanai (t.sk. neveiksmīgi apstiprināta nosaukuma labošanai) vispiemērotāko atbilstoši Ministru kabineta 10.01.2012. noteikumu Nr. 50 "Vietvārdu informācijas noteikumi" prasībām.';

COMMENT ON COLUMN lgia.vdb.pamatnosaukums2 IS 'Paralēlais pamatnosaukums (ūdenstecēm var būt arī atsevišķa tās posma nosaukums)';

COMMENT ON COLUMN lgia.vdb.stavoklis IS 'Stāvoklis';

COMMENT ON COLUMN lgia.vdb.atkkods IS 'Administratīvi teritoriālās vienības kods (ATVK)';

COMMENT ON COLUMN lgia.vdb.veids IS 'Objekta veids';

COMMENT ON COLUMN lgia.vdb.oficials_nosaukums IS 'Oficiālais nosaukums';

COMMENT ON COLUMN lgia.vdb.oficials_avots IS 'Oficiālā nosaukuma avots';

COMMENT ON COLUMN lgia.vdb.nosaukumaid IS 'Nosaukuma ID';

COMMENT ON COLUMN lgia.vdb.nosaukums IS 'Nosaukums';

COMMENT ON COLUMN lgia.vdb.izskana IS 'Izskaņa';

COMMENT ON COLUMN lgia.vdb.galvenais IS 'Galvenais';

COMMENT ON COLUMN lgia.vdb.izruna IS 'Izruna';

COMMENT ON COLUMN lgia.vdb.pardevets IS 'Pārdēvēts';

COMMENT ON COLUMN lgia.vdb.sakumalaiks IS 'Objekta sākuma laiks';

COMMENT ON COLUMN lgia.vdb.beigulaiks IS 'Objekta beigu laiks';

COMMENT ON COLUMN lgia.vdb.lietosanasvide IS 'Lietošanas vide';

COMMENT ON COLUMN lgia.vdb.lietosanasbiezums IS 'Lietošanas biežums';

COMMENT ON COLUMN lgia.vdb.komentari IS 'Komentāri';

COMMENT ON COLUMN lgia.vdb.kartesnos IS 'Kartes nosaukums';

COMMENT ON COLUMN lgia.vdb.visi_nos IS 'Citi nosaukumi un nosaukumu varianti, nenorādot, kuri ir kļūdaini vai novecojuši.';

COMMENT ON COLUMN lgia.vdb.oficials IS 'Oficiāls';

COMMENT ON COLUMN lgia.vdb.forma IS 'Formas ID';

COMMENT ON COLUMN lgia.vdb.geom IS 'Ģeometrija (punktveida objektu atrašanās vietas, laukumveida objektu aptuvenie centri un ūdensteču ietekas ūdenstilpēs vai citās ūdenstecēs)';
COMMENT ON COLUMN lgia.vdb.datumsizm IS 'Pēdējo izmaiņu datums Vietvārdu datubāzē';

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE lgia.vdb() FROM PUBLIC;