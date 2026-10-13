{#
  Grain: one active school (tp_situacao_funcionamento = 1) in one Censo Escolar year. INEP 2024 publishes
  no details for paralisadas/extintas, so keeping only active schools makes both years comparable; the
  closed ones are still in dim_escola. A count INEP left blank for an active school stays NULL.
#}

select
    e.chave_escola,
    {{ edition_date_key('c.nu_ano_censo', 'censo_data_referencia') }} as chave_data,
    l.chave_localizacao,
    i.chave_infraestrutura,
    t.chave_tecnologia,
    pr.chave_profissionais,

    -- devices for students
    c.qt_desktop_aluno, c.qt_comp_portatil_aluno, c.qt_tablet_aluno,

    -- staff
    c.qt_prof_administrativos, c.qt_prof_servicos_gerais, c.qt_prof_bibliotecario, c.qt_prof_coordenador,
    c.qt_prof_psicologo, c.qt_prof_pedagogia, c.qt_prof_secretario, c.qt_prof_seguranca, c.qt_prof_monitores,
    c.qt_prof_gestao, c.qt_prof_assist_social,

    -- enrollments (bas = all of basic education), by level and by sex / race
    c.qt_mat_bas, c.qt_mat_inf, c.qt_mat_fund, c.qt_mat_med, c.qt_mat_prof, c.qt_mat_eja, c.qt_mat_esp,
    c.qt_mat_bas_fem, c.qt_mat_bas_masc,
    c.qt_mat_bas_branca, c.qt_mat_bas_preta, c.qt_mat_bas_parda, c.qt_mat_bas_indigena,

    -- teachers and classes by level
    c.qt_doc_bas, c.qt_doc_fund, c.qt_doc_med, c.qt_doc_prof, c.qt_doc_eja, c.qt_doc_esp,
    c.qt_tur_bas, c.qt_tur_fund, c.qt_tur_med, c.qt_tur_prof, c.qt_tur_eja, c.qt_tur_esp
from {{ censo_escolas_ativas() }} c
join {{ ref('dim_escola') }} e on e.co_escola = c.co_entidade
join {{ ref('dim_localizacao') }} l on l.co_municipio = c.co_municipio
{{ join_junk_dimension('dim_infraestrutura', 'i', infraestrutura_columns(), 'c') }}
{{ join_junk_dimension('dim_tecnologia', 't', tecnologia_columns(), 'c') }}
{{ join_junk_dimension('dim_profissionais', 'pr', profissionais_columns(), 'c') }}
