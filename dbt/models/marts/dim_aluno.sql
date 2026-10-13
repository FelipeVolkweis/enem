{#
  One row per ENEM participation. The microdata has no NU_SEQUENCIAL column, so the registration
  number (unique across editions) plays that role.
#}

select
    {{ surrogate_key(['nu_inscricao']) }} as chave_aluno,
    nu_inscricao as nu_sequencial,
    tp_lingua
from {{ ref('stg_enem__participantes') }}
