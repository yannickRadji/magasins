{% macro clean_name(col) %}
trim(
  regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              regexp_replace(
                lower(trim({{ col }})),
                '[àáâãäåā]', 'a'
              ),
              '[çćč]', 'c'
            ),
            '[éèêëēėę]', 'e'
          ),
          '[îïíìīį]', 'i'
        ),
        '[ôöóòõøō]', 'o'
      ),
      '[ûüúùū]', 'u'
    ),
    '[^a-z0-9]+', ' '     -- collapse any non [a-z0-9] run to exactly one space
  )
)
{% endmacro %}
