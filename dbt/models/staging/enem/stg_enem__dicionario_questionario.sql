{#
  Socioeconomic questionnaire dictionary for both editions. The q-codes are not stable across years
  (2019 q006 is family income, 2024 q006 is "do you have an income?"), so always join on nu_ano too.
  questao is lowercased to match the stg_enem__participantes column names.
#}

{% for year in [2019, 2024] %}
select
    {{ year }} as nu_ano,
    lower(trim(questao)) as questao,
    trim(descricao_questao) as descricao_questao,
    trim(alternativa_questao) as alternativa,
    trim(descricao_alternativa_questao) as descricao_alternativa
from {{ source('bronze', 'dicionario_questionario_socioeconomico_' ~ year) }}
{% if not loop.last %}union all{% endif %}
{% endfor %}
