{#- Unit test with for an incremental model with redefining `{{this}}`. -#}
{{ dbt_datamocktool.unit_test_incremental(
    model = ref('stg_orders'),
    input_mapping = {
            ref('raw_orders'): ref('dmt__raw_orders_3'),
            "this": ref('dmt__current_state_orders_2')
    },
    expected_output = ref('dmt__expected_stg_orders_2'),
) }}
