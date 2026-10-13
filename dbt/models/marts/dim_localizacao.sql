{#
  One row per municipality that has a school in the Censo Escolar, each attribute from the latest year
  in which it is not NULL. The intermediate/immediate geographic regions only exist in the 2024 layout;
  a municipality seen only in 2019 gets 0 / 'NÃO INFORMADO' for them.
#}

with municipios as (
    select
        co_municipio,
        {%- for c in ['no_municipio', 'co_uf', 'no_uf', 'sg_uf', 'co_regiao', 'no_regiao',
                      'co_regiao_geog_interm', 'no_regiao_geog_interm', 'co_regiao_geog_imed', 'no_regiao_geog_imed'] %}
        {{ latest_non_null(c, 'nu_ano_censo') }} as {{ c }}{{ ',' if not loop.last }}
        {%- endfor %}
    from {{ ref('stg_censo_escolar__escolas') }}
    group by co_municipio
)

select
    {{ sequential_key(['co_municipio']) }} as chave_localizacao,
    co_municipio,
    {{ name_or_unknown('no_municipio') }} as no_municipio,
    coalesce(co_uf, 0) as co_uf,
    {{ name_or_unknown('no_uf') }} as no_uf,
    {{ name_or_unknown('sg_uf') }} as sg_uf,
    coalesce(co_regiao, 0) as co_regiao,
    {{ name_or_unknown('no_regiao') }} as no_regiao,
    coalesce(co_regiao_geog_interm, 0) as co_regiao_geog_interm,
    {{ name_or_unknown('no_regiao_geog_interm') }} as no_regiao_geog_interm,
    coalesce(co_regiao_geog_imed, 0) as co_regiao_geog_imed,
    {{ name_or_unknown('no_regiao_geog_imed') }} as no_regiao_geog_imed
from municipios
