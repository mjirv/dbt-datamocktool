{% test unit_test(model, input_mapping, expected_output, name, description, compare_columns, depends_on) %}
    {% set test_sql = dbt_datamocktool.get_unit_test_sql(model, input_mapping, depends_on)|trim %}
    {% do return(dbt_utils.test_equality(expected_output, compare_model=test_sql, compare_columns=compare_columns)) %}
{% endtest %}

{% test assert_mock_eq(model, input_mapping, expected_output) %}
    {% do return(test_unit_test(model, input_mapping, expected_output)) %}
{% endtest %}

