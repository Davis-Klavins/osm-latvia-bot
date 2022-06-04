CREATE OR REPLACE PROCEDURE vzd.nivkis_adreses(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$
BEGIN

DROP TABLE IF EXISTS vzd.nivkis_adreses;

CREATE TABLE vzd.nivkis_adreses (
  id serial PRIMARY KEY
  ,"ObjectCadastreNr" VARCHAR(17) NOT NULL
  ,"ARCode" INT NOT NULL
  );

WITH s
AS (
  SELECT UNNEST((xpath('AddressFullData/AddressItemList/AddressItemData/ObjectRelation/ObjectCadastreNr/text()', data)))::TEXT "ObjectCadastreNr"
    ,UNNEST((xpath('AddressFullData/AddressItemList/AddressItemData/AddressData/ARCode/text()', data)))::TEXT::INT "ARCode"
  FROM vzd.nivkis_adreses_tmp
  )
INSERT INTO vzd.nivkis_adreses (
  "ObjectCadastreNr"
  ,"ARCode"
  )
SELECT "ObjectCadastreNr"
  ,"ARCode"
FROM s
WHERE "ARCode" IS NOT NULL;

DROP TABLE IF EXISTS vzd.nivkis_adreses_tmp;

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.nivkis_adreses() FROM PUBLIC;
