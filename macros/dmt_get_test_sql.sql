

{% macro get_unit_test_sql(model, input_mapping) %}
    {% set ns=namespace(
        test_sql="(select 1) raw_sql",
        rendered_keys={}
    ) %}

    {% for k in input_mapping.keys() %}
        {# doing this outside the execute block allows dbt to infer the proper dependencies #}
        {% do ns.rendered_keys.update({k: render("{{ " + k + " }}")}) %}
    {% endfor %}

    {% if execute %}
        {# inside an execute block because graph nodes aren't well-defined during parsing #}
        {% set graph_model = graph.nodes["model." + project_name + "." + model.name] %}
        {% set ns.test_sql = "( " + graph_model.raw_sql + " ) raw_sql" %}

        {% for k,v in input_mapping.items() %}
            {# render the original sql and replacement key before replacing because v is already rendered when it is passed to this test #}
            {% set ns.test_sql = render(ns.test_sql)|replace(ns.rendered_keys[k], v) %}
        {% endfor %}
    {% endif %}

    {{ render(ns.test_sql) }}
{% endmacro %}
