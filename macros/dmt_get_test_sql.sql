{% macro get_unit_test_sql(model, input_mapping) %}
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

        {# SQL Server requires us to specify a table type because it calls `drop_relation_script()` from `create_table_as()`.
        I'd prefer to use something like RelationType.table, but can't find a way to access the relation types #}
        {% if not adapter.check_schema_exists(database=model.database, schema=model.schema) %}
            {% do adapter.create_schema(api.Relation.create(database=model.database, schema=model.schema)) %}
        {% endif %}

        {% set mock_model_relation = dbt_datamocktool._get_model_to_mock(model, suffix=('_dmt_' ~ modules.datetime.datetime.now().strftime("%S%f"))) %}

        {% do run_query(create_table_as(false, mock_model_relation, ns.test_sql)) %}
    {% endif %}


    {{ mock_model_relation }}
{% endmacro %}

{# Spark-specific logic excludes a schema name in order to fix https://github.com/mjirv/dbt-datamocktool/issues/22 #}
{% macro _get_model_to_mock(model, suffix) %}
    {{ return(adapter.dispatch('_get_model_to_mock', 'dbt_datamocktool')(model, suffix)) }}
{% endmacro %}

{% macro default___get_model_to_mock(model, suffix) %}
    {% set tmp_identifier = model.identifier ~ suffix %}
    {{ return(model.incorporate(type='table', path={"identifier": tmp_identifier})) }}
{% endmacro %}

{% macro spark___get_model_to_mock(model, suffix) %}
    {% set tmp_identifier = model.identifier ~ suffix %}
    {{ return(model.incorporate(type='table', path={"identifier": tmp_identifier}).include(schema=False)) }}
{% endmacro %}