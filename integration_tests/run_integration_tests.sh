dbt clean && \
dbt deps && \
dbt seed && \
dbt test && \
dbt test --threads 2