# datamocktool

## About
datamocktool (dmt) is a simple package for unit testing dbt projects.

Using dmt, you can create mock CSV seeds to stand in for the sources and refs that your models use
and test that the model produces the desired output (using another CSV seed).

## Quickstart
1. Install this package by adding the following to your `packages.yml` file:
    * ```yaml
        - git: git@github.com:mjirv/dbt-datamocktool.git
          revision: 0.1.0-beta
2. Create your mock CSVs: sample inputs for your models and the expected outputs of those models given the inputs.
    * Save them to your seeds directory (usually `data/`; note that you can use any folder structure you would like within that directory)
    * See the `integration_tests/data/` directory of this project for some examples
3. Define your tests: Add unit tests to your `schema.yml` files, using the following example: 
    * ```yaml
        models:
        - name: stg_customers
          tests:
            - dbt_datamocktool.unit_test:
                input_mapping:
                  source('jaffle_shop', 'raw_customers'): ref('dmt__raw_customers_1')
                expected_output: ref('dmt__expected_stg_customers_1')
          columns:
            ...

        - name: stg_orders
          tests:
            - dbt_datamocktool.unit_test:
                input_mapping:
                  ref('raw_orders'): ref('dmt__raw_orders_1')
                expected_output: ref('dmt__expected_stg_orders_1')
          columns:
            ...
4. Run your tests: `dbt deps && dbt seed && dbt test`
        