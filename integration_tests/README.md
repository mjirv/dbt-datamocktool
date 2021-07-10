# Integration Tests

This is based on the sample Jaffle Shop project provided by dbt Labs. I have made some modifications to include unit tests via datamocktool.

## Quickstart
1. Make sure your `.dbt/profile.yml` file has a `datamocktool` profile and that the schema is `jaffle_shop` (or change these in `dbt_project.yml` and `stg_customers.sql` to your preferred profile and schema)
2. Run `./run_integration_tests.sh` or the following commands:
    1. Verify that the unit tests work: Run `dbt deps && dbt seed && dbt run --vars "dmt_test_suite: test_suite_1" && dbt test -m tag:test_suite_1`
    2. Verify that running _without_ the unit tests also works: Run `dbt seed && dbt run && dbt test --exclude tag:test_suite_1`