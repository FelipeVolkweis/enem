-- Every questionnaire answer must decode through that year's dictionary.
with respostas as (
    select p.nu_ano, r.questao, r.alternativa
    from {{ ref('stg_enem__participantes') }} p
    cross join unnest(
        array[{% for i in range(1, 26) %}'{{ 'q%03d' % i }}'{{ ',' if not loop.last }}{% endfor %}],
        array[{% for i in range(1, 26) %}{{ 'q%03d' % i }}{{ ',' if not loop.last }}{% endfor %}]
    ) as r (questao, alternativa)
    where r.alternativa is not null
)

select r.nu_ano, r.questao, r.alternativa, count(*) as participantes
from respostas r
left join {{ ref('stg_enem__dicionario_questionario') }} d
    on d.nu_ano = r.nu_ano and d.questao = r.questao and d.alternativa = r.alternativa
where d.questao is null
group by 1, 2, 3
