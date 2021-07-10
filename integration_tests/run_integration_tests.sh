dbt deps && dbt seed && dbt run --vars "dmt_test_suite: test_suite_1" && dbt test -m tag:test_suite_1 || exit 1
dbt seed && dbt run && dbt test --exclude tag:test_suite_1 || exit 1