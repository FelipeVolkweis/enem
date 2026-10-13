{#
  Calendar spanning every year an ENEM edition or Censo Escolar is filed under (see the
  enem_data_prova / censo_data_referencia vars). chave_data is the date as yyyymmdd.
#}

{%- set years = (var('enem_data_prova').keys() | list) + (var('censo_data_referencia').keys() | list) %}

with dias as (
    select d as data
    from unnest(sequence(date '{{ years | min }}-01-01', date '{{ years | max }}-12-31', interval '1' day)) as t (d)
)

select
    cast(date_format(data, '%Y%m%d') as integer) as chave_data,
    data,
    day(data) as dia,
    element_at(array['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'],
               day_of_week(data)) as nome_dia,
    month(data) as mes,
    element_at(array['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro',
                     'Outubro', 'Novembro', 'Dezembro'], month(data)) as nome_mes,
    quarter(data) as trimestre,
    case when month(data) <= 6 then 1 else 2 end as semestre,
    year(data) as ano,
    year(data) / 10 * 10 as decada
from dias
