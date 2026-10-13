{#
  One row per municipality that has a school in the Censo Escolar, attributes from its latest census
  year. The intermediate/immediate geographic regions only exist in the 2024 layout, so they are NULL
  for municipalities seen only in 2019.
#}

select
    {{ surrogate_key(['co_municipio']) }} as chave_localizacao,
    co_municipio,
    max_by(no_municipio, nu_ano_censo) as no_municipio,
    max_by(co_uf, nu_ano_censo) as co_uf,
    max_by(no_uf, nu_ano_censo) as no_uf,
    max_by(sg_uf, nu_ano_censo) as sg_uf,
    max_by(co_regiao, nu_ano_censo) as co_regiao,
    max_by(no_regiao, nu_ano_censo) as no_regiao,
    max_by(co_regiao_geog_interm, nu_ano_censo) as co_regiao_geog_interm,
    max_by(no_regiao_geog_interm, nu_ano_censo) as no_regiao_geog_interm,
    max_by(co_regiao_geog_imed, nu_ano_censo) as co_regiao_geog_imed,
    max_by(no_regiao_geog_imed, nu_ano_censo) as no_regiao_geog_imed
from {{ ref('stg_censo_escolar__escolas') }}
group by co_municipio
