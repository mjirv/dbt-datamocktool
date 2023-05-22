{#- Unit test with macro as the input and a model as the expected output. -#}
{{ dbt_datamocktool.unit_test(
    model = ref('stg_customers'),
    input_mapping = {
        source('jaffle_shop', 'raw_customers'): "{{ dmt_raw_customers() }}"
    },
    expected_output = ref('dmt__expected_stg_customers_2'),
    name = "This test is a unit test",
) }}
