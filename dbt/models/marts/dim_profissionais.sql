{#
  Junk dimension: each distinct combination of the profissionais columns among active schools.
  NULL codes are stored as 9 (see junk_value).
#}

{%- set cols = profissionais_columns() %}

with combinacoes as (
    select distinct
        {%- for c in cols %}
        {{ junk_value(c) }} as {{ c }}{{ ',' if not loop.last }}
        {%- endfor %}
    from {{ ref('int_censo_escolar__escolas_ativas') }}
)

select {{ sequential_key(cols) }} as chave_profissionais, *
from combinacoes
