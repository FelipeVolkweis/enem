{#
  Conformed school dimension shared by the ENEM and Censo Escolar stars. ENEM-side attributes
  (*_esc) come from the participants' records, census-side ones from Censo Escolar; each side keeps
  its latest year. co_escola is the INEP code from either side, co_entidade is set only when the
  school is in the census. Row -1 stands for participants with no school informed.
#}

with enem as (
    select
        co_escola,
        max_by(co_municipio_esc, nu_ano) as co_municipio_esc,
        max_by(no_municipio_esc, nu_ano) as no_municipio_esc,
        max_by(co_uf_esc, nu_ano) as co_uf_esc,
        max_by(sg_uf_esc, nu_ano) as sg_uf_esc,
        max_by(tp_dependencia_adm_esc, nu_ano) as tp_dependencia_adm_esc,
        max_by(tp_localizacao_esc, nu_ano) as tp_localizacao_esc,
        max_by(tp_sit_func_esc, nu_ano) as tp_sit_func_esc
    from {{ ref('stg_enem__participantes') }}
    where co_escola is not null
    group by co_escola
),

censo as (
    select
        co_entidade,
        max_by(no_entidade, nu_ano_censo) as no_entidade,
        max_by(tp_dependencia, nu_ano_censo) as tp_dependencia,
        max_by(tp_categoria_escola_privada, nu_ano_censo) as tp_categoria_escola_privada,
        max_by(tp_localizacao, nu_ano_censo) as tp_localizacao,
        max_by(tp_localizacao_diferenciada, nu_ano_censo) as tp_localizacao_diferenciada,
        max_by(tp_situacao_funcionamento, nu_ano_censo) as tp_situacao_funcionamento,
        max_by(in_predio_compartilhado, nu_ano_censo) as in_predio_compartilhado
    from {{ ref('stg_censo_escolar__escolas') }}
    group by co_entidade
),

escolas as (
    select
        coalesce(enem.co_escola, censo.co_entidade) as co_escola,
        enem.co_municipio_esc,
        enem.no_municipio_esc,
        enem.co_uf_esc,
        enem.sg_uf_esc,
        enem.tp_dependencia_adm_esc,
        enem.tp_localizacao_esc,
        enem.tp_sit_func_esc,
        censo.co_entidade,
        censo.no_entidade,
        censo.tp_dependencia,
        censo.tp_categoria_escola_privada,
        censo.tp_localizacao,
        censo.tp_localizacao_diferenciada,
        censo.tp_situacao_funcionamento,
        censo.in_predio_compartilhado
    from enem
    full outer join censo on censo.co_entidade = enem.co_escola
)

select {{ escola_key('co_escola') }} as chave_escola, *
from escolas

union all

select
    -1 as chave_escola,
    cast(null as integer) as co_escola,
    cast(null as integer) as co_municipio_esc,
    cast(null as varchar) as no_municipio_esc,
    cast(null as integer) as co_uf_esc,
    cast(null as varchar) as sg_uf_esc,
    cast(null as integer) as tp_dependencia_adm_esc,
    cast(null as integer) as tp_localizacao_esc,
    cast(null as integer) as tp_sit_func_esc,
    cast(null as integer) as co_entidade,
    'NÃO INFORMADA' as no_entidade,
    cast(null as integer) as tp_dependencia,
    cast(null as integer) as tp_categoria_escola_privada,
    cast(null as integer) as tp_localizacao,
    cast(null as integer) as tp_localizacao_diferenciada,
    cast(null as integer) as tp_situacao_funcionamento,
    cast(null as integer) as in_predio_compartilhado
