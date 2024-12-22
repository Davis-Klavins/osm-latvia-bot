--aw_ciems.
DROP TABLE IF EXISTS vzd.aw_ciems;

CREATE TABLE vzd.aw_ciems (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,statuss CHAR(3) NOT NULL
  ,sort_nos TEXT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,atrib TEXT
  ,std TEXT
  );

--aw_ciems_his.
DROP TABLE IF EXISTS vzd.aw_ciems_his;

CREATE TABLE vzd.aw_ciems_his (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT NOT NULL
  ,std TEXT
  ,nosaukums TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  );

--aw_dziv.
DROP TABLE IF EXISTS vzd.aw_dziv;

CREATE TABLE vzd.aw_dziv (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,statuss CHAR(3) NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,sort_nos TEXT NOT NULL
  ,atrib TEXT
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,std TEXT
  );

--aw_dziv_his.
DROP TABLE IF EXISTS vzd.aw_dziv_his;

CREATE TABLE vzd.aw_dziv_his (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT NOT NULL
  ,std TEXT
  ,nosaukums TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  );

--aw_eka.
DROP TABLE IF EXISTS vzd.aw_eka;

CREATE TABLE vzd.aw_eka (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,statuss CHAR(3) NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,sort_nos TEXT NOT NULL
  ,atrib TEXT
  ,pnod_cd INT
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,for_build BOOLEAN NOT NULL
  ,plan_adr BOOLEAN NOT NULL
  ,std TEXT
  ,koord_x DECIMAL(9, 3)
  ,koord_y DECIMAL(9, 3)
  ,dd_n DECIMAL(8, 6)
  ,dd_e DECIMAL(8, 6)
  );

--aw_eka_his.
DROP TABLE IF EXISTS vzd.aw_eka_his;

CREATE TABLE vzd.aw_eka_his (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,kods_his INT
  ,tips_cd SMALLINT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,std TEXT
  ,nosaukums TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  );

--aw_iela.
DROP TABLE IF EXISTS vzd.aw_iela;

CREATE TABLE vzd.aw_iela (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,statuss CHAR(3) NOT NULL
  ,sort_nos TEXT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,atrib TEXT
  ,std TEXT
  );

--aw_iela_his.
DROP TABLE IF EXISTS vzd.aw_iela_his;

CREATE TABLE vzd.aw_iela_his (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT NOT NULL
  ,std TEXT
  ,nosaukums TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  );

--aw_novads.
DROP TABLE IF EXISTS vzd.aw_novads;

CREATE TABLE vzd.aw_novads (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,statuss CHAR(3) NOT NULL
  ,sort_nos TEXT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,atrib TEXT
  ,std TEXT
  );

--aw_novads_his.
DROP TABLE IF EXISTS vzd.aw_novads_his;

CREATE TABLE vzd.aw_novads_his (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT NOT NULL
  ,std TEXT
  ,nosaukums TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  );

--aw_pagasts.
DROP TABLE IF EXISTS vzd.aw_pagasts;

CREATE TABLE vzd.aw_pagasts (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,statuss CHAR(3) NOT NULL
  ,sort_nos TEXT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,atrib TEXT
  ,std TEXT
  );

--aw_pagasts_his.
DROP TABLE IF EXISTS vzd.aw_pagasts_his;

CREATE TABLE vzd.aw_pagasts_his (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT NOT NULL
  ,std TEXT
  ,nosaukums TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  );

--aw_pilseta.
DROP TABLE IF EXISTS vzd.aw_pilseta;

CREATE TABLE vzd.aw_pilseta (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,statuss CHAR(3) NOT NULL
  ,sort_nos TEXT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,atrib TEXT
  ,std TEXT
  );

--aw_pilseta_his.
DROP TABLE IF EXISTS vzd.aw_pilseta_his;

CREATE TABLE vzd.aw_pilseta_his (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT NOT NULL
  ,std TEXT
  ,nosaukums TEXT
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  );

--aw_ppils.
DROP TABLE IF EXISTS vzd.aw_ppils;

CREATE TABLE vzd.aw_ppils (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,ppils TEXT NOT NULL
  );

--aw_rajons.
DROP TABLE IF EXISTS vzd.aw_rajons;

CREATE TABLE vzd.aw_rajons (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,apstipr BOOLEAN
  ,apst_pak SMALLINT
  ,statuss CHAR(3) NOT NULL
  ,sort_nos TEXT NOT NULL
  ,dat_sak TEXT NOT NULL
  ,dat_mod TEXT NOT NULL
  ,dat_beig TEXT
  ,atrib TEXT
  );

--aw_vietu_centroidi.
DROP TABLE IF EXISTS vzd.aw_vietu_centroidi;

CREATE TABLE vzd.aw_vietu_centroidi (
  id serial PRIMARY KEY
  ,kods INT NOT NULL
  ,tips_cd SMALLINT NOT NULL
  ,nosaukums TEXT NOT NULL
  ,vkur_cd INT NOT NULL
  ,vkur_tips SMALLINT NOT NULL
  ,std TEXT
  ,koord_x DECIMAL(9, 3)
  ,koord_y DECIMAL(9, 3)
  ,dd_n DECIMAL(8, 6)
  ,dd_e DECIMAL(8, 6)
  );
