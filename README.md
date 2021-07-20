# datamocktool

## About
datamocktool (dmt) is a simple package for unit testing dbt projects.

Using dmt, you can create mock CSV seeds to stand in for the sources and refs that your models use
and test that the model produces the desired output (using another CSV seed).

## Requirements
* dbt version 0.19.2 or greater
* Redshift, Postgres, or SQL Server (likely works on Snowflake and BigQuery but has not been specifically tested)

## Quickstart
1. Install this package by adding the following to your `packages.yml` file:
    * ```yaml
        - git: git@github.com:mjirv/dbt-datamocktool.git
          revision: 0.1.2-beta 
    * Note that for the revision, you can also use `0.1.2-beta-fishtown` if other packages require fishtown-analytics/dbt_utils instead of dbt-labs/dbt_utils
2. Create your mocks: sample inputs for your models and the expected outputs of those models given the inputs.
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

## Advanced Usage
Inputs can also be models, SQL statements, and/or macros instead of seeds. See `integration_tests/macros/dmt_raw_customers.sql` and the related test in `integration_tests/models/staging/schema.yml` where this is implemented (copied below).

Note that you must wrap your SQL in parentheses in order to create a valid subquery, as below.

Expected outputs _must_ be seeds or models because the `dbt_utils.equality` test expects a relation. If you want to write SQL instead of a CSV for the expectation, you can use a model that is materialized as a view. See `integration_tests/models/unit_test_helpers/dmt__expected_stg_customers_2.sql` where this is implemented (copied below).

Test:
```yaml
  - dbt_datamocktool.unit_test:
            input_mapping:
              source('jaffle_shop', 'raw_customers'): "{{ dmt_raw_customers() }}" # this is a macro
            expected_output: ref('dmt__expected_stg_customers_2') # this is a model
```

Model (expected output):
```sql
  {{
      config(materialized='view')
  }}

  select 1 as customer_id, 'Michael' as first_name, 'P.' as last_name
  union all
  select 2 as customer_id, 'Shawn' as first_name, 'M.' as last_name
```

Macro (input):
```sql
  {% macro dmt_raw_customers() %}
    (

    {% set records = [
        [1,"Michael","P."],
        [2,"Shawn","M."]
    ] %}

    {% for record in records %}
        select {{ record[0] }} as id, '{{ record[1] }}' as first_name, '{{ record[2] }}' as last_name
        {% if not loop.last %}
            union all
        {% endif %}
    {% endfor %}
    ) raw_customers
{% endmacro %}
```

