CREATE OR REPLACE PROCEDURE vzd.nivkis_buves_attr(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$

BEGIN

--nivkis_buves_attr.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr;

CREATE TABLE vzd.nivkis_buves_attr (
  id SERIAL PRIMARY KEY
  ,"BuildingCadastreNr" VARCHAR(14) NOT NULL
  ,"ParcelCadastreNr" VARCHAR(11) NOT NULL
  ,"BuildingName" TEXT
  ,"BuildingUseKindId" SMALLINT
  --,"BuildingArea" DECIMAL(10, 2)
  --,"BuildingConstrArea" DECIMAL(11, 2)
  ,"BuildingGroundFloors" SMALLINT
  ,"BuildingUndergroundFloors" SMALLINT
  ,"MaterialKindId" SMALLINT
  ,"BuildingPregCount" SMALLINT
  ,"BuildingAcceptionYears" SMALLINT[]
  ,"BuildingExploitYear" SMALLINT
  ,"BuildingDeprecation" SMALLINT
  ,"BuildingDepValDate" DATE
  ,"BuildingSurveyDate" DATE
  ,"NotForLandBook" BOOLEAN
  ,"Prereg" BOOLEAN
  ,"NotExist" BOOLEAN
  --,"EngineeringStructureType" SMALLINT
  );

/*
--EngineeringStructureType klasifikators.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_estype;

CREATE TABLE vzd.nivkis_buves_attr_estype (
  id SERIAL PRIMARY KEY
  ,"EngineeringStructureType" TEXT
  );
*/

--BuildingUseKind klasifikators.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_usekind;

CREATE TABLE vzd.nivkis_buves_attr_usekind (
  "BuildingUseKindId" SMALLINT PRIMARY KEY
  ,"BuildingUseKindName" TEXT
  );

--BuildingMaterialKind klasifikators.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_materialkind;

CREATE TABLE vzd.nivkis_buves_attr_materialkind (
  "MaterialKindId" SMALLINT PRIMARY KEY
  ,"MaterialKindName" TEXT
  );

--BuildingItemData.
CREATE TEMPORARY TABLE nivkis_buves_attr_tmp1 AS
SELECT UNNEST(XPATH('BuildingFullData/BuildingItemList/BuildingItemData', data)) "BuildingItemData"
FROM vzd.nivkis_buves_attr_tmp;

DROP TABLE IF EXISTS vzd.nivkis_buves_attr_tmp;

--ObjectRelation un BuildingBasicData.
CREATE TEMPORARY TABLE nivkis_buves_attr_tmp2 AS
SELECT DISTINCT (XPATH('/BuildingItemData/BuildingBasicData/BuildingCadastreNr/text()', "BuildingItemData")) [1]::TEXT "BuildingCadastreNr"
  --,(XPATH('/BuildingItemData/BuildingBasicData/VARISCode/text()', "BuildingItemData")) [1]::TEXT::INT "VARISCode"
  ,(XPATH('/BuildingItemData/ObjectRelation/ObjectCadastreNr/text()', "BuildingItemData")) [1]::TEXT "ParcelCadastreNr"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingName/text()', "BuildingItemData")) [1]::TEXT "BuildingName"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingUseKind/BuildingUseKindId/text()', "BuildingItemData")) [1]::TEXT::SMALLINT "BuildingUseKindId"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingUseKind/BuildingUseKindName/text()', "BuildingItemData")) [1]::TEXT "BuildingUseKindName"
  --,(XPATH('/BuildingItemData/BuildingBasicData/BuildingArea/text()', "BuildingItemData")) [1]::TEXT::DECIMAL(10, 2) "BuildingArea"
  --,(XPATH('/BuildingItemData/BuildingBasicData/BuildingConstrArea/text()', "BuildingItemData")) [1]::TEXT::DECIMAL(11, 2) "BuildingConstrArea"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingGroundFloors/text()', "BuildingItemData")) [1]::TEXT::SMALLINT "BuildingGroundFloors"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingUndergroundFloors/text()', "BuildingItemData")) [1]::TEXT::SMALLINT "BuildingUndergroundFloors"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingMaterialKind/MaterialKindId/text()', "BuildingItemData")) [1]::TEXT::SMALLINT "MaterialKindId"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingMaterialKind/MaterialKindName/text()', "BuildingItemData")) [1]::TEXT "MaterialKindName"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingPregCount/text()', "BuildingItemData")) [1]::TEXT::SMALLINT "BuildingPregCount"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingAcceptionYears/text()', "BuildingItemData")) [1]::TEXT "BuildingAcceptionYears"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingExploitYear/text()', "BuildingItemData")) [1]::TEXT::SMALLINT "BuildingExploitYear"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingDeprecation/text()', "BuildingItemData")) [1]::TEXT::SMALLINT "BuildingDeprecation"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingDepValDate/text()', "BuildingItemData")) [1]::TEXT::DATE "BuildingDepValDate"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingSurveyDate/text()', "BuildingItemData")) [1]::TEXT::DATE "BuildingSurveyDate"
  ,(XPATH('/BuildingItemData/BuildingBasicData/NotForLandBook/text()', "BuildingItemData")) [1]::TEXT "NotForLandBook"
  ,(XPATH('/BuildingItemData/BuildingBasicData/Prereg/text()', "BuildingItemData")) [1]::TEXT "Prereg"
  ,(XPATH('/BuildingItemData/BuildingBasicData/NotExist/text()', "BuildingItemData")) [1]::TEXT "NotExist"
  --,(XPATH('/BuildingItemData/BuildingBasicData/EngineeringStructureType/text()', "BuildingItemData")) [1]::TEXT "EngineeringStructureType"
FROM nivkis_buves_attr_tmp1;

--Papildina BuildingUseKind klasifikatoru.
INSERT INTO vzd.nivkis_buves_attr_usekind
SELECT DISTINCT "BuildingUseKindId"
  ,"BuildingUseKindName"
FROM nivkis_buves_attr_tmp2
WHERE "BuildingUseKindId" IS NOT NULL
ORDER BY "BuildingUseKindId";

--Papildina BuildingMaterialKind klasifikatoru.
INSERT INTO vzd.nivkis_buves_attr_materialkind
SELECT DISTINCT "MaterialKindId"
  ,"MaterialKindName"
FROM nivkis_buves_attr_tmp2
WHERE "MaterialKindId" IS NOT NULL
ORDER BY "MaterialKindId";

/*
--Papildina EngineeringStructureType klasifikatoru.
INSERT INTO vzd.nivkis_buves_attr_estype ("EngineeringStructureType")
SELECT DISTINCT "EngineeringStructureType"
FROM nivkis_buves_attr_tmp2
WHERE "EngineeringStructureType" IS NOT NULL
ORDER BY "EngineeringStructureType";
*/

--nivkis_buves_attr.
INSERT INTO vzd.nivkis_buves_attr (
  "BuildingCadastreNr"
  ,"ParcelCadastreNr"
  ,"BuildingName"
  ,"BuildingUseKindId"
  --,"BuildingArea"
  --,"BuildingConstrArea"
  ,"BuildingGroundFloors"
  ,"BuildingUndergroundFloors"
  ,"MaterialKindId"
  ,"BuildingPregCount"
  ,"BuildingAcceptionYears"
  ,"BuildingExploitYear"
  ,"BuildingDeprecation"
  ,"BuildingDepValDate"
  ,"BuildingSurveyDate"
  ,"NotForLandBook"
  ,"Prereg"
  ,"NotExist"
  --,"EngineeringStructureType"
  )
SELECT DISTINCT a."BuildingCadastreNr"
  ,a."ParcelCadastreNr"
  ,a."BuildingName"
  ,a."BuildingUseKindId"
  --,a."BuildingArea"
  --,a."BuildingConstrArea"
  ,a."BuildingGroundFloors"
  ,a."BuildingUndergroundFloors"
  ,a."MaterialKindId"
  ,a."BuildingPregCount"
  ,ARRAY(SELECT DISTINCT e FROM UNNEST(STRING_TO_ARRAY(a."BuildingAcceptionYears", ', ')::SMALLINT[]) a(e) ORDER BY e) "BuildingAcceptionYears"
  ,a."BuildingExploitYear"
  ,a."BuildingDeprecation"
  ,a."BuildingDepValDate"
  ,a."BuildingSurveyDate"
  ,CASE 
    WHEN a."NotForLandBook" IS NOT NULL
      THEN 1::BOOLEAN
    ELSE NULL
    END "NotForLandBook"
  ,CASE 
    WHEN a."Prereg" IS NOT NULL
      THEN 1::BOOLEAN
    ELSE NULL
    END "Prereg"
  ,CASE 
    WHEN a."NotExist" IS NOT NULL
      THEN 1::BOOLEAN
    ELSE NULL
    END "NotExist"
  --,c.id "EngineeringStructureType"
FROM nivkis_buves_attr_tmp2 a
/*LEFT OUTER JOIN vzd.nivkis_buves_attr_estype c ON a."EngineeringStructureType" = c."EngineeringStructureType"*/;

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.nivkis_buves_attr() FROM PUBLIC;
