{% macro test_dbt_unit_test(model, expected_output) %}
    {{ dbt_utils.test_equality(model, compare_model=expected_output) }}
{% endmacro %}