CREATE OR REPLACE PROCEDURE vzd.nivkis_buves_attr(
	)
LANGUAGE 'plpgsql'

AS $BODY$BEGIN

DO $$

BEGIN

--nivkis_buves_attr.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr CASCADE;

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
  ,"BuildingDeprecation" TEXT
  ,"BuildingDepValDate" DATE
  ,"BuildingSurveyDate" DATE
  ,"NotForLandBook" BOOLEAN
  ,"Prereg" BOOLEAN
  ,"NotExist" BOOLEAN
  --,"EngineeringStructureType" SMALLINT
  ,"BuildingKindId" INT[]
  );

/*
--EngineeringStructureType classificator.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_estype;

CREATE TABLE vzd.nivkis_buves_attr_estype (
  id SERIAL PRIMARY KEY
  ,"EngineeringStructureType" TEXT
  );
*/

--BuildingUseKind classificator.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_usekind;

CREATE TABLE vzd.nivkis_buves_attr_usekind (
  "BuildingUseKindId" SMALLINT PRIMARY KEY
  ,"BuildingUseKindName" TEXT
  );

--BuildingKind klasifikators.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_kind;

CREATE TABLE vzd.nivkis_buves_attr_kind (
  "BuildingKindId" INT PRIMARY KEY
  ,"BuildingKindName" TEXT
  );

--BuildingMaterialKind classificator.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_materialkind;

CREATE TABLE vzd.nivkis_buves_attr_materialkind (
  "MaterialKindId" SMALLINT PRIMARY KEY
  ,"MaterialKindName" TEXT
  );

--BuildingElementName classificator.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_elementname;

CREATE TABLE vzd.nivkis_buves_attr_elementname (
  id SERIAL PRIMARY KEY
  ,"BuildingElementName" TEXT
  );

--nivkis_buves_attr_element.
DROP TABLE IF EXISTS vzd.nivkis_buves_attr_element;

CREATE TABLE vzd.nivkis_buves_attr_element (
  id SERIAL PRIMARY KEY
  ,"BuildingCadastreNr" VARCHAR(14) NOT NULL
  ,"MaterialKindName" TEXT[]
  ,"BuildingElementName" SMALLINT
  --,"ConstructionKindName" TEXT[]
  --,"BuildingElementAcceptionYears" SMALLINT[]
  --,"BuildingElementExploitYear" SMALLINT
  --,"BuildingElementDeprecation" SMALLINT
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
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingDeprecation/text()', "BuildingItemData")) [1]::TEXT "BuildingDeprecation"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingDepValDate/text()', "BuildingItemData")) [1]::TEXT::DATE "BuildingDepValDate"
  ,(XPATH('/BuildingItemData/BuildingBasicData/BuildingSurveyDate/text()', "BuildingItemData")) [1]::TEXT::DATE "BuildingSurveyDate"
  ,(XPATH('/BuildingItemData/BuildingBasicData/NotForLandBook/text()', "BuildingItemData")) [1]::TEXT "NotForLandBook"
  ,(XPATH('/BuildingItemData/BuildingBasicData/Prereg/text()', "BuildingItemData")) [1]::TEXT "Prereg"
  ,(XPATH('/BuildingItemData/BuildingBasicData/NotExist/text()', "BuildingItemData")) [1]::TEXT "NotExist"
  --,(XPATH('/BuildingItemData/BuildingBasicData/EngineeringStructureType/text()', "BuildingItemData")) [1]::TEXT "EngineeringStructureType"
FROM nivkis_buves_attr_tmp1;

--Add data to the BuildingUseKind classificator.
INSERT INTO vzd.nivkis_buves_attr_usekind
SELECT DISTINCT "BuildingUseKindId"
  ,"BuildingUseKindName"
FROM nivkis_buves_attr_tmp2
WHERE "BuildingUseKindId" IS NOT NULL
ORDER BY "BuildingUseKindId";

--Add data to the BuildingMaterialKind classificator.
INSERT INTO vzd.nivkis_buves_attr_materialkind
SELECT DISTINCT "MaterialKindId"
  ,"MaterialKindName"
FROM nivkis_buves_attr_tmp2
WHERE "MaterialKindId" IS NOT NULL
ORDER BY "MaterialKindId";

/*
--Add data to the EngineeringStructureType classificator.
INSERT INTO vzd.nivkis_buves_attr_estype ("EngineeringStructureType")
SELECT DISTINCT "EngineeringStructureType"
FROM nivkis_buves_attr_tmp2
WHERE "EngineeringStructureType" IS NOT NULL
ORDER BY "EngineeringStructureType";
*/

--BuildingTypeData.
CREATE TEMPORARY TABLE nivkis_buves_attr_tmp3 AS
WITH a
AS (
  SELECT DISTINCT (XPATH('/BuildingItemData/BuildingBasicData/BuildingCadastreNr/text()', a."BuildingItemData")) [1]::TEXT "BuildingCadastreNr"
    ,t."BuildingKind"
  FROM nivkis_buves_attr_tmp1 a
    ,LATERAL UNNEST((XPATH('/BuildingItemData/BuildingTypeData/BuildingKind', "BuildingItemData"))::TEXT[]) t("BuildingKind")
  )
  ,b
AS (
  SELECT "BuildingCadastreNr"
    ,"BuildingKind"::XML "BuildingKind"
  FROM a
  )
SELECT "BuildingCadastreNr"
  ,(XPATH('/BuildingKind/BuildingKindId/text()', "BuildingKind")) [1]::TEXT::INT "BuildingKindId"
  ,(XPATH('/BuildingKind/BuildingKindName/text()', "BuildingKind")) [1]::TEXT "BuildingKindName"
FROM b;

--Papildina BuildingKind klasifikatoru.
INSERT INTO vzd.nivkis_buves_attr_kind
SELECT DISTINCT "BuildingKindId"
  ,"BuildingKindName"
FROM nivkis_buves_attr_tmp3
WHERE "BuildingKindId" IS NOT NULL
ORDER BY "BuildingKindId";

CREATE TEMPORARY TABLE nivkis_buves_attr_tmp4 AS
SELECT "BuildingCadastreNr"
  ,ARRAY_AGG("BuildingKindId" ORDER BY "BuildingKindId") "BuildingKindId"
FROM nivkis_buves_attr_tmp3
GROUP BY "BuildingCadastreNr";

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
  ,"BuildingKindId"
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
    ,b."BuildingKindId"
FROM nivkis_buves_attr_tmp2 a
INNER JOIN nivkis_buves_attr_tmp4 b ON a."BuildingCadastreNr" = b."BuildingCadastreNr"
/*LEFT OUTER JOIN vzd.nivkis_buves_attr_estype c ON a."EngineeringStructureType" = c."EngineeringStructureType"*/;

--BuildingElementData.
CREATE TEMPORARY TABLE nivkis_buves_attr_tmp_element AS
WITH a
AS (
  SELECT DISTINCT (XPATH('/BuildingItemData/BuildingBasicData/BuildingCadastreNr/text()', a."BuildingItemData")) [1]::TEXT "BuildingCadastreNr"
    ,t."ConstructionDataList"
  FROM nivkis_buves_attr_tmp1 a
    ,LATERAL UNNEST((XPATH('/BuildingItemData/BuildingElementData/ConstructionDataList', "BuildingItemData"))::TEXT[]) t("ConstructionDataList")
  )
  ,b
AS (
  SELECT "BuildingCadastreNr"
    ,"ConstructionDataList"::XML "ConstructionDataList"
  FROM a
  )
  ,c
AS (
  SELECT "BuildingCadastreNr"
    ,t."BuildingElementMaterialKind"
    ,(XPATH('/ConstructionDataList/BuildingElementName/text()', "ConstructionDataList")) [1]::TEXT "BuildingElementName"
    --,t2."BuildingElementConstructionKind"
    --,ARRAY(SELECT DISTINCT e FROM UNNEST(STRING_TO_ARRAY((XPATH('/ConstructionDataList/BuildingElementAcceptionYears/text()', "ConstructionDataList")) [1]::TEXT, ', ')::SMALLINT[]) a(e) ORDER BY e) "BuildingElementAcceptionYears"
    --,(XPATH('/ConstructionDataList/BuildingElementExploitYear/text()', "ConstructionDataList")) [1]::TEXT::SMALLINT "BuildingElementExploitYear"
    --,(XPATH('/ConstructionDataList/BuildingElementDeprecation/text()', "ConstructionDataList")) [1]::TEXT::SMALLINT "BuildingElementDeprecation"
  FROM b
  LEFT JOIN LATERAL(SELECT UNNEST((XPATH('/ConstructionDataList/BuildingElementMaterialKindList/BuildingElementMaterialKind', "ConstructionDataList"))::TEXT[]) "BuildingElementMaterialKind") t ON TRUE
    --LEFT JOIN LATERAL (SELECT UNNEST((XPATH('/ConstructionDataList/BuildingElementConstractionKindList/BuildingElementConstructionKind', "ConstructionDataList"))::TEXT[]) "BuildingElementConstructionKind") t2 ON TRUE
  )
  ,d
AS (
  SELECT "BuildingCadastreNr"
    ,"BuildingElementMaterialKind"::XML "BuildingElementMaterialKind"
    ,"BuildingElementName"
    --,"BuildingElementConstructionKind"::XML "BuildingElementConstructionKind"
    --,"BuildingElementAcceptionYears"
    --,"BuildingElementExploitYear"
    --,"BuildingElementDeprecation"
  FROM c
  )
  ,e
AS (
  SELECT "BuildingCadastreNr"
    --,(XPATH('/BuildingElementMaterialKind/MaterialKindId/text()', "BuildingElementMaterialKind")) [1]::TEXT::SMALLINT "MaterialKindId"
    ,(XPATH('/BuildingElementMaterialKind/MaterialKindName/text()', "BuildingElementMaterialKind")) [1]::TEXT "MaterialKindName"
    ,"BuildingElementName"
    --,(XPATH('/BuildingElementConstructionKind/ConstructionKindId/text()', "BuildingElementConstructionKind")) [1]::TEXT::SMALLINT "ConstructionKindId"
    --,(XPATH('/BuildingElementConstructionKind/ConstructionKindName/text()', "BuildingElementConstructionKind")) [1]::TEXT "ConstructionKindName"
    --,"BuildingElementAcceptionYears"
    --,"BuildingElementExploitYear"
    --,"BuildingElementDeprecation"
  FROM d
  )
SELECT "BuildingCadastreNr"
  ,ARRAY_AGG("MaterialKindName" ORDER BY "MaterialKindName") "MaterialKindName"
  ,"BuildingElementName"
  --,ARRAY_AGG("ConstructionKindName" ORDER BY "ConstructionKindName") "ConstructionKindName"
  --,"BuildingElementAcceptionYears"
  --,"BuildingElementExploitYear"
  --,"BuildingElementDeprecation"
FROM e
GROUP BY "BuildingCadastreNr"
  ,"BuildingElementName"
  --,"BuildingElementAcceptionYears"
  --,"BuildingElementExploitYear"
  /*,"BuildingElementDeprecation"*/;

--Add data to the BuildingElementName classificator.
INSERT INTO vzd.nivkis_buves_attr_elementname ("BuildingElementName")
SELECT DISTINCT "BuildingElementName"
FROM nivkis_buves_attr_tmp_element
WHERE "BuildingElementName" IS NOT NULL
ORDER BY "BuildingElementName";

--Use ID from the classificator.
CREATE TEMPORARY TABLE nivkis_buves_attr_tmp_element_2 AS
SELECT a."BuildingCadastreNr"
  ,a."MaterialKindName"
  ,b.id "BuildingElementName"
  --,a."ConstructionKindName"
  --,a."BuildingElementAcceptionYears"
  --,a."BuildingElementExploitYear"
  --,a."BuildingElementDeprecation"
FROM nivkis_buves_attr_tmp_element a
INNER JOIN vzd.nivkis_buves_attr_elementname b ON a."BuildingElementName" = b."BuildingElementName";

--nivkis_buves_attr_element.
INSERT INTO vzd.nivkis_buves_attr_element (
  "BuildingCadastreNr"
  ,"MaterialKindName"
  ,"BuildingElementName"
  --,"ConstructionKindName"
  --,"BuildingElementAcceptionYears"
  --,"BuildingElementExploitYear"
  --,"BuildingElementDeprecation"
  )
SELECT "BuildingCadastreNr"
  ,"MaterialKindName"
  ,"BuildingElementName"
  --,"ConstructionKindName"
  --,"BuildingElementAcceptionYears"
  --,"BuildingElementExploitYear"
  --,"BuildingElementDeprecation"
FROM nivkis_buves_attr_tmp_element_2;

END
$$ LANGUAGE plpgsql;

END;
$BODY$;

REVOKE ALL ON PROCEDURE vzd.nivkis_buves_attr() FROM PUBLIC;
