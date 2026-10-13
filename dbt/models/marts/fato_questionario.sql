{{ config(properties={"partitioning": "ARRAY['chave_data']"}) }}

{#
  Grain: one participant's answer to one questionnaire question in one ENEM edition (unanswered
  questions have no row). qt_resposta is always 1, so sums count respondents. Keys are looked up on the
  2.3M participants before unnesting their 25 answers, so the big side never joins dim_aluno/dim_escola.
#}

with participantes as (
    select
        a.chave_aluno,
        coalesce(e.chave_escola, 0) as chave_escola,
        p.nu_ano,
        {% for i in range(1, 26) %}p.{{ 'q%03d' % i }}{{ ',' if not loop.last }}{% endfor %}
    from {{ ref('stg_enem__participantes') }} p
    join {{ ref('dim_aluno') }} a on a.nu_sequencial = p.nu_inscricao
    left join {{ ref('dim_escola') }} e on e.co_escola = p.co_escola
),

respostas as (
    select p.chave_aluno, p.chave_escola, p.nu_ano, r.questao, r.alternativa
    from participantes p
    cross join unnest(
        array[{% for i in range(1, 26) %}'{{ 'q%03d' % i }}'{{ ',' if not loop.last }}{% endfor %}],
        array[{% for i in range(1, 26) %}{{ 'q%03d' % i }}{{ ',' if not loop.last }}{% endfor %}]
    ) as r (questao, alternativa)
    where r.alternativa is not null
)

-- Every answer decodes through the dictionary (tests/staging/assert_respostas_no_dicionario), so the inner join keeps them all.
select
    r.chave_aluno,
    r.chave_escola,
    {{ edition_date_key('r.nu_ano', 'enem_data_prova') }} as chave_data,
    q.chave_questionario,
    1 as qt_resposta
from respostas r
join {{ ref('dim_questionario') }} q
    on q.ano = r.nu_ano and q.questao = r.questao and q.alternativa_questao = r.alternativa
