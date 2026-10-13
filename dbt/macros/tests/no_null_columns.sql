{# Fails for every row with a NULL in any column: dimensions use 9 / 0 / 'NÃO INFORMADO' instead. #}
{% test no_null_columns(model) %}
    {%- set columns = adapter.get_columns_in_relation(model) if execute else [] %}
    select *
    from {{ model }}
    where {% for c in columns %}{{ c.name }} is null{{ ' or ' if not loop.last }}{% else %}false{% endfor %}
{% endtest %}
