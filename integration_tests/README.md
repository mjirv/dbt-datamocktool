# Integration Tests

This is based on the sample Jaffle Shop project provided by dbt Labs. I have made some modifications to include unit tests via datamocktool.

## Quickstart
1. Make sure your `.dbt/profile.yml` file has a `datamocktool` profile and that the schema is `jaffle_shop` (or change these in `dbt_project.yml` and `stg_customers.sql` to your preferred profile and schema)
2. Run `./run_integration_tests.sh` or `dbt deps && dbt seed && dbt test`