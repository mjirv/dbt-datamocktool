# datamocktool

## About
datamocktool (dmt) is a simple package for unit testing dbt projects.

Using dmt, you can create mock CSV seeds to stand in for the sources and refs that your models use
and test that the model produces the desired output (using another CSV seed).

## Quickstart
1. Install this package following the guide in the [dbt documentation](https://docs.getdbt.com/docs/building-a-dbt-project/package-management).
2. Add a variable called `dmt_mappings` to your `dbt_project.yml`. 
  1. This variable tells dmt which seeds to replace `ref()` and `source()` blocks with in your models.
  2. Follow the example below. Note the structure: Test Suite > refs/sources > schema name (for sources) > table/model name. The dictionary keys should be names of refs and sources in your project, and the values should be the _input_ seeds you want to use in your tests.
  3. ```yaml
        vars:
          dmt_mappings:
            test_suite_1:
              sources:
                raw:
                  customers: dmt__raw_customers_1
                  orders: dbt__raw_orders_1
              models:
                stg_payments: dmt__stg_payments_1
                stg_orders: dbt__stg_orders_1
            test_suite_2:
              sources:
                raw:
                  customers: dmt__raw_customers_2
                  orders: dbt__raw_orders_2
              models:
                stg_payments: dmt__stg_payments_2
                stg_orders: dbt__stg_orders_2```
  4. Add `dmt.unit_test` tests to your `schema.yml` files, using the following example:
    ```yaml
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
  5. Add the input and expected output seeds you referenced above to your `seeds` directory.
  6. To run tests, run `dbt seed && dbt run -m <YOUR MODELS TO TEST> --vars "dmt_test_suite: your_test_suite_name" && dbt test -m tag:your_test_suite_name

        