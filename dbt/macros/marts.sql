{# Helpers shared by the gold models in models/marts. #}

{#
  NULL policy for dimensions: attributes are never NULL.
    tp_/in_ codes -> 9, INEP's own "não sabe / não informado" code (already used by e.g. tp_rede_local),
                     here also meaning "não se aplica" (tp_categoria_escola_privada of a public school).
    identifiers   -> 0 (only on the "unknown" member rows).
    names         -> 'NÃO INFORMADO'.
  Facts keep NULL measures: NULL means "not measured", which avg()/sum() then skip.
#}
{% macro code_or_unknown(expr) -%}
    coalesce({{ expr }}, 9)
{%- endmacro %}

{% macro name_or_unknown(expr) -%}
    coalesce({{ expr }}, 'NÃO INFORMADO')
{%- endmacro %}

{#
  Sequential surrogate key (1, 2, ...) ordered by the natural key, so a rebuild over the same data gives
  the same keys. Facts look keys up by joining on the natural key. 0 is reserved for "unknown" members.
#}
{% macro sequential_key(order_by) -%}
    cast(row_number() over (order by {{ order_by | join(', ') }}) as integer)
{%- endmacro %}

{# yyyymmdd dim_data key of an edition, looked up in a year -> date var (enem_data_prova, censo_data_referencia). #}
{% macro edition_date_key(year_col, var_name) -%}
    case {{ year_col }}
        {%- for year, day in var(var_name).items() %}
        when {{ year }} then {{ day | replace('-', '') }}
        {%- endfor %}
    end
{%- endmacro %}

{# A junk-dimension column as stored in the dimension: tp_/in_ codes NULL -> 9; qt_ counts stay as published. #}
{% macro junk_value(col, alias=none) -%}
    {%- set ref = (alias ~ '.' ~ col) if alias else col -%}
    {%- if col.startswith('qt_') -%}{{ ref }}{%- else -%}{{ code_or_unknown(ref) }}{%- endif -%}
{%- endmacro %}

{# Join a junk dimension to census rows (alias `alias`) on all of its columns. #}
{% macro join_junk_dimension(dim, dim_alias, cols, alias) -%}
join {{ ref(dim) }} {{ dim_alias }} on
    {%- for c in cols %}
    {{ dim_alias }}.{{ c }} = {{ junk_value(c, alias) }}{{ ' and' if not loop.last }}
    {%- endfor %}
{%- endmacro %}

{# The value from the latest year in which it is not NULL (INEP leaves some fields blank in some years). #}
{% macro latest_non_null(col, year_col) -%}
    max_by({{ col }}, case when {{ col }} is not null then {{ year_col }} end)
{%- endmacro %}
