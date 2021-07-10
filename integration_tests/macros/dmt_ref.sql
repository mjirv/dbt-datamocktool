{% macro ref(model) %}
    {% do return(dbt_datamocktool.ref(model)) %}
{% endmacro %}