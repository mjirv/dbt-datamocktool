{% test assert_mock_eq(model, input_mapping, expected_output) %}
    {% set test_sql = dbt_datamocktool.get_unit_test_sql(model, input_mapping) %}

    {% do return(dbt_utils.test_equality(expected_output, compare_model=test_sql)) %}
{% endtest %}