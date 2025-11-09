{{ config(materialized='table', schema='SILVER') }}

with gi as (
  select
    gi_id, clean_name, raw_name, lat, lon,
    split_part(clean_name, ' ', 1) as tkn1,
    floor(lat * 100)::int  as lat_b,     -- ~0.01° ≈ 1.1km (tune)
    floor(lon * 100)::int  as lon_b
  from {{ ref('stg_gi_magasins') }}
),
th as (
  select
    th_id, clean_name, raw_name, lat, lon,
    split_part(clean_name, ' ', 1) as tkn1,
    floor(lat * 100)::int  as lat_b,
    floor(lon * 100)::int  as lon_b
  from {{ ref('stg_th_magasins') }}
),

-- 1) Exact name block (very selective, cheap)
cand_exact as (
  select g.gi_id, t.th_id
  from gi g join th t
    on g.clean_name = t.clean_name
),

-- 2) Geo grid block: only same or neighbor cells (9-cell neighborhood)
cand_geo as (
  select g.gi_id, t.th_id
  from gi g
  join th t
    on t.lat_b between g.lat_b - 1 and g.lat_b + 1
   and t.lon_b between g.lon_b - 1 and g.lon_b + 1
),

-- 3) Token block: same first normalized token (e.g., brand / chain)
cand_token as (
  select g.gi_id, t.th_id
  from gi g
  join th t
    on g.tkn1 = t.tkn1
),

-- union candidates and remove duplicates + already exact-matched pairs
candidates as (
  select distinct gi_id, th_id from cand_exact
  union
  select distinct gi_id, th_id from cand_geo
  union
  select distinct gi_id, th_id from cand_token
),

scored as (
  select
    g.gi_id, t.th_id,
    g.clean_name as gi_name, t.clean_name as th_name,
    editdistance(g.clean_name, t.clean_name) as name_dist,
    haversine(g.lat, g.lon, t.lat, t.lon)    as dist_km,
    row_number() over (
      partition by g.gi_id
      order by
        (g.clean_name = t.clean_name) desc,           -- exact first
        haversine(g.lat, g.lon, t.lat, t.lon) asc,    -- nearer first
        editdistance(g.clean_name, t.clean_name) asc, -- then name distance
        t.th_id asc
    ) as rn_g,
    row_number() over (
      partition by t.th_id
      order by
        (g.clean_name = t.clean_name) desc,
        haversine(g.lat, g.lon, t.lat, t.lon) asc,
        editdistance(g.clean_name, t.clean_name) asc,
        g.gi_id asc
    ) as rn_t
  from candidates c
  join gi g on g.gi_id = c.gi_id
  join th t on t.th_id = c.th_id
  where
    -- apply thresholds only on candidates
    (
      g.clean_name = t.clean_name
      or (
        editdistance(g.clean_name, t.clean_name) <= {{ var('name_dist_threshold', 3) }}
        and haversine(g.lat, g.lon, t.lat, t.lon) < {{ var('geo_threshold_km', 0.5) }}
      )
    )
)

-- keep a 1-to-1 mapping: best TH per GI, ALSO best GI per TH
select
  gi_id, th_id,
  gi_name, th_name,
  /* geo columns are optional downstream; add if needed */
  null::float as gi_lat,
  null::float as gi_lon,
  null::float as th_lat,
  null::float as th_lon
from scored
qualify rn_g = 1 and rn_t = 1
