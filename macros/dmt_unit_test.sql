{%- test unit_test(model, input_mapping, expected_output, name, description, compare_columns, depends_on, exclude_columns) -%}
    {%- set test_sql = dbt_datamocktool.get_unit_test_sql(model, input_mapping, depends_on)|trim -%}
    {%- set test_report = dbt_datamocktool.test_equality(expected_output, name, compare_model=test_sql, compare_columns=compare_columns, exclude_columns=exclude_columns) -%}
    {{ test_report }}
{%- endtest -%}

{% test unit_test_incremental(model, input_mapping, expected_output, name, description, compare_columns, depends_on, exclude_columns) %}
    {%- set test_sql = dbt_datamocktool.get_unit_test_incremental_sql(model, input_mapping, depends_on)|trim -%}
    {%- set test_report = dbt_datamocktool.test_equality(expected_output, name, compare_model=test_sql, compare_columns=compare_columns, exclude_columns=exclude_columns) -%}
    {{ test_report }}
{% endtest %}

{%- macro test_equality(model, name, compare_model, compare_columns=None, exclude_columns=None) -%}

    {#-- Prevent querying of db in parsing mode. This works because this macro does not create any new refs. #}
    {%- if not execute or flags.WHICH == 'compile' -%}
        {{ return('') }}
    {%- endif -%}

    {#- setup -#}
    {%- do dbt_utils._is_relation(model, 'test_equality') -%}
    {#-
    If the compare_cols arg is provided, we can run this test without querying the
    information schema — this allows the model to be an ephemeral model
    -#}
    
    {%- if not exclude_columns -%}
        {%- set exclude_columns = [] -%}
    {%- endif -%}
    {%- if not compare_columns -%}
        {%- do dbt_utils._is_ephemeral(model, 'test_equality') -%}
    {%- else -%}
        {%- set all_columns = adapter.get_columns_in_relation(model) | map(attribute='quoted')  -%}
        {%- for col in all_columns -%}
            {%- set col = col|replace('"',"") -%}
            {# -- in bigquery columns seem to come quoted with ` #}
            {%- set col = col|replace('`',"") -%}
            {%- if col|upper not in compare_columns|upper -%}
                {%- do exclude_columns.append(col) -%}
            {%- endif -%}
        {%- endfor -%}
    {%- endif -%}

    {% set all_columns = adapter.get_columns_in_relation(model) %}
    {% set except = exclude_columns | map("lower") | list %}

    {% set cols = [] %}
    {% for col in all_columns %}  
        {% if col.column|lower not in except %} 
            {% if 'STRUCT' in col.data_type or 'ARRAY' in col.data_type %}  
                {% set _ = cols.append("TO_JSON_STRING(" + col.name + ") as " + col.name) %}
            {% elif 'FLOAT' in col.data_type %}
                {% set _ = cols.append("ROUND(" + col.name + ", 3) as " + col.name) %}
            {% else %}
                {% set _ = cols.append(col.name) %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {% set model_query %}
      SELECT 
        {{ cols|join(", ") }}
      FROM model
    {% endset %}

    {% set compare_model_query %}
      SELECT 
        {{ cols|join(", ") }}
      FROM compare_model
    {% endset %}

    {%- set tables_compared -%}
    {{ audit_helper.compare_queries(
        a_query = model_query,
        b_query = compare_model_query,
        summarize = False
    ) }}
    {%- endset -%}

    {#- Run the comparison query -#}
    {%- set test_report = run_query(tables_compared) -%}
    {%- if test_report.columns[0].values()|length -%}
        {%- set test_status = 1 -%}
    {%- else -%}
        {%- set test_status = 0 -%}
    {%- endif-%}

    {#- Print output if there are any rows within the table. -#}
    {%- if test_status == 1 -%}
        {{ dbt_datamocktool.print_color('{YELLOW}The test <' ~ name ~ '> failed with the differences:') }}
        {{ dbt_datamocktool.print_color('{RED}================================================================') }}
        {% do test_report.print_table() %}
        {{ dbt_datamocktool.print_color('{RED}================================================================') }}
    {%- endif -%}

    {{ return(tables_compared) }}
{%- endmacro -%}


{% macro print_color(string) %}
  {% do log(dbt_datamocktool.parse_colors(string ~ "{RESET}"), info=true) %}
{% endmacro %}


{% macro parse_colors(string) %}
  {{ return (string
      .replace("{RED}", "\x1b[0m\x1b[31m")
      .replace("{YELLOW}", "\x1b[0m\x1b[33m")
      .replace("{RESET}", "\x1b[0m")) }}
{% endmacro %}
