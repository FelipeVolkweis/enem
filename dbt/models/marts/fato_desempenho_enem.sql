{{ config(properties={"partitioning": "ARRAY['chave_data']"}) }}

{#
  Grain: one participant who sat at least one ENEM test, in one edition. Those absent on both days have
  no score at all and are left out (they stay in dim_aluno and fato_questionario, since the questionnaire
  is answered at registration). A participant who missed one day keeps NULL scores for that day's tests,
  so avg() covers only those who sat each test.
#}

select
    a.chave_aluno,
    {{ edition_date_key('p.nu_ano', 'enem_data_prova') }} as chave_data,
    coalesce(e.chave_escola, 0) as chave_escola,

    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    p.tp_presenca_{{ area }},
    {% endfor -%}
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    p.co_prova_{{ area }},
    {% endfor -%}
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    p.nu_nota_{{ area }},
    {% endfor -%}
    p.tp_status_redacao,
    {% for i in range(1, 6) -%}
    p.nu_nota_comp{{ i }},
    {% endfor -%}
    p.nu_nota_redacao
from {{ ref('stg_enem__participantes') }} p
join {{ ref('dim_aluno') }} a on a.nu_sequencial = p.nu_inscricao
left join {{ ref('dim_escola') }} e on e.co_escola = p.co_escola
where {{ enem_presente('p') }}
