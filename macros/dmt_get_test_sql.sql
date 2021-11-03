{% macro get_unit_test_sql(model, input_mapping) %}
    {% set ns=namespace(
        test_sql="(select 1) raw_sql",
        rendered_keys={},
        graph_model=none
    ) %}

    {% for k in input_mapping.keys() %}
        -- depends on: {{ render("{{ " ~ k ~ " }}") }}
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

        {# SQL Server requires us to specify a table type because it calls `drop_relation_script()` from `create_table_as()`.
        I'd prefer to use something like RelationType.table, but can't find a way to access the relation types #}
        {% do adapter.create_schema(api.Relation.create(database=model.database, schema=model.schema)) %}
        {% set mock_model_relation = make_temp_relation(model.incorporate(type='table'), suffix=('_dmt_' ~ modules.datetime.datetime.now().strftime("%S%f") ~ '_')) %}

        {% do run_query(create_table_as(true, mock_model_relation, ns.test_sql)) %}
    {% endif %}

    {{ mock_model_relation }}
{% endmacro %}
