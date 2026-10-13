{# Use a model's +schema verbatim (iceberg.silver) instead of dbt's default "<target>_<custom>" prefix. #}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {{ (custom_schema_name or target.schema) | trim }}
{%- endmacro %}
