dbt clean && \
dbt deps && \
dbt seed && \
dbt run && \
dbt test && \
dbt test --threads 2