{% snapshot dim_magasins_snapshot %}
{{
  config(
    unique_key='store_uid',
    strategy='check',
    check_cols='all',
    target_database=target.database,
    target_schema='SILVER'
  )
}}
select
  store_uid, name, clean_name, lat, lon, brand, gi_id, th_id
from {{ ref('magasins_canonical') }}
{% endsnapshot %}
