{#- Unit test with seeds as the input as well as the output. -#}
{{ dbt_datamocktool.unit_test(
    model = ref('stg_customers'),
    input_mapping = {
        source('jaffle_shop', 'raw_customers'): ref('dmt__raw_customers_1')
    },
    expected_output = ref('dmt__expected_stg_customers_1'),
) }}
