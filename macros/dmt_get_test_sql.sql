

{% macro get_unit_test_sql(model, input_mapping) %}
    {% set ns=namespace(
        test_sql="(select 1) raw_sql",
        rendered_keys={}
    ) %}

    {% for k in input_mapping.keys() %}
        {% do ns.rendered_keys.update({k: render("{{ " + k + " }}")}) %}
    {% endfor %}

    {% if execute %}
        {% set graph_model = graph.nodes["model." + project_name + "." + model.name] %}
        {% set ns.test_sql = "( " + graph_model.raw_sql + " ) raw_sql" %}

        {% for k,v in input_mapping.items() %}
            {% set ns.test_sql = render(ns.test_sql)|replace(ns.rendered_keys[k], v) %}
        {% endfor %}
    {% endif %}

    {% do log(ns.test_sql, info=True) %}

    {{ render(ns.test_sql) }}
{% endmacro %}