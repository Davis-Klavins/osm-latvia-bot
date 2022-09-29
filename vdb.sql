CREATE OR REPLACE PROCEDURE lgia.vdb(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$
BEGIN

DROP TABLE IF EXISTS lgia.vdb;

CREATE TABLE lgia.vdb (
  objektaid INTEGER NOT NULL PRIMARY KEY
  ,pamatnosaukums TEXT NOT NULL
  ,pamatnosaukums2 TEXT NULL
  ,objekta_veids TEXT NOT NULL
  ,stavoklis TEXT NULL
  ,oficialais_nosaukums TEXT NULL
  ,oficialais_nosaukums_ar TEXT NULL
  ,citi_nosaukumi TEXT [] NULL
  ,galv_pagasts TEXT NOT NULL
  ,galv_novads TEXT NOT NULL
  ,galv_rajons_agrak TEXT NOT NULL
  ,atkkods TEXT NOT NULL
  ,arisid INTEGER NULL
  ,raksturojums TEXT NULL
  ,zinas_par_objektu TEXT NULL
  ,papildus_zinas_par_nosaukumu TEXT NULL
  ,geom geometry(Point, 4326) NOT NULL
  ,izveides_datums TIMESTAMP NOT NULL
  ,pedejo_izmainu_datums TIMESTAMP NOT NULL
  );

INSERT INTO lgia.vdb (
  objektaid
  ,pamatnosaukums
  ,pamatnosaukums2
  ,objekta_veids
  ,stavoklis
  ,oficialais_nosaukums
  ,oficialais_nosaukums_ar
  ,citi_nosaukumi
  ,galv_pagasts
  ,galv_novads
  ,galv_rajons_agrak
  ,atkkods
  ,arisid
  ,raksturojums
  ,zinas_par_objektu
  ,papildus_zinas_par_nosaukumu
  ,geom
  ,izveides_datums
  ,pedejo_izmainu_datums
  )
SELECT objektaid
  ,pamatnosaukums
  ,pamatnosaukums2
  ,objekta_veids
  ,stavoklis
  ,oficialais_nosaukums
  ,oficialais_nosaukums_ar
  ,STRING_TO_ARRAY(citi_nosaukumi, ',')
  ,galv_pagasts
  ,galv_novads
  ,galv_rajons_agrak
  ,atkkods
  ,arisid
  ,TRIM(raksturojums)
  ,TRIM(zinas_par_objektu)
  ,TRIM(papildus_zinas_par_nosaukumu)
  ,ST_SetSRID(ST_MakePoint(geogarums, geoplatums), 4326)
  ,REPLACE(izveides_datums, ',', '.')::TIMESTAMP
  ,REPLACE(pedejo_izmainu_datums, ',', '.')::TIMESTAMP
FROM lgia.vdb_orig;

CREATE INDEX vdb_geom_idx ON lgia.vdb USING GIST (geom);

COMMENT ON TABLE lgia.vdb IS 'LĢIA Vietvārdu datubāze';

COMMENT ON COLUMN lgia.vdb.objektaid IS 'ID';

COMMENT ON COLUMN lgia.vdb.pamatnosaukums IS 'Nosaukums, kas no visiem datubāzē uzkrātajiem ir atzīts par lietošanai vai oficiālai apstiprināšanai (t.sk. neveiksmīgi apstiprināta nosaukuma labošanai) vispiemērotāko atbilstoši Ministru kabineta 10.01.2012. noteikumu Nr. 50 "Vietvārdu informācijas noteikumi" prasībām.';

COMMENT ON COLUMN lgia.vdb.pamatnosaukums2 IS 'Paralēlais pamatnosaukums (ūdenstecēm var būt arī atsevišķa tās posma nosaukums)';

COMMENT ON COLUMN lgia.vdb.objekta_veids IS 'Objekta veids';

COMMENT ON COLUMN lgia.vdb.stavoklis IS 'Stāvoklis';

COMMENT ON COLUMN lgia.vdb.oficialais_nosaukums IS 'Oficiālais nosaukums';

COMMENT ON COLUMN lgia.vdb.oficialais_nosaukums_ar IS 'Oficiālais nosaukums Adrešu reģistrā';

COMMENT ON COLUMN lgia.vdb.citi_nosaukumi IS 'Citi nosaukumi un nosaukumu varianti, nenorādot, kuri ir kļūdaini vai novecojuši.';

COMMENT ON COLUMN lgia.vdb.galv_pagasts IS 'Galvenā pagasta nosaukums';

COMMENT ON COLUMN lgia.vdb.galv_novads IS 'Galvenā novada nosaukums';

COMMENT ON COLUMN lgia.vdb.galv_rajons_agrak IS 'Galvenā rajona nosaukums';

COMMENT ON COLUMN lgia.vdb.atkkods IS 'Administratīvi teritoriālās vienības kods (ATVK)';

COMMENT ON COLUMN lgia.vdb.arisid IS 'Adresācijas objekta kods Adrešu reģistrā';

COMMENT ON COLUMN lgia.vdb.raksturojums IS 'Raksturojums';

COMMENT ON COLUMN lgia.vdb.zinas_par_objektu IS 'Ziņas par objektu';

COMMENT ON COLUMN lgia.vdb.papildus_zinas_par_nosaukumu IS 'Papildus ziņas par nosaukumu';

COMMENT ON COLUMN lgia.vdb.geom IS 'Ģeometrija (punktveida objektu atrašanās vietas, laukumveida objektu aptuvenie centri un ūdensteču ietekas ūdenstilpēs vai citās ūdenstecēs)';

COMMENT ON COLUMN lgia.vdb.izveides_datums IS 'Izveides datums Vietvārdu datubāzē';

COMMENT ON COLUMN lgia.vdb.pedejo_izmainu_datums IS 'Pēdējo izmaiņu datums Vietvārdu datubāzē';

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE lgia.vdb() FROM PUBLIC;
