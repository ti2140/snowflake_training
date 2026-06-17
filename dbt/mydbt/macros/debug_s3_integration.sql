{% macro debug_s3_integration() %}

  {%- set div = "=" * 60 -%}
  {% do log(div, info=True) %}
  {% do log("DEBUG: Storage Integration Diagnostics", info=True) %}
  {% do log(div, info=True) %}

  -- 1) DESC INTEGRATION
  {% do log("[1/3] DESC INTEGRATION S3_INT", info=True) %}
  {% do log("-" * 60, info=True) %}
  {% set int_result = run_query("DESC INTEGRATION S3_INT") %}
  {% if int_result %}
    {% for row in int_result.rows %}
      {% do log("  " ~ (row[0] | string) ~ " = " ~ (row[2] | string), info=True) %}
    {% endfor %}
  {% endif %}
  {% do log("", info=True) %}

  -- 2) DESC STAGE (全プロパティを出力)
  {% set stage_fqn = target.database ~ ".RAW.ST_S3_MAIL" %}
  {% do log("[2/3] DESC STAGE " ~ stage_fqn, info=True) %}
  {% do log("-" * 60, info=True) %}
  {% set stage_url = none %}
  {% set stage_int = none %}
  {% set stage_result = run_query("DESC STAGE " ~ stage_fqn) %}
  {% if stage_result %}
    {% for row in stage_result.rows %}
      {# DESC STAGE columns: parent_property(0), property(1), property_type(2), property_value(3), property_default(4) #}
      {% do log("  [" ~ (row[0] | string) ~ "] " ~ (row[1] | string) ~ " = " ~ (row[3] | string), info=True) %}
      {% if row[1] == 'URL' %}
        {% set stage_url = row[3] | string | replace('["', '') | replace('"]', '') %}
      {% elif row[1] == 'STORAGE_INTEGRATION' %}
        {% set stage_int = row[3] | string %}
      {% endif %}
    {% endfor %}
  {% endif %}
  {% do log("", info=True) %}

  -- 3) SYSTEM$VALIDATE_STORAGE_INTEGRATION
  {% do log("[3/3] SYSTEM$VALIDATE_STORAGE_INTEGRATION", info=True) %}
  {% do log("-" * 60, info=True) %}
  {% do log("  Using URL = " ~ (stage_url | string), info=True) %}
  {% do log("  Using INTEGRATION = " ~ (stage_int | string), info=True) %}
  {% if stage_url and stage_int %}
    {% set v_query %}
      SELECT SYSTEM$VALIDATE_STORAGE_INTEGRATION(
        '{{ stage_int }}',
        '{{ stage_url }}',
        'ci-debug-probe.txt',
        'all'
      ) AS result
    {% endset %}
    {% set v_result = run_query(v_query) %}
    {% if v_result %}
      {% do log(v_result.rows[0][0] | string, info=True) %}
    {% endif %}
  {% else %}
    {% do log("URL or STORAGE_INTEGRATION not extracted from stage.", info=True) %}
  {% endif %}
  {% do log(div, info=True) %}

{% endmacro %}