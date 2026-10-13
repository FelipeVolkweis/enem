{{ config(properties={"partitioning": "ARRAY['chave_data']"}) }}

{#
  Grain: one participation of a participant in one ENEM edition, absentees included. A test the
  participant missed (tp_presenca_* 0 = absent, 2 = eliminated) has score 0, booklet 0 and, for the
  essay, tp_status_redacao 0 ("ausente", a code ENEM does not use). A real 0 also exists among present
  participants (e.g. a blank essay, tp_status_redacao 4), so analyses of scores filter on
  tp_presenca_<area> = 1 (essay: tp_presenca_lc = 1); a plain avg() would count absentees as 0.
#}

select
    a.chave_aluno,
    {{ edition_date_key('p.nu_ano', 'enem_data_prova') }} as chave_data,
    coalesce(e.chave_escola, 0) as chave_escola,

    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    p.tp_presenca_{{ area }},
    {% endfor -%}
    -- int_enem__participacoes_validas guarantees a NULL here only for a missed test
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    coalesce(p.co_prova_{{ area }}, 0) as co_prova_{{ area }},
    {% endfor -%}
    {% for area in ['cn', 'ch', 'lc', 'mt'] -%}
    coalesce(p.nu_nota_{{ area }}, 0) as nu_nota_{{ area }},
    {% endfor -%}
    coalesce(p.tp_status_redacao, 0) as tp_status_redacao,
    {% for i in range(1, 6) -%}
    coalesce(p.nu_nota_comp{{ i }}, 0) as nu_nota_comp{{ i }},
    {% endfor -%}
    coalesce(p.nu_nota_redacao, 0) as nu_nota_redacao
from {{ ref('int_enem__participacoes_validas') }} p
join {{ ref('dim_aluno') }} a on a.nu_sequencial = p.nu_inscricao
left join {{ ref('dim_escola') }} e on e.co_escola = p.co_escola
