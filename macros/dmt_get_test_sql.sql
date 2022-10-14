{% macro get_unit_test_sql(model, input_mapping, depends_on, test_case=none) %}
    {% set ns=namespace(
        test_sql="(select 1) raw_sql",
        rendered_keys={},
        graph_model=none
    ) %}

    {% for k in input_mapping.keys() %}
        {# doing this outside the execute block allows dbt to infer the proper dependencies #}
        {% do ns.rendered_keys.update({k: render("{{ " + k + " }}")}) %}
    {% endfor %}

    {% if execute %}
        {# inside an execute block because graph nodes aren't well-defined during parsing #}
        {% set ns.graph_model = graph.nodes.get("model." + project_name + "." + model.name) %}
        {# if the model uses an alias, the above call was unsuccessful, so loop through the graph to grab it by the alias instead #}
        {% if ns.graph_model is none %}
            {% for node in graph.nodes.values() %}
                {% if node.alias == model.name and node.schema == model.schema %}
                    {% set ns.graph_model = node %}
                {% endif %}
            {% endfor %}
        {% endif %}
        {% set ns.test_sql = ns.graph_model.raw_sql %}

        {% for k,v in input_mapping.items() %}
            {# render the original sql and replacement key before replacing because v is already rendered when it is passed to this test #}
            {% set ns.test_sql = render(ns.test_sql)|replace(ns.rendered_keys[k], v) %}
        {% endfor %}

        {# Store model result for visibility in case of unit test failure #}
        {% set identifier_name = model.name %}
        {% if test_case %}
            {% set identifier_name = identifier_name ~ '__test_case_'~test_case %}        
        {% endif %}
        {# Note: possible to hardcode desired database.schema to store the mocked model output #}
        {% set mock_model_relation = api.Relation.create(
                    database=model.database,
                    schema=model.schema,
                    identifier=identifier_name,
                    type='view') %}
        {# Create view to expose full definition #}
        {% do run_query(create_view_as(relation, ns.test_sql)) %}

    {% endif %}

    {% for k in depends_on %}
        -- depends_on: {{ k }}
    {% endfor %}
    
    {{ mock_model_relation }}
{% endmacro %}
