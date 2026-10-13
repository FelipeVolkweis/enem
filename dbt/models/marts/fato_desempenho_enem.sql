{{ config(properties={"partitioning": "ARRAY['chave_data']"}) }}

{#
  Grain: one participant who sat the whole exam (all four tests on both days, essay included) in one
  ENEM edition, so every score is present. Participants absent on either day, and the few 2019 rows
  truncated in the source, are left out here. They stay in dim_aluno and fato_questionario, since the
  questionnaire is answered at registration.
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
where {{ enem_prova_completa('p') }}
