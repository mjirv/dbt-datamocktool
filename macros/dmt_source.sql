{% macro source(schema_name, source_name) %}
    {% if var('dmt_test_suite', '') != '' %}
        {% set mapping_dict = "var('dmt_mappings')[var('dmt_test_suite')]['sources']" %}
        {% if schema_name in eval(mapping_dict) %}
            {% if model_name in eval(mapping_dict)[schema_name] %}
                {% do return(builtins.ref(eval(mapping_dict)[schema_name][source_name])) %}
            {% endif %}
        {% endif %}
    {% endif %}

    {% do return(builtins.source(schema_name, source_name)) %}
{% endmacro %}