{%- macro unit_test(model, input_mapping, expected_output, name, description, compare_columns, depends_on) -%}
    {%- set test_sql = get_unit_test_sql(model, input_mapping, depends_on)|trim -%}

    {%- set test_report = test_equality(expected_output, name, compare_model=test_sql, compare_columns=compare_columns) -%}
    {%- do return(test_report) -%}
{%- endmacro -%}


{%- macro test_equality(model, name, compare_model, compare_columns=None) -%}

{%- set set_diff -%}
    count(*) + coalesce(abs(
        sum(case when which_diff = 'a_minus_b' then 1 else 0 end) -
        sum(case when which_diff = 'b_minus_a' then 1 else 0 end)
    ), 0)
{%- endset -%}

{#-- Needs to be set at parse time, before we return '' below --#}
{{ config(fail_calc = set_diff) }}

{#-- Prevent querying of db in parsing mode. This works because this macro does not create any new refs. #}
{%- if not execute -%}
    {{ return('') }}
{%- endif -%}

-- setup
{%- do dbt_utils._is_relation(model, 'test_equality') -%}

{#-
If the compare_cols arg is provided, we can run this test without querying the
information schema — this allows the model to be an ephemeral model
-#}

{%- if not compare_columns -%}
    {%- do dbt_utils._is_ephemeral(model, 'test_equality') -%}
    {%- set compare_columns = adapter.get_columns_in_relation(model) | map(attribute='quoted') -%}
{%- endif -%}

{%- set compare_cols_csv = compare_columns | join(', ') -%}

{%- set tables_compared -%}
with a as (

    select * from {{ model }}

),

b as (

    select * from {{ compare_model }}

),

a_minus_b as (

    select {{compare_cols_csv}} from a
    {{ dbt.except() }}
    select {{compare_cols_csv}} from b

),

b_minus_a as (

    select {{compare_cols_csv}} from b
    {{ dbt.except() }}
    select {{compare_cols_csv}} from a

),

unioned as (

    select 'actual' as which_diff, b_minus_a.* from b_minus_a
    union all
    select 'expected' as which_diff, a_minus_b.* from a_minus_b

)

select * from unioned
{%- endset -%}

    {#- Run the comparison query -#}
    {%- set test_report = run_query(tables_compared) -%}
    {#- Print output if there are any rows within the table. -#}
    {%- if test_report.columns[0].values()|length -%}
        {{ print_color('{YELLOW}The test <' ~ name ~ '> failed with the differences:') }}
        {{ print_color('{RED}================================================================') }}
        {% do test_report.print_table() %}
    {{ print_color('{RED}================================================================') }}
    {%- endif -%}

{{ return(tables_compared) }}
{%- endmacro -%}



{% macro print_color(string) %}
  {% do log(parse_colors(string ~ "{RESET}"), info=true) %}
{% endmacro %}

{% macro parse_colors(string) %}
  {{ return (string
      .replace("{RED}", "\x1b[0m\x1b[31m")
      .replace("{GREEN}", "\x1b[0m\x1b[32m")
      .replace("{YELLOW}", "\x1b[0m\x1b[33m")
      .replace("{RESET}", "\x1b[0m")) }}
{% endmacro %}
