{#
  Grain: one active school (tp_situacao_funcionamento = 1) in one Censo Escolar year. INEP 2024 publishes
  no details for paralisadas/extintas, so keeping only active schools makes both years comparable; the
  closed ones are still in dim_escola. INEP writes no zero enrollment/teacher/class counts: an active
  school with no regular students (e.g. only complementary activities or AEE) has all three blank, so
  those blanks are 0.
#}

{%- set zero_if_blank = [
    'qt_mat_bas', 'qt_mat_inf', 'qt_mat_fund', 'qt_mat_med', 'qt_mat_prof', 'qt_mat_eja', 'qt_mat_esp',
    'qt_mat_bas_fem', 'qt_mat_bas_masc', 'qt_mat_bas_branca', 'qt_mat_bas_preta', 'qt_mat_bas_parda', 'qt_mat_bas_indigena',
    'qt_doc_bas', 'qt_doc_fund', 'qt_doc_med', 'qt_doc_prof', 'qt_doc_eja', 'qt_doc_esp',
    'qt_tur_bas', 'qt_tur_fund', 'qt_tur_med', 'qt_tur_prof', 'qt_tur_eja', 'qt_tur_esp',
] %}

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

    -- enrollments (bas = all of basic education, also by sex / race), teachers and classes by level
    {%- for c in zero_if_blank %}
    coalesce(c.{{ c }}, 0) as {{ c }}{{ ',' if not loop.last }}
    {%- endfor %}
from {{ ref('int_censo_escolar__escolas_ativas') }} c
join {{ ref('dim_escola') }} e on e.co_escola = c.co_entidade
join {{ ref('dim_localizacao') }} l on l.co_municipio = c.co_municipio
{{ join_junk_dimension('dim_infraestrutura', 'i', infraestrutura_columns(), 'c') }}
{{ join_junk_dimension('dim_tecnologia', 't', tecnologia_columns(), 'c') }}
{{ join_junk_dimension('dim_profissionais', 'pr', profissionais_columns(), 'c') }}
