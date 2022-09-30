{% macro individual_unit_test(model, input_mapping, expected_output, test_case) %}

  {% set new_input_mapping = dict() %}
  {% for k, v in input_mapping.items() %}
    {# String substitution on the templated value #}
    {% set templated_value = v|replace('@', test_case)|replace('\\', '') %}

    {# Update copy of dictionary #}
    {% do new_input_mapping.update({k: render('{{' ~ templated_value ~ '}}')}) %}
  {% endfor %}
  
  {# Retrieve the SQL code with the input mapping applied, using mocked input #}
  {% set test_sql = get_unit_test_sql(model=model, input_mapping=new_input_mapping, test_case=test_case) %}

  {# equality test expects a Relation #}
  {% set full_path = render('{{' ~ expected_output|replace('@', test_case)|replace('\\', '') ~ '}}') %}
  {% set full_path_list = full_path.split('.') %}
  {% set expected_output = adapter.get_relation(*full_path_list) %}
  
  {# Retrieve the SQL code that compares the results between model and expected result #}
  {% do return(dbt_utils.test_equality(expected_output, compare_model=test_sql)) %}

{% endmacro %}
---
{% test unit_test(model, input_mapping, expected_output, test_case_list = []) %}
    {# Support iterating through list of test cases #}
    {% if test_case_list %}
    {% set error_count = namespace(value=0) %}
      {% for test_case in test_case_list %}
        {% set unit_test_sql = individual_unit_test(model, input_mapping, expected_output, test_case) %}
        {% if execute %}
          {% set test_difference_count = run_query(unit_test_sql).columns[0].values()[0] %}
        {% else %}
          {% set test_difference_count = 0 %}
        {% endif %}

        {% if test_difference_count > 0 %}
          {# log errors with red font #}
          {{ log('\033[31m    [ERROR] >> TEST CASE FAILED: ' ~ test_case ~ ' | Number of incorrect records = ' ~ test_difference_count ~ '\033[m', info=True) }}
          {% set error_count.value = error_count.value + 1 %}
        {% endif %}
      {% endfor %}

      {% do return('select '~ error_count.value) %}  
      
    {% else %}
    {# Backwards compatible #}
        {% set test_sql = custom_get_unit_test_sql(model, input_mapping) %}
        {% do return(dbt_utils.test_equality(expected_output, compare_model=test_sql)) %}
    {% endif %}
{% endtest %}

{% test assert_mock_eq(model, input_mapping, expected_output) %}
    {% do return(test_unit_test(model, input_mapping, expected_output)) %}
{% endtest %}
