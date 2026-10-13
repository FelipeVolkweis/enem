{# Helpers that turn bronze's all-varchar columns into typed silver columns. #}

{# Bronze keeps CSV blanks as '' rather than NULL. #}
{% macro blank_to_null(col) -%}
    nullif(trim({{ col }}), '')
{%- endmacro %}

{#
  ENEM cell: blank -> NULL, and NULL for the 18 rows of 2019 that the per-state join truncated mid-field
  (the cut cell ends in ";<UF>", e.g. "515.;SP", and every later cell is empty).
#}
{% macro enem_text(col) -%}
    case when strpos({{ col }}, ';') > 0 then null else {{ blank_to_null(col) }} end
{%- endmacro %}

{# pandas round-trips wrote integer codes as floats ("42.0"), so go through double. #}
{% macro enem_int(col) -%}
    cast(cast({{ enem_text(col) }} as double) as integer)
{%- endmacro %}

{% macro enem_double(col) -%}
    cast({{ enem_text(col) }} as double)
{%- endmacro %}

{#
  Undo UTF-8 text that was decoded as latin1 and re-encoded ("SÃ£o Carlos" -> "São Carlos"):
  each character's code point is the original byte, so rebuild the bytes and decode them as UTF-8.
  Only values with the telltale [ÂÃ] + continuation-byte pattern are touched, so "Ângulo" survives.
#}
{% macro fix_mojibake(col) -%}
    case
        when regexp_like({{ col }}, '[ÂÃ][\x{80}-\x{BF}]')
            then from_utf8(from_hex(array_join(
                transform(regexp_extract_all({{ col }}, '.'),
                          c -> lpad(to_base(codepoint(cast(c as varchar(1))), 16), 2, '0')),
                '')))
        else {{ col }}
    end
{%- endmacro %}

{#
  Type for a Censo Escolar column, from INEP's naming convention:
  co_/in_/tp_/qt_ are integer codes and counts, dt_ are dates, everything else is text.
  Codes that are really strings (CEP, CNPJ, phone, street number, alphanumeric regional office) stay varchar.
#}
{% macro censo_column_type(name) -%}
    {%- if name in ['co_cep', 'co_orgao_regional', 'nu_endereco', 'nu_ddd', 'nu_telefone'] or name.startswith('nu_cnpj') -%}
        varchar
    {%- elif name == '_ingested_at' -%}
        timestamp(6) with time zone
    {%- elif name == 'nu_ano_censo' or name[:3] in ['co_', 'in_', 'tp_', 'qt_'] -%}
        integer
    {%- elif name.startswith('dt_') -%}
        date
    {%- else -%}
        varchar
    {%- endif -%}
{%- endmacro %}

{% macro censo_cast(name) -%}
    {%- set type = censo_column_type(name) -%}
    {%- if name == '_ingested_at' -%}
        {{ name }}
    {%- elif type == 'integer' -%}
        cast({{ blank_to_null(name) }} as integer)
    {%- elif type == 'date' -%}
        {# INEP SAS export: "06FEB2019:00:00:00", with "0" for missing. #}
        cast(date_parse(nullif({{ blank_to_null(name) }}, '0'), '%d%b%Y:%H:%i:%s') as date)
    {%- else -%}
        {{ blank_to_null(name) }}
    {%- endif -%}
{%- endmacro %}

{#
  Union relations whose column sets drift between years, keeping every column (missing ones are NULL),
  the same way keep_same_columns reindexed ENEM 2019 onto the 2024 layout. Columns are ordered by first appearance.
#}
{% macro union_censo(relations) -%}
    {%- if not execute -%}
        select 1 as placeholder
    {%- else -%}
        {%- set columns_by_rel = [] -%}
        {%- set all_columns = [] -%}
        {%- for rel in relations -%}
            {%- set names = adapter.get_columns_in_relation(rel) | map(attribute='name') | map('lower') | list -%}
            {%- do columns_by_rel.append(names) -%}
            {%- for n in names if n not in all_columns -%}
                {%- do all_columns.append(n) -%}
            {%- endfor -%}
        {%- endfor -%}
        {%- for rel in relations %}
            {%- set present = columns_by_rel[loop.index0] %}
            select
            {%- for n in all_columns %}
                {% if n in present %}{{ censo_cast(n) }}{% else %}cast(null as {{ censo_column_type(n) }}){% endif %} as {{ n }}{{ ',' if not loop.last }}
            {%- endfor %}
            from {{ rel }}
            {% if not loop.last %}union all{% endif %}
        {%- endfor -%}
    {%- endif -%}
{%- endmacro %}
