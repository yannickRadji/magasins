{% macro brand_from_clean_name(clean_col) -%}
case
  -- IMPORTANT: put the most "dominant" brands first
  when {{ clean_col }} like '%station metro%'                              then 'STATION METRO'
  when {{ clean_col }} like '%auchan%'                                      then 'AUCHAN'
  when {{ clean_col }} like '%carrefour%'                                   then 'CARREFOUR'
  when {{ clean_col }} like '%leclerc%' or {{ clean_col }} like '%e leclerc%' then 'LECLERC'
  when {{ clean_col }} like '%intermarche%'                                 then 'INTERMARCHE'
  when {{ clean_col }} like '%super u%' or {{ clean_col }} like '%superu%'  then 'SUPER U'
  when {{ clean_col }} like '%monoprix%'                                    then 'MONOPRIX'
  when {{ clean_col }} like '%casino%'                                      then 'CASINO'
  when {{ clean_col }} like '%metro%'                                       then 'METRO (CASH & CARRY)'
  when {{ clean_col }} like '%sephora%'                                     then 'SEPHORA'
  when {{ clean_col }} like '%franprix%'                                    then 'FRANPRIX'
  when {{ clean_col }} like '%beauty succes%'                               then 'BEAUTY SUCCES'
  when {{ clean_col }} like '%galeries lafayette%'                          then 'GALERIES LAFAYETTE'
  when {{ clean_col }} like '%nocibe%'                                      then 'NOCIBE'
  when {{ clean_col }} like '%leroy merlin%'                                then 'LEROY MERLIN'
  when {{ clean_col }} like '%mr bricolage%' or {{ clean_col }} like '%monsieur bricolage%' then 'MR. BRICOLAGE'
  when {{ clean_col }} like '%marionnaud%'                                  then 'MARIONNAUD'
  else null
end
{%- endmacro %}
