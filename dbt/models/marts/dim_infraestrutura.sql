{#
  Junk dimension: each distinct combination of the infraestrutura columns among active schools.
  NULL codes are stored as 9 (see code_or_unknown).
#}

{{ junk_dimension('chave_infraestrutura', infraestrutura_columns()) }}
