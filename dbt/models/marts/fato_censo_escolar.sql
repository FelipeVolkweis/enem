{# Grain: one school in one Censo Escolar year. #}

select
    {{ escola_key('co_entidade') }} as chave_escola,
    {{ edition_date_key('nu_ano_censo', 'censo_data_referencia') }} as chave_data,
    {{ surrogate_key(['co_municipio']) }} as chave_localizacao,
    {{ surrogate_key(infraestrutura_columns()) }} as chave_infraestrutura,
    {{ surrogate_key(tecnologia_columns()) }} as chave_tecnologia,
    {{ surrogate_key(profissionais_columns()) }} as chave_profissionais,

    -- devices for students
    qt_desktop_aluno, qt_comp_portatil_aluno, qt_tablet_aluno,

    -- staff
    qt_prof_administrativos, qt_prof_servicos_gerais, qt_prof_bibliotecario, qt_prof_coordenador,
    qt_prof_psicologo, qt_prof_pedagogia, qt_prof_secretario, qt_prof_seguranca, qt_prof_monitores,
    qt_prof_gestao, qt_prof_assist_social,

    -- enrollments (bas = all of basic education), by level and by sex / race
    qt_mat_bas, qt_mat_inf, qt_mat_fund, qt_mat_med, qt_mat_prof, qt_mat_eja, qt_mat_esp,
    qt_mat_bas_fem, qt_mat_bas_masc,
    qt_mat_bas_branca, qt_mat_bas_preta, qt_mat_bas_parda, qt_mat_bas_indigena,

    -- teachers and classes by level
    qt_doc_bas, qt_doc_fund, qt_doc_med, qt_doc_prof, qt_doc_eja, qt_doc_esp,
    qt_tur_bas, qt_tur_fund, qt_tur_med, qt_tur_prof, qt_tur_eja, qt_tur_esp
from {{ ref('stg_censo_escolar__escolas') }}
