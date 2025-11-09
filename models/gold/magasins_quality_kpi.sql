with base as (
  select * from {{ ref('dim_magasins_snapshot') }} where dbt_valid_to is null
),

flags as (
  select
    store_uid,
    name, brand, lat, lon, clean_name, dbt_valid_from, dbt_updated_at,
    /* completeness: present in both sources */
    case when gi_id is not null and th_id is not null then 1 else 0 end as in_both_sources,
    /* coherence/badness flags */
    case when clean_name is null 
          or length(clean_name) < 4
          or clean_name='tabac' then 1 else 0 end as bad_name,
    case when brand is null then 1 else 0 end as bad_brand,
    case when lat is null or lon is null
           or not(lat between -90 and 90)
           or not(lon between -180 and 180)
           or not lat=0
           or not lon=0 then 1 else 0 end as bad_geo
  from base
)

select * from flags
