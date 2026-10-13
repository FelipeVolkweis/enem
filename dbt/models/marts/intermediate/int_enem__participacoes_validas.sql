{#
  fato_desempenho_enem's grain: every ENEM participation, absentees included, minus the 23 rows of 2019
  truncated in the source (no attendance code, or marked present without a published score). Those
  would otherwise turn into a score of 0 for a present participant, indistinguishable from a real 0.
  In the remaining rows a NULL score always means the participant missed that test (tp_presenca 0 = absent,
  2 = eliminated), which is what the fact zeroes.
#}

select *
from {{ ref('stg_enem__participantes') }}
where
    {%- for area in ['cn', 'ch', 'lc', 'mt'] %}
    tp_presenca_{{ area }} is not null
    and (tp_presenca_{{ area }} <> 1 or (co_prova_{{ area }} is not null and nu_nota_{{ area }} is not null))
    and
    {%- endfor %}
    -- the essay is written on day 1, with linguagens (lc)
    (tp_presenca_lc <> 1 or (tp_status_redacao is not null and nu_nota_redacao is not null
        {%- for i in range(1, 6) %} and nu_nota_comp{{ i }} is not null{% endfor %}))
