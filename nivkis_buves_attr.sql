CREATE OR REPLACE PROCEDURE vzd.nivkis_buves_attr(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$
BEGIN

DROP TABLE IF EXISTS vzd.nivkis_buves_attr;

CREATE TABLE vzd.nivkis_buves_attr (
  id serial PRIMARY KEY
  ,"BuildingCadastreNr" VARCHAR(17) NOT NULL
  ,"BuildingUseKindId" INT NOT NULL
  );

WITH s
AS (
  SELECT UNNEST((xpath('BuildingFullData/BuildingItemList/BuildingItemData/BuildingBasicData/BuildingCadastreNr/text()', data)))::TEXT "BuildingCadastreNr"
    ,UNNEST((xpath('BuildingFullData/BuildingItemList/BuildingItemData/BuildingBasicData/BuildingUseKind/BuildingUseKindId/text()', data)))::TEXT::INT "BuildingUseKindId"
  FROM vzd.nivkis_buves_attr_tmp
  )
INSERT INTO vzd.nivkis_buves_attr (
  "BuildingCadastreNr"
  ,"BuildingUseKindId"
  )
SELECT "BuildingCadastreNr"
  ,"BuildingUseKindId"
FROM s
WHERE "BuildingUseKindId" IS NOT NULL;

DROP TABLE IF EXISTS vzd.nivkis_buves_attr_tmp;

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.nivkis_buves_attr() FROM PUBLIC;