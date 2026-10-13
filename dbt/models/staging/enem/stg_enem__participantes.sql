{{ config(properties={"partitioning": "ARRAY['nu_ano']"}) }}

{#
  One row per ENEM participant, 2019 + 2024 on the 2024 layout (keep_same_columns), plus q024/q025
  which only 2019 asked. Questionnaire letters are kept as answered: the same q-code means different
  things each year, so decode them through stg_enem__dicionario_questionario on (nu_ano, questao).
#}

{% for year in [2019, 2024] %}
select
    cast({{ enem_text('nu_inscricao') }} as bigint) as nu_inscricao,
    {{ enem_int('nu_ano') }} as nu_ano,

    -- participant
    {{ enem_text('tp_sexo') }} as tp_sexo,
    {{ enem_int('tp_estado_civil') }} as tp_estado_civil,
    {{ enem_int('tp_cor_raca') }} as tp_cor_raca,
    {{ enem_int('tp_nacionalidade') }} as tp_nacionalidade,
    {{ enem_int('tp_st_conclusao') }} as tp_st_conclusao,
    {{ enem_int('tp_ano_concluiu') }} as tp_ano_concluiu,
    {{ enem_int('tp_ensino') }} as tp_ensino,
    {{ enem_int('in_treineiro') }} as in_treineiro,

    -- school (joins to stg_censo_escolar__escolas.co_entidade)
    {{ enem_int('co_escola') }} as co_escola,
    {{ enem_int('co_municipio_esc') }} as co_municipio_esc,
    {{ fix_mojibake(enem_text('no_municipio_esc')) }} as no_municipio_esc,
    {{ enem_int('co_uf_esc') }} as co_uf_esc,
    {{ enem_text('sg_uf_esc') }} as sg_uf_esc,
    {{ enem_int('tp_dependencia_adm_esc') }} as tp_dependencia_adm_esc,
    {{ enem_int('tp_localizacao_esc') }} as tp_localizacao_esc,
    {{ enem_int('tp_sit_func_esc') }} as tp_sit_func_esc,

    -- exam location
    {{ enem_int('co_municipio_prova') }} as co_municipio_prova,
    {{ fix_mojibake(enem_text('no_municipio_prova')) }} as no_municipio_prova,
    {{ enem_int('co_uf_prova') }} as co_uf_prova,
    {{ enem_text('sg_uf_prova') }} as sg_uf_prova,

    -- attendance and booklets
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    {{ enem_int('tp_presenca_' ~ area) }} as tp_presenca_{{ area }},
    {{ enem_int('co_prova_' ~ area) }} as co_prova_{{ area }},
    {% endfor -%}
    {{ enem_int('tp_lingua') }} as tp_lingua,

    -- scores
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    {{ enem_double('nu_nota_' ~ area) }} as nu_nota_{{ area }},
    {% endfor -%}
    {{ enem_int('tp_status_redacao') }} as tp_status_redacao,
    {% for i in range(1, 6) -%}
    {{ enem_double('nu_nota_comp' ~ i) }} as nu_nota_comp{{ i }},
    {% endfor -%}
    {{ enem_double('nu_nota_redacao') }} as nu_nota_redacao,

    -- answer sheets
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    {{ enem_text('tx_respostas_' ~ area) }} as tx_respostas_{{ area }},
    {{ enem_text('tx_gabarito_' ~ area) }} as tx_gabarito_{{ area }},
    {% endfor -%}

    -- socioeconomic questionnaire (letters; q005 is a head count written as "4.0" in 2019)
    {% for i in range(1, 26) -%}
    {%- set q = 'q%03d' % i -%}
    {% if q in ['q024', 'q025'] and year == 2024 -%}
    cast(null as varchar) as {{ q }},
    {%- elif q == 'q005' -%}
    cast({{ enem_int(q) }} as varchar) as q005,
    {%- else -%}
    {{ enem_text(q) }} as {{ q }},
    {%- endif %}
    {% endfor %}
    _source_file,
    _ingested_at
from {{ source('bronze', 'enem_microdados_' ~ year) }}
{% if not loop.last %}union all{% endif %}
{% endfor %}
