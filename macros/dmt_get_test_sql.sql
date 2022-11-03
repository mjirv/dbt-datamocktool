{% macro get_unit_test_sql(model, input_mapping, depends_on) %}
    {% set ns=namespace(
        test_sql="(select 1) raw_code",
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
        {% set ns.test_sql = ns.graph_model.raw_code %}

        {# before rendering -- check if test should be incremental #}
        {# suppose it is incremental if this is in input mapping #}
        {% if 'this' in input_mapping.keys() %}    
            {% set ns.test_sql = ns.test_sql|replace('is_incremental()','true') %}     
        {% endif %}

        {% for k,v in input_mapping.items() %}
            {# render the original sql and replacement key before replacing because v is already rendered when it is passed to this test #}
            {% set ns.test_sql = render(ns.test_sql)|replace(ns.rendered_keys[k], v) %}
        {% endfor %}

        {# after rendering .. replace this with project dataset and mocked ""this"" model #}
        {% if 'this' in input_mapping.keys() %}    
            {% set ns.test_sql = ns.test_sql|replace(this.dataset, model.dataset) %}     
            {% set ns.test_sql = ns.test_sql|replace(this.table, input_mapping.this) %}     
        {% endif %}

        {# mock_model_relation is the mocked model name #}
        {% set mock_model_relation = dbt_datamocktool._get_model_to_mock(
            model, suffix=('_dmt_' ~ modules.datetime.datetime.now().strftime("%S%f"))
        ) %}

        {{ log('var: ' ~ mock_model_relation, info=True) }}

        {# TODO create merge instead of create table or view if its an incremental test  #}
        {# if incremtental test then #}
            {# create base model from input  (copy seed into target table?) #}

        {% if 'this' in input_mapping.keys() %}    
            {# create base model from input  (copy seed into target table?) #}
            {{ log("copying base table", info=True) }}
            {% do dbt_datamocktool._create_mock_table_or_view(mock_model_relation, "select * from " ~ input_mapping.this) %}
            
            {# create merge statement to merge into base model #}
            {{ log("creating merge statement", info=True) }}
            {# need sql to be wrapped in parentheses  - see bq_generate_incremental_build_sql #}
            {% do dbt_datamocktool._create_mock_merge_table(mock_model_relation, "(" + ns.test_sql + ")", dest_columns=adapter.get_columns_in_relation(mock_model_relation)) %}
        {% else %}
            {# normal run #}
            {{ log("normal run", info=True) }}
            {% do dbt_datamocktool._create_mock_table_or_view(mock_model_relation, ns.test_sql) %}
        {% endif %}

    {% endif %}
    {% for k in depends_on %}
        -- depends_on: {{ k }}
    {% endfor %}
    
    {{ mock_model_relation }}
{% endmacro %}


{% macro _get_model_to_mock(model, suffix) %}
    {{ return(adapter.dispatch('_get_model_to_mock', 'dbt_datamocktool')(model, suffix)) }}
{% endmacro %}

{% macro default___get_model_to_mock(model, suffix) %}
    {{ return(make_temp_relation(model.incorporate(type='table'), suffix=suffix)) }}
{% endmacro %}

{# Spark-specific logic excludes a schema name in order to fix https://github.com/mjirv/dbt-datamocktool/issues/22 #}
{% macro spark___get_model_to_mock(model, suffix) %}
    {{ return(make_temp_relation(model.incorporate(type='table').include(schema=False), suffix=suffix)) }}
{% endmacro %}

{# SQL Server logic creates a view instead of a temp table to fix https://github.com/mjirv/dbt-datamocktool/issues/42 #}
{% macro sqlserver___get_model_to_mock(model, suffix) %}
    {% set schema = "datamocktool_tmp" %}
    {% if not adapter.check_schema_exists(database=model.database, schema=schema) %}
        {% do adapter.create_schema(api.Relation.create(database=model.database, schema=schema)) %}
    {% endif %}
    {% set tmp_identifier = model.identifier ~ suffix %}
    {# SQL Server requires us to specify a table type because it calls `drop_relation_script()` from `create_table_as()`.
    I'd prefer to use something like RelationType.table, but can't find a way to access the relation types #}
    {{ return(model.incorporate(type='view', path={"identifier": tmp_identifier, "schema": schema})) }}
{% endmacro %}


{% macro _create_mock_table_or_view(model, test_sql) %}
    {{ return(adapter.dispatch('_create_mock_table_or_view', 'dbt_datamocktool')(model, test_sql)) }}
{% endmacro %}

{% macro default___create_mock_table_or_view(model, test_sql) %}
    {% do run_query(create_table_as(True, model, test_sql)) %}
{% endmacro %}

{% macro sqlserver___create_mock_table_or_view(model, test_sql) %}
    {% do run_query(create_view_as(model, test_sql)) %}
{% endmacro %}

{% macro _create_mock_merge_table(model, test_sql, dest_columns) %}
    {{ return(adapter.dispatch('_create_mock_merge_table', 'dbt_datamocktool')(model, test_sql, dest_columns)) }}
{% endmacro %}

{% macro default___create_mock_merge_table(model, test_sql, dest_columns) %}
    {% do run_query(get_merge_sql(model, test_sql, dest_columns=dest_columns)) %}
{% endmacro %}