{# fato_censo_escolar's grain: schools em atividade. INEP 2024 publishes no details for paralisadas/extintas. #}

select *
from {{ ref('stg_censo_escolar__escolas') }}
where tp_situacao_funcionamento = 1
