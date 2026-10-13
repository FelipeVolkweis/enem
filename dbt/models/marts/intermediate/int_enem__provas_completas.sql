{#
  fato_desempenho_enem's grain: present (tp_presenca = 1; absent is 0, eliminated 2) at all four tests,
  with every score and booklet published, so the fact holds no NULLs.
#}

select *
from {{ ref('stg_enem__participantes') }}
where
    {%- for area in ['cn', 'ch', 'lc', 'mt'] %}
    tp_presenca_{{ area }} = 1 and co_prova_{{ area }} is not null and nu_nota_{{ area }} is not null and
    {%- endfor %}
    tp_status_redacao is not null and
    {%- for i in range(1, 6) %}
    nu_nota_comp{{ i }} is not null and
    {%- endfor %}
    nu_nota_redacao is not null
