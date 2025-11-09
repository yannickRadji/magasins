-- Ensure all surfaced brands belong to the dictionary
select brand
from {{ ref('magasins_canonical') }}
where brand is not null
  and brand not in (select brand from {{ target.database }}.AUDIT.BRAND_DICTIONARY);
