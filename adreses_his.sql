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
FROM vzd.aw_dziv_his;

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
FROM vzd.aw_eka_his;

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
FROM vzd.aw_iela_his;

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
FROM vzd.aw_ciems_his;

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
FROM vzd.aw_pilseta_his;

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
FROM vzd.aw_pagasts_his;

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
FROM vzd.aw_novads_his;

---Correct date errors.
UPDATE vzd.adreses_his
SET dat_sak = '2000-04-05'
WHERE dat_sak = '0200-04-05';

UPDATE vzd.adreses_his
SET dat_sak = '2000-10-04'
WHERE dat_sak = '0200-10-04';

UPDATE vzd.adreses_his
SET dat_sak = '2002-09-25'
WHERE dat_sak = '0202-09-25';