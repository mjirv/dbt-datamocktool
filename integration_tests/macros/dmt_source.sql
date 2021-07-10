{% macro source(source_name, table_name) %}
    {% do return(dbt_datamocktool.source(source_name, table_name)) %}
{% endmacro %}