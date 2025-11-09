{{ config(materialized='table', schema='SILVER') }}

with gi as (select * from {{ ref('stg_gi_magasins') }}),
     th as (select * from {{ ref('stg_th_magasins') }}),
     m  as (select * from {{ ref('magasins_match') }}),

base as (
  -- matched
  select
    md5( concat_ws('|', coalesce('G:'||m.gi_id,''), coalesce('T:'||m.th_id,'')) ) as store_uid,
    coalesce(g.raw_name, t.raw_name)   as name,
    coalesce(g.clean_name, t.clean_name) as clean_name,
    coalesce(g.lat, t.lat)            as lat,
    coalesce(g.lon, t.lon)            as lon,
    m.gi_id, m.th_id
  from m
  left join gi g on g.gi_id = m.gi_id
  left join th t on t.th_id = m.th_id

  union all
  -- unmatched GI
  select md5('G:'||gi_id), raw_name, clean_name, lat, lon, gi_id, cast(null as number)
  from gi where gi_id not in (select gi_id from m)

  union all
  -- unmatched TH
  select md5('T:'||th_id), raw_name, clean_name, lat, lon, cast(null as number), th_id
  from th where th_id not in (select th_id from m)
)

select
  store_uid,
  name,
  clean_name,
  lat,
  lon,
  {{ brand_from_clean_name('clean_name') }} as brand,
  gi_id,
  th_id
from base
