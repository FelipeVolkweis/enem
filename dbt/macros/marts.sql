{# Helpers shared by the gold models in models/marts. #}

{#
  NULL policy for dimensions: attributes are never NULL.
    tp_/in_ codes -> 9, INEP's own "não sabe / não informado" code (already used by e.g. tp_rede_local),
                     here also meaning "não se aplica" (tp_categoria_escola_privada of a public school).
    identifiers   -> 0 (only on the "unknown" member rows).
    names         -> 'NÃO INFORMADO'.
  Facts keep NULL measures: NULL means "not measured", which avg()/sum() then skip.
#}
{% macro code_or_unknown(expr) -%}
    coalesce({{ expr }}, 9)
{%- endmacro %}

{% macro name_or_unknown(expr) -%}
    coalesce({{ expr }}, 'NÃO INFORMADO')
{%- endmacro %}

{#
  Sequential surrogate key (1, 2, ...) ordered by the natural key, so a rebuild over the same data gives
  the same keys. Facts look keys up by joining on the natural key. 0 is reserved for "unknown" members.
#}
{% macro sequential_key(order_by) -%}
    cast(row_number() over (order by {{ order_by | join(', ') }}) as integer)
{%- endmacro %}

{# yyyymmdd dim_data key of an edition, looked up in a year -> date var (enem_data_prova, censo_data_referencia). #}
{% macro edition_date_key(year_col, var_name) -%}
    case {{ year_col }}
        {%- for year, day in var(var_name).items() %}
        when {{ year }} then {{ day | replace('-', '') }}
        {%- endfor %}
    end
{%- endmacro %}

{# fato_censo_escolar's grain: schools em atividade. INEP 2024 publishes no details for paralisadas/extintas. #}
{% macro censo_escolas_ativas() -%}
    (select * from {{ ref('stg_censo_escolar__escolas') }} where tp_situacao_funcionamento = 1)
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

{# A junk-dimension column as stored in the dimension: tp_/in_ codes NULL -> 9; qt_ counts stay as published. #}
{% macro junk_value(col, alias=none) -%}
    {%- set ref = (alias ~ '.' ~ col) if alias else col -%}
    {%- if col.startswith('qt_') -%}{{ ref }}{%- else -%}{{ code_or_unknown(ref) }}{%- endif -%}
{%- endmacro %}

{# Junk dimension: one row per distinct combination of the given columns among active schools. #}
{% macro junk_dimension(key_name, cols) -%}
with combinacoes as (
    select distinct
        {%- for c in cols %}
        {{ junk_value(c) }} as {{ c }}{{ ',' if not loop.last }}
        {%- endfor %}
    from {{ censo_escolas_ativas() }}
)

select {{ sequential_key(cols) }} as {{ key_name }}, *
from combinacoes
{%- endmacro %}

{# Join a junk dimension to census rows (alias `alias`) on all of its columns. #}
{% macro join_junk_dimension(dim, dim_alias, cols, alias) -%}
join {{ ref(dim) }} {{ dim_alias }} on
    {%- for c in cols %}
    {{ dim_alias }}.{{ c }} = {{ junk_value(c, alias) }}{{ ' and' if not loop.last }}
    {%- endfor %}
{%- endmacro %}

{# The value from the latest year in which it is not NULL (INEP leaves some fields blank in some years). #}
{% macro latest_non_null(col, year_col) -%}
    max_by({{ col }}, case when {{ col }} is not null then {{ year_col }} end)
{%- endmacro %}
