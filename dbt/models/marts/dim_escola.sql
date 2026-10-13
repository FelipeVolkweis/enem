{#
  Conformed school dimension shared by the ENEM and Censo Escolar stars, one row per INEP school code.
  The ENEM attributes (*_esc) and the census ones describe the same things with the same INEP codes,
  so each side fills in for the other: census-only schools get their *_esc columns from the census and
  ENEM-only schools get theirs from ENEM. Each value comes from the latest year in which it is not NULL.
  chave_escola = 0 is the "no school informed" member most ENEM participants point to.
#}

with enem as (
    select
        co_escola,
        {%- for c in ['co_municipio_esc', 'no_municipio_esc', 'co_uf_esc', 'sg_uf_esc',
                      'tp_dependencia_adm_esc', 'tp_localizacao_esc', 'tp_sit_func_esc'] %}
        {{ latest_non_null(c, 'nu_ano') }} as {{ c }}{{ ',' if not loop.last }}
        {%- endfor %}
    from {{ ref('stg_enem__participantes') }}
    where co_escola is not null
    group by co_escola
),

censo as (
    select
        co_entidade,
        {%- for c in ['no_entidade', 'co_municipio', 'no_municipio', 'co_uf', 'sg_uf',
                      'tp_dependencia', 'tp_categoria_escola_privada', 'tp_localizacao',
                      'tp_localizacao_diferenciada', 'tp_situacao_funcionamento', 'in_predio_compartilhado'] %}
        {{ latest_non_null(c, 'nu_ano_censo') }} as {{ c }}{{ ',' if not loop.last }}
        {%- endfor %}
    from {{ ref('stg_censo_escolar__escolas') }}
    group by co_entidade
),

escolas as (
    select
        coalesce(enem.co_escola, censo.co_entidade) as co_escola,

        -- ENEM view of the school
        coalesce(enem.co_municipio_esc, censo.co_municipio, 0) as co_municipio_esc,
        {{ name_or_unknown('coalesce(enem.no_municipio_esc, censo.no_municipio)') }} as no_municipio_esc,
        coalesce(enem.co_uf_esc, censo.co_uf, 0) as co_uf_esc,
        {{ name_or_unknown('coalesce(enem.sg_uf_esc, censo.sg_uf)') }} as sg_uf_esc,
        {{ code_or_unknown('coalesce(enem.tp_dependencia_adm_esc, censo.tp_dependencia)') }} as tp_dependencia_adm_esc,
        {{ code_or_unknown('coalesce(enem.tp_localizacao_esc, censo.tp_localizacao)') }} as tp_localizacao_esc,
        {{ code_or_unknown('coalesce(enem.tp_sit_func_esc, censo.tp_situacao_funcionamento)') }} as tp_sit_func_esc,

        -- Censo Escolar view of the school
        coalesce(censo.co_entidade, enem.co_escola) as co_entidade,
        {{ name_or_unknown('censo.no_entidade') }} as no_entidade,
        {{ code_or_unknown('coalesce(censo.tp_dependencia, enem.tp_dependencia_adm_esc)') }} as tp_dependencia,
        {{ code_or_unknown('censo.tp_categoria_escola_privada') }} as tp_categoria_escola_privada,
        {{ code_or_unknown('coalesce(censo.tp_localizacao, enem.tp_localizacao_esc)') }} as tp_localizacao,
        {{ code_or_unknown('censo.tp_localizacao_diferenciada') }} as tp_localizacao_diferenciada,
        {{ code_or_unknown('coalesce(censo.tp_situacao_funcionamento, enem.tp_sit_func_esc)') }} as tp_situacao_funcionamento,
        {{ code_or_unknown('censo.in_predio_compartilhado') }} as in_predio_compartilhado
    from enem
    full outer join censo on censo.co_entidade = enem.co_escola
)

select {{ sequential_key(['co_escola']) }} as chave_escola, *
from escolas

union all

select
    0 as chave_escola,
    0 as co_escola,
    0 as co_municipio_esc,
    'NÃO INFORMADO' as no_municipio_esc,
    0 as co_uf_esc,
    'NÃO INFORMADO' as sg_uf_esc,
    9 as tp_dependencia_adm_esc,
    9 as tp_localizacao_esc,
    9 as tp_sit_func_esc,
    0 as co_entidade,
    'NÃO INFORMADO' as no_entidade,
    9 as tp_dependencia,
    9 as tp_categoria_escola_privada,
    9 as tp_localizacao,
    9 as tp_localizacao_diferenciada,
    9 as tp_situacao_funcionamento,
    9 as in_predio_compartilhado
