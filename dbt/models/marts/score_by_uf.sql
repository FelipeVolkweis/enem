select
    uf,
    count(*) as students,
    avg(score) as avg_score
from {{ ref('stg_students') }}
group by uf
