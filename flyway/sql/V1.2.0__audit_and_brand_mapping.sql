USE SCHEMA AUDIT;

-- logs transformations
CREATE TABLE IF NOT EXISTS LOGS (
  run_id STRING,
  model STRING,
  event STRING,
  time TIMESTAMP_NTZ,
  rows_affected NUMBER
);

-- Admin roles should bypass RLS/masking
CREATE TABLE IF NOT EXISTS ADMIN_ACCESS (
  role_name STRING PRIMARY KEY
);

-- Brand mapping for RLS/MASKING,The same client can have several brands e.g. fnac darty group
CREATE TABLE IF NOT EXISTS BRAND_ACCESS (
  role_name STRING,
  brand     STRING
);

-- Brand dictionary for data-quality test
create or replace table AUDIT.BRAND_DICTIONARY (
  brand    string primary key,
  pattern  string,   -- regex on normalized name: (^| )token( |$)
  priority int       -- higher wins on ties
);

-- Data seeds for the 3 tables
INSERT INTO BRAND_DICTIONARY(brand, pattern, priority)
  SELECT * FROM VALUES
    ('MONOPRIX',            '(^| )monoprix( |$)',                 10),
    ('CARREFOUR',           '(^| )carrefour( |$)',                10),
    ('LECLERC',             '(^| )leclerc( |$)',                  10),
    ('INTERMARCHE',         '(^| )intermarche( |$)',              10),
    ('SUPER U',             '(^| )super u( |$)',                  10),
    ('STATION METRO',       '(^| )station metro( |$)',            10),
    ('CASINO',              '(^| )casino( |$)',                   10),
    ('AUCHAN',              '(^| )auchan( |$)',                   10),
    ('METRO (CASH & CARRY)','(^| )metro( |$)',                    10),
    ('SEPHORA',             '(^| )sephora( |$)',                  10),
    ('FRANPRIX',            '(^| )franprix( |$)',                 10),
    ('BEAUTY SUCCES',       '(^| )beauty succes( |$)',            10),
    ('GALERIES LAFAYETTE',  '(^| )galeries lafayette( |$)',       10),
    ('NOCIBE',              '(^| )nocibe( |$)',                   10),
    ('LEROY MERLIN',        '(^| )leroy merlin( |$)',             10),
    ('MR. BRICOLAGE',       '(^| )mr bricolage( |$)',             10),
    ('MARIONNAUD',          '(^| )marionnaud( |$)',               10)
  s(brand)
  WHERE NOT EXISTS (SELECT 1 FROM BRAND_DICTIONARY);

INSERT INTO BRAND_ACCESS(role_name, brand) SELECT * FROM VALUES
  ('ROLE_MONOPRIX','MONOPRIX'),
  ('ROLE_CARREFOUR','CARREFOUR'),
  ('ROLE_LECLERC','LECLERC'),
  ('ROLE_INTERMARCHE','INTERMARCHE'),
  ('ROLE_SUPER_U','SUPER U'),
  ('ROLE_METRO_AG','STATION METRO'),
  ('ROLE_CASINO','CASINO'),
  ('ROLE_AUCHAN','AUCHAN'),
  ('ROLE_AFM','AUCHAN'),
  ('ROLE_AFM','LEROY MERLIN'),
  ('ROLE_CASINO_GROUP','CASINO'),
  ('ROLE_CASINO_GROUP','FRANPRIX'),
  ('ROLE_CASINO_GROUP','MONOPRIX'),
  ('ROLE_METRO_AG','METRO (CASH & CARRY)'),
  ('ROLE_SEPHORA','SEPHORA'),
  ('ROLE_FRANPRIX','FRANPRIX'),
  ('ROLE_BEAUTY_SUCCES','BEAUTY SUCCES'),
  ('ROLE_GALERIES_LAFAYETTE','GALERIES LAFAYETTE'),
  ('ROLE_NOCIBE','NOCIBE'),
  ('ROLE_LEROY_MERLIN','LEROY MERLIN'),
  ('ROLE_MR_BRICOLAGE','MR. BRICOLAGE'),
  ('ROLE_MARIONNAUD','MARIONNAUD')
WHERE NOT EXISTS (SELECT 1 FROM BRAND_ACCESS);

INSERT INTO ADMIN_ACCESS(role_name)
  SELECT 'ROLE_YANNICK_RADJI'
  WHERE NOT EXISTS (SELECT 1 FROM ADMIN_ACCESS WHERE role_name='ROLE_YANNICK_RADJI');