select
  store_uid  as magasin_id,
  name,
  brand,
  lat as latitude,
  lon as longitude
from {{ ref('dim_magasins_snapshot') }}
where dbt_valid_to is null
