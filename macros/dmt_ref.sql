{% macro ref(model_name) %}
    {% if var('dmt_unit_test_suite', '') != '' %}
        {% if model_name in var('dmt_mappings')[var('unit_test_suite')]['refs'] %}
            {% do return(builtins.ref(var('dmt_mappings')[var('unit_test_suite')['refs'][model_name]])) %}
        {% endif %}
    {% endif %}

    {% do return(builtins.ref(model_name)) %}
{% endmacro %}