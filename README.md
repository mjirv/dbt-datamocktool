# datamocktool

## About

datamocktool (dmt) is a simple package for unit testing dbt projects.

Using dmt, you can create mock CSV seeds to stand in for the sources and refs that your models use
and test that the model produces the desired output (using another CSV seed).

## Requirements

- dbt version:
  - 1.3 or greater for datamocktool>=0.2.1
  - 1.0 or greater for datamocktool>=0.1.8
  - 0.19.2 or greater for datamocktool<0.1.8
- BigQuery, Redshift, Postgres, or SQL Server (likely works on Snowflake but has not been specifically tested)

## Quickstart

1. Install this package by adding the following to your `packages.yml` file:
   - ```yaml
     - package: mjirv/dbt_datamocktool
       version: [">=0.3.0"]
     ```
2. Create your mocks: sample inputs for your models and the expected outputs of those models given the inputs.
   - Save them to your seeds directory (usually `data/`; note that you can use any folder structure you would like within that directory)
   - See the `integration_tests/data/` directory of this project for some examples
3. Define your tests: Add unit tests to your `schema.yml` files, using the following example:

   - ```yaml
     models:
       - name: stg_customers
         tests:
           - dbt_datamocktool.unit_test:
               input_mapping:
                 source('jaffle_shop', 'raw_customers'): ref('dmt__raw_customers_1')
               expected_output: ref('dmt__expected_stg_customers_1')
               depends_on:
                 - ref('raw_customers')
         columns: ...

       - name: stg_orders
         tests:
           - dbt_datamocktool.unit_test:
               input_mapping:
                 ref('raw_orders'): ref('dmt__raw_orders_1')
               expected_output: ref('dmt__expected_stg_orders_1')
         columns: ...
     ```

4. Run your tests: `dbt deps && dbt seed && dbt test`

## Advanced Usage

### Using Other Materializations

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

### Test Names/Descriptions

You can add optional names and descriptions to your tests to make them easier to work with.

For example:

```yaml
- dbt_datamocktool.unit_test:
    input_mapping:
      source('jaffle_shop', 'raw_customers'): "{{ dmt_raw_customers() }}" # this is a macro
    expected_output: ref('dmt__expected_stg_customers_2') # this is a model
    name: "Raw Customers 2"
    description: "This test is a unit test"
```

will show up in your test run as follows:

```python
21:37:48 | 4 of 23 START test dbt_datamocktool_unit_test_stg_customers_This_test_is_a_unit_test__ref_dmt__expected_stg_customers_2____dmt_raw_customers___Raw_Customers_2 [RUN]
21:37:49 | 4 of 23 PASS dbt_datamocktool_unit_test_stg_customers_This_test_is_a_unit_test__ref_dmt__expected_stg_customers_2____dmt_raw_customers___Raw_Customers_2 [PASS in 0.27s]
```

### Include/exclude columns

If you only want to mock a few columns, you can do so and use the `compare_columns` field to tell the test which columns to look at, like so:

```yaml
models:
  - name: stg_customers
    tests:
      - dbt_datamocktool.unit_test:
          input_mapping:
            source('jaffle_shop', 'raw_customers'): ref('dmt__raw_customers_1')
          expected_output: ref('dmt__expected_stg_customers_1')
          compare_columns:
            - first_name
            - last_name
```

Alternatively, if you want to compare all columns apart from a few, you can use the `exclude_columns` field:

```yaml
models:
  - name: stg_customers
    tests:
      - dbt_datamocktool.unit_test:
          input_mapping:
            source('jaffle_shop', 'raw_customers'): ref('dmt__raw_customers_1')
          expected_output: ref('dmt__expected_stg_customers_1')
          exclude_columns:
            - description
```

### Manual Dependencies

Sometimes dbt won't pick up all the needed dependencies. You can manually add dependencies using `depends_on`:

```yaml
models:
  - name: stg_customers
    tests:
      - dbt_datamocktool.unit_test:
          input_mapping:
            source('jaffle_shop', 'raw_customers'): ref('dmt__raw_customers_1')
          expected_output: ref('dmt__expected_stg_customers_1')
          depends_on:
            - ref('raw_customers')
    columns: ...
```

### Incremental testing

You can test incremental models with the `unit_test_incremental` macro.

Steps:

1. Create a mock input corresponding to the initial state of the table
2. Use it as `this` in the input mapping

_NOTE: currently only the MERGE strategy is supported, so `unit_test_incremental` can only be used on databases that support it (BigQuery and Snowflake)._

```yaml
- name: stg_orders
  tests:
    - dbt_datamocktool.unit_test:
        input_mapping:
          ref('raw_orders'): ref('dmt__raw_orders_1')
        expected_output: ref('dmt__expected_stg_orders_1')
    - dbt_datamocktool.unit_test_incremental:
        input_mapping:
          ref('raw_orders'): ref('dmt__raw_orders_3')
          this: ref('dmt__current_state_orders_2')
        expected_output: ref('dmt__expected_stg_orders_2')
```

### Set the unit tests as macros

The unit tests can also be defined inside macros. This yields the disadvantage that not all the tests are defined at the same place, i.e. the yml file of the model. However, this allows to easlily run a specific unit test and enables easier selection criterias if the tests are for example run within a ci/cd pipeline, since all the tests can be excluded or included via their folder path within tests/.

To set a new test, a file has to be created within the tests/ folder like that:

```sql
{{ dbt_datamocktool.unit_test(
    model = ref('stg_customers'),
    input_mapping = {
        source('jaffle_shop', 'raw_customers'): ref('dmt__raw_customers_1')
    },
    expected_output = ref('dmt__expected_stg_customers_1'),
) }}
```

To make use of the other configuration possibilities, like inlcuding only specific columns, they can be simply added the same then in the yml files. If a specification consists out of multiple items, it has to explicitly be setup as a dictionary. Does one key contain multiple calues, it has to be added as a list. A complete example would look like that:

```sql
{{ dbt_datamocktool.unit_test(
  model = ref('<model_to_test>'),
  input_mapping = {
        ref('<input_one>'): ref('<replacement_one>'),
        ref('<input_two>'): ref('<replacement_two>')
    },
    expected_output = ref('<expected_output>'),
    name = '<Name of the unit test>',
    description = '<Description of the unit test>',
    compare_columns = ['<col_one>', '<col_two>'],
    depends_on = [ref('<dependency_one>'), ref('<dependency_two>')],
)}}
```

Up to this moment, not multiple tests can defined per file. It can be only one test macro per file.
