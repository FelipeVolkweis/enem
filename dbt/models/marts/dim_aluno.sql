{#
  One row per ENEM participation. The microdata has no NU_SEQUENCIAL column, so the registration
  number (unique across editions) plays that role.
#}

select
    {{ sequential_key(['nu_inscricao']) }} as chave_aluno,
    nu_inscricao as nu_sequencial,
    {{ code_or_unknown('tp_lingua') }} as tp_lingua
from {{ ref('stg_enem__participantes') }}
