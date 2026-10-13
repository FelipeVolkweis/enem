{#
  One row per (edition, question, answer option) of the socioeconomic questionnaire. The q-codes
  change meaning between editions, so the edition is part of the natural key.
#}

select
    {{ sequential_key(['nu_ano', 'questao', 'alternativa']) }} as chave_questionario,
    nu_ano as ano,
    questao,
    alternativa as alternativa_questao,
    descricao_questao,
    descricao_alternativa as descricao_alternativa_questao
from {{ ref('stg_enem__dicionario_questionario') }}
