{{ config(properties={"partitioning": "ARRAY['chave_data']"}) }}

{#
  Grain: one participant's answer to one questionnaire question in one ENEM edition (unanswered
  questions have no row). qt_resposta is always 1, so sums count respondents.
#}

with respostas as (
    select p.nu_inscricao, p.nu_ano, p.co_escola, r.questao, r.alternativa
    from {{ ref('stg_enem__participantes') }} p
    cross join unnest(
        array[{% for i in range(1, 26) %}'{{ 'q%03d' % i }}'{{ ',' if not loop.last }}{% endfor %}],
        array[{% for i in range(1, 26) %}{{ 'q%03d' % i }}{{ ',' if not loop.last }}{% endfor %}]
    ) as r (questao, alternativa)
    where r.alternativa is not null
)

select
    {{ surrogate_key(['nu_inscricao']) }} as chave_aluno,
    {{ escola_key('co_escola') }} as chave_escola,
    {{ edition_date_key('nu_ano', 'enem_data_prova') }} as chave_data,
    {{ surrogate_key(['nu_ano', 'questao', 'alternativa']) }} as chave_questionario,
    1 as qt_resposta
from respostas
