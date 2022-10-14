{% test unit_test(model, input_mapping, expected_output, name, description, compare_columns, depends_on, test_case_list = []) %}
    {# Support iterating through list of test cases #}
    {% if test_case_list %}
    {% set error_count = namespace(value=0) %}
      {% for test_case in test_case_list %}        
        {# String substitution for inputs #}
        {% set individual_input_mapping = dict() %}
        {% for k, v in input_mapping.items() %}
          {# String substitution on the templated value #}
          {% set templated_value = v|replace('@', test_case)|replace('\\', '') %}
          {# Update copy of dictionary #}
          {% do individual_input_mapping.update({k: render('{{' ~ templated_value ~ '}}')}) %}
        {% endfor %}

        {# String substitution for expected output #}
        {# Equality test expects a Relation #}
        {% set full_path = render('{{' ~ expected_output|replace('@', test_case)|replace('\\', '') ~ '}}') %}
        {% set full_path_list = full_path.split('.') %}
        {% set individual_expected_output = adapter.get_relation(*full_path_list) %}

        {# Retrieve the SQL code with the input mapping applied, using mocked input #}
        {% set individual_test_sql = dbt_datamocktool.get_unit_test_sql(model, individual_input_mapping, depends_on, test_case) %}
        {# Retrieve the SQL code that compares the results between model and expected result #}
        {% set comparison_sql = dbt_utils.test_equality(individual_expected_output, compare_model=individual_test_sql, compare_columns=compare_columns) %}

        {% if execute %}
          {% set test_difference_count = run_query(comparison_sql).columns[0].values()[0] %}
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
    {# Backwards compatible when not using multiple test_case list #}
        {% set test_sql = dbt_datamocktool.get_unit_test_sql(model, input_mapping, depends_on)|trim %}
        {% do return(dbt_utils.test_equality(expected_output, compare_model=test_sql, compare_columns=compare_columns)) %}
    {% endif %}
{% endtest %}

{% test assert_mock_eq(model, input_mapping, expected_output) %}
    {% do return(test_unit_test(model, input_mapping, expected_output)) %}
{% endtest %}
