# datamocktool

## About
datamocktool (dmt) is a simple package for unit testing dbt projects.

Using dmt, you can create mock CSV seeds to stand in for the sources and refs that your models use
and test that the model produces the desired output (using another CSV seed).

## Quickstart
1. Install this package following the guide in the [dbt documentation](https://docs.getdbt.com/docs/building-a-dbt-project/package-management).
2. Add a variable called `dmt_mappings` to your `dbt_project.yml`. 
    * This variable tells dmt which seeds to use as mock inputs for your unit tests (You will define the outputs later, in `schema.yml`).
    * Follow the example below.
    * ```yaml
        vars:
          dmt_mappings:
            test_suite_1: # dmt allows you to define multiple test suites so that you can define multiple tests for the same model
              sources:
                raw:
                  customers: dmt__raw_customers_1 # source('raw', 'customers') becomes ref('dmt__raw_customers_1')
                  orders: dbt__raw_orders_1
              models:
                stg_payments: dmt__stg_payments_1 # ref('stg_payments') becomes ref('dmt__stg_payments_1')
                stg_orders: dbt__stg_orders_1
            test_suite_2:
              sources:
                raw:
                  customers: dmt__raw_customers_2
                  orders: dbt__raw_orders_2
              models:
                stg_payments: dmt__stg_payments_2
                stg_orders: dbt__stg_orders_2```
3. Add unit tests to your `schema.yml` files, using the following example: 
    * ```yaml
        - name: stg_payments
          tests:
            - dbt_datamocktool.unit_test:
                expected_output: ref('dmt__expected_stg_payments_1') # this should be a CSV of the expected output in your `seeds` directory
                tags: ['dmt_test_suite_1']
            - dbt_datamocktool.unit_test:
                expected_output: ref('dmt__expected_stg_payments_2')
                tags: ['dmt_test_suite_2']
          columns:
            ...```
4. Create CSVs for the input and output seeds you referenced above, and put them in your seed directory (typically `data/`).
    * See the `integration_tests/data/` folder in this project for some examples
5. To run tests, run the following (replacing `dmt_test_suite_1` with your test suite name): 
    * `dbt seed`
    * `dbt run -m <YOUR MODELS TO TEST> --vars "dmt_test_suite: dmt_test_suite_1"`
    * `dbt test -m tag:dmt_test_suite_1` 
    * Note that the mocks are only used to build models when running `dbt run` with a `dmt_test_suite` variable provided.
    This ensures that dmt does not conflict with your regular dbt runs.
        