{{ config(properties={"partitioning": "ARRAY['nu_ano_censo']"}) }}

{#
  One row per school per census year. The 2024 layout comes first; 2019-only columns are appended and
  NULL for 2024 (and vice versa). Types follow INEP's prefixes, see censo_column_type.
#}

{{ union_censo([source('bronze', 'censo_escolar_2024'), source('bronze', 'censo_escolar_2019')]) }}
