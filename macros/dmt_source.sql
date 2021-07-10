{% macro source(source_name, table_name) %}
    {% if var('dmt_test_suite', '') != '' %}
        {% set mapping_dict = var('dmt_mappings')[var('dmt_test_suite')]['sources'] %}
        {% if source_name in mapping_dict %}
            {% if table_name in mapping_dict[source_name] %}
                {% do return(builtins.ref(mapping_dict[source_name][table_name])) %}
            {% endif %}
        {% endif %}
    {% endif %}

    {% do return(builtins.source(source_name, table_name)) %}
{% endmacro %}