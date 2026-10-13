select
    cast(id as integer) as student_id,
    student_name,
    uf,
    cast(score as double) as score
from {{ ref('smoke_students') }}
