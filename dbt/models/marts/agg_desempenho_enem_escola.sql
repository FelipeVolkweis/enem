{#
  Aggregate of fato_desempenho_enem for dashboards (Superset): one row per school x ENEM edition x area,
  with how many participants were present for that area and the sum and average of their scores.
  chave_escola = 0 holds the participants who informed no school, so summing every school gives the
  national figures. Weighted averages over several rows are sum(soma_notas) / sum(qt_participantes).

  Areas: the four objective tests (present: tp_presenca_<area> = 1), the essay (redacao, written on
  the lc day, so tp_presenca_lc = 1) and the overall average (media_geral: the plain average of the
  five scores, for participants present on both days).
#}

with participacoes as (
    select
        f.*,
        d.ano,
        f.tp_presenca_cn = 1 and f.tp_presenca_ch = 1 and f.tp_presenca_lc = 1 and f.tp_presenca_mt = 1
            as presente_tudo
    from {{ ref('fato_desempenho_enem') }} f
    join {{ ref('dim_data') }} d on d.chave_data = f.chave_data
),

notas as (
    select p.chave_escola, p.ano, a.ordem, a.co_area, a.no_area, a.nota
    from participacoes p
    cross join unnest(
        array[1, 2, 3, 4, 5, 6],
        array['cn', 'ch', 'lc', 'mt', 'redacao', 'media_geral'],
        array['Ciências da Natureza', 'Ciências Humanas', 'Linguagens e Códigos', 'Matemática', 'Redação',
              'Média geral'],
        array[
            if(p.tp_presenca_cn = 1, p.nu_nota_cn),
            if(p.tp_presenca_ch = 1, p.nu_nota_ch),
            if(p.tp_presenca_lc = 1, p.nu_nota_lc),
            if(p.tp_presenca_mt = 1, p.nu_nota_mt),
            if(p.tp_presenca_lc = 1, p.nu_nota_redacao),
            if(p.presente_tudo, (p.nu_nota_cn + p.nu_nota_ch + p.nu_nota_lc + p.nu_nota_mt + p.nu_nota_redacao) / 5)
        ]
    ) as a (ordem, co_area, no_area, nota)
    where a.nota is not null
)

select
    n.chave_escola,
    n.ano,
    e.co_escola,
    e.no_entidade as no_escola,
    e.co_municipio_esc as co_municipio,
    e.no_municipio_esc as no_municipio,
    e.sg_uf_esc as sg_uf,
    e.tp_dependencia_adm_esc as tp_dependencia_adm,
    case e.tp_dependencia_adm_esc
        when 1 then 'Federal' when 2 then 'Estadual' when 3 then 'Municipal' when 4 then 'Privada'
        else 'NÃO INFORMADO'
    end as no_dependencia_adm,
    n.ordem as ordem_area,
    n.co_area,
    n.no_area,
    count(*) as qt_participantes,
    sum(n.nota) as soma_notas,
    avg(n.nota) as media_nota
from notas n
join {{ ref('dim_escola') }} e on e.chave_escola = n.chave_escola
group by 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
