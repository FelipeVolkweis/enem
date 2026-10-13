{{ config(properties={"partitioning": "ARRAY['chave_data']"}) }}

{# Grain: one participant in one ENEM edition. #}

select
    {{ surrogate_key(['nu_inscricao']) }} as chave_aluno,
    {{ edition_date_key('nu_ano', 'enem_data_prova') }} as chave_data,
    {{ escola_key('co_escola') }} as chave_escola,

    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    tp_presenca_{{ area }},
    {% endfor -%}
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    co_prova_{{ area }},
    {% endfor -%}
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    nu_nota_{{ area }},
    {% endfor -%}
    tp_status_redacao,
    {% for i in range(1, 6) -%}
    nu_nota_comp{{ i }},
    {% endfor -%}
    nu_nota_redacao
from {{ ref('stg_enem__participantes') }}
