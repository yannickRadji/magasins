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

-- by pass only RLS for data engineers & analysts
CREATE TABLE IF NOT EXISTS INTERNAL_ACCESS (
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
  ('DBR_BRAND_MONOPRIX','MONOPRIX'),
  ('DBR_BRAND_CARREFOUR','CARREFOUR'),
  ('DBR_BRAND_LECLERC','LECLERC'),
  ('DBR_BRAND_INTERMARCHE','INTERMARCHE'),
  ('DBR_BRAND_SUPER_U','SUPER U'),
  ('DBR_BRAND_METRO_AG','STATION METRO'),
  ('DBR_BRAND_CASINO','CASINO'),
  ('DBR_BRAND_AUCHAN','AUCHAN'),
  ('DBR_ROLE_AFM','AUCHAN'),
  ('DBR_ROLE_AFM','LEROY MERLIN'),
  ('DBR_ROLE_CASINO_GROUP','CASINO'),
  ('DBR_ROLE_CASINO_GROUP','FRANPRIX'),
  ('DBR_ROLE_CASINO_GROUP','MONOPRIX'),
  ('DBR_BRAND_METRO_AG','METRO (CASH & CARRY)'),
  ('DBR_BRAND_SEPHORA','SEPHORA'),
  ('DBR_BRAND_FRANPRIX','FRANPRIX'),
  ('DBR_BRAND_BEAUTY_SUCCES','BEAUTY SUCCES'),
  ('DBR_BRAND_GALERIES_LAFAYETTE','GALERIES LAFAYETTE'),
  ('DBR_BRAND_NOCIBE','NOCIBE'),
  ('DBR_BRAND_LEROY_MERLIN','LEROY MERLIN'),
  ('DBR_BRAND_MR_BRICOLAGE','MR. BRICOLAGE'),
  ('DBR_BRAND_MARIONNAUD','MARIONNAUD')
WHERE NOT EXISTS (SELECT 1 FROM BRAND_ACCESS);

INSERT INTO ADMIN_ACCESS(role_name) SELECT * FROM VALUES
  ('ROLE_YANNICK_RADJI'),
  ('DBR_DATA_ENGINEER')
  WHERE NOT EXISTS (SELECT 1 FROM ADMIN_ACCESS);

INSERT INTO INTERNAL_ACCESS(role_name) SELECT * FROM VALUES
  ('ROLE_YANNICK_RADJI'),
  ('DBR_DATA_ENGINEER'),
  ('DBR_DATA_ANALYST')
  WHERE NOT EXISTS (SELECT 1 FROM INTERNAL_ACCESS);