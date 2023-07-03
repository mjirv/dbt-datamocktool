{{ dbt_datamocktool.unit_test(
    model = ref('stg_orders'),
    input_mapping = {
        ref('raw_orders'): ref('dmt__raw_orders_1')
    },
    expected_output = ref('dmt__expected_stg_orders_1'),
) }}
