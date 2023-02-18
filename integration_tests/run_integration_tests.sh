dbt clean && \
dbt deps && \
dbt seed && \
dbt run --full-refresh && \
dbt run && \
dbt test && \
dbt test --threads 2