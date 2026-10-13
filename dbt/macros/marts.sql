{# Helpers shared by the gold models in models/marts. #}

{#
  Deterministic bigint surrogate key over natural-key columns, so facts derive their foreign keys
  without joining back to the dimensions. NULLs hash to a sentinel, so junk-dimension combinations
  that differ only by a NULL stay distinct.
#}
{% macro surrogate_key(cols) -%}
    from_big_endian_64(xxhash64(to_utf8(concat_ws('|', array[
        {%- for c in cols %}coalesce(cast({{ c }} as varchar), '<null>'){{ ', ' if not loop.last }}{% endfor -%}
    ]))))
{%- endmacro %}

{# School key; participants without a school point at dim_escola's "unknown" row (-1). #}
{% macro escola_key(col) -%}
    case when {{ col }} is null then -1 else {{ surrogate_key([col]) }} end
{%- endmacro %}

{# yyyymmdd dim_data key of an edition, looked up in a year -> date var (enem_data_prova, censo_data_referencia). #}
{% macro edition_date_key(year_col, var_name) -%}
    case {{ year_col }}
        {%- for year, day in var(var_name).items() %}
        when {{ year }} then {{ day | replace('-', '') }}
        {%- endfor %}
    end
{%- endmacro %}

{# Censo Escolar columns grouped into the junk dimensions of fato_censo_escolar. #}
{% macro infraestrutura_columns() -%}
    {{ return([
        'in_predio_compartilhado',
        'in_agua_potavel', 'in_agua_rede_publica',
        'in_energia_rede_publica', 'in_energia_renovavel',
        'in_esgoto_rede_publica',
        'in_lixo_servico_coleta', 'in_tratamento_lixo_separacao', 'in_tratamento_lixo_reciclagem',
        'in_biblioteca', 'in_biblioteca_sala_leitura', 'in_cozinha',
        'in_laboratorio_ciencias', 'in_laboratorio_informatica',
        'in_patio_coberto', 'in_parque_infantil',
        'in_quadra_esportes', 'in_quadra_esportes_coberta',
        'in_refeitorio',
        'in_sala_diretoria', 'in_sala_leitura', 'in_sala_professor', 'in_secretaria', 'in_sala_atendimento_especial',
        'in_acessibilidade_corrimao', 'in_acessibilidade_elevador', 'in_acessibilidade_pisos_tateis',
        'in_acessibilidade_rampas', 'in_acessibilidade_sinal_sonoro', 'in_acessibilidade_sinal_tatil',
        'in_acessibilidade_sinal_visual', 'in_acessibilidade_inexistente',
        'qt_salas_utilizadas', 'qt_salas_utiliza_climatizadas', 'qt_salas_utilizadas_acessiveis',
    ]) }}
{%- endmacro %}

{% macro tecnologia_columns() -%}
    {{ return([
        'in_computador',
        'in_equip_impressora', 'in_equip_impressora_mult', 'in_equip_scanner',
        'in_equip_tv', 'in_equip_lousa_digital', 'in_equip_multimidia',
        'in_desktop_aluno', 'in_comp_portatil_aluno', 'in_tablet_aluno',
        'in_internet', 'in_internet_alunos', 'in_internet_administrativo',
        'in_internet_aprendizagem', 'in_internet_comunidade',
        'in_acesso_internet_computador', 'in_aces_internet_disp_pessoais',
        'tp_rede_local', 'in_banda_larga',
    ]) }}
{%- endmacro %}

{% macro profissionais_columns() -%}
    {{ return([
        'in_prof_administrativos', 'in_prof_servicos_gerais', 'in_prof_bibliotecario',
        'in_prof_coordenador', 'in_prof_psicologo', 'in_prof_pedagogia',
        'in_prof_secretario', 'in_prof_seguranca', 'in_prof_monitores',
        'in_prof_gestao', 'in_prof_assist_social',
    ]) }}
{%- endmacro %}

{# Junk dimension: one row per distinct combination of the given Censo Escolar columns. #}
{% macro junk_dimension(key_name, cols) -%}
select distinct
    {{ surrogate_key(cols) }} as {{ key_name }},
    {%- for c in cols %}
    {{ c }}{{ ',' if not loop.last }}
    {%- endfor %}
from {{ ref('stg_censo_escolar__escolas') }}
{%- endmacro %}
