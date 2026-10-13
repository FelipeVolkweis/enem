-- The facts look their keys up with inner joins; none of them may lose source rows on the way.
with esperado as (
    select 'fato_desempenho_enem' as fato, count(*) as linhas from {{ ref('stg_enem__participantes') }} p where {{ enem_prova_completa('p') }}
    union all
    select 'fato_censo_escolar', count(*) from {{ ref('stg_censo_escolar__escolas') }} where tp_situacao_funcionamento = 1
    union all
    select 'fato_questionario', count(*)
    from {{ ref('stg_enem__participantes') }}
    cross join unnest(array[{% for i in range(1, 26) %}{{ 'q%03d' % i }}{{ ',' if not loop.last }}{% endfor %}]) as r (alternativa)
    where r.alternativa is not null
),

obtido as (
    select 'fato_desempenho_enem' as fato, count(*) as linhas from {{ ref('fato_desempenho_enem') }}
    union all
    select 'fato_censo_escolar', count(*) from {{ ref('fato_censo_escolar') }}
    union all
    select 'fato_questionario', count(*) from {{ ref('fato_questionario') }}
)

select e.fato, e.linhas as esperado, o.linhas as obtido
from esperado e
join obtido o on o.fato = e.fato
where e.linhas <> o.linhas
