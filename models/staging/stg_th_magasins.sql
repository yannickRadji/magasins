with source as (
    SELECT * FROM {{ source('DTL_EXO_TH','MAGASINS') }}
)

SELECT
    ID                as th_id,
    {{ clean_name('NAME') }} as clean_name,
    NAME              as raw_name,
    LATITUDE::float   as lat,
    LONGITUDE::float  as lon,
    'TH'              as _source,
    CURRENT_TIMESTAMP as _created_date
FROM source