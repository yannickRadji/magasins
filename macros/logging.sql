{% macro log_run_results(in_results) %}
  {% for r in in_results %}
    {% set rows = (r.adapter_response.get('rows_affected') | default(0)) | int %}
    {% set sql %}
      insert into {{ target.database }}.AUDIT.LOGS
      (run_id, model, event, time, rows_affected)
      values ('{{ invocation_id }}', '{{ r.node.name }}', 'MODEL', current_timestamp, {{ rows }})
    {% endset %}
    {% do run_query(sql) %}
  {% endfor %}
  {{ return("select 1") }}
{% endmacro %}
