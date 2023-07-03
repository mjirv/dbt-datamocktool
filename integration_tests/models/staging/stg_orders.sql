{{ config(materialized = "incremental", unique_key='order_id') }}

with source as (

    {#-
    Normally we would select from the table here, but we are using seeds to load
    our data in this project
    #}
    select * from {{ ref('raw_orders') }}
    {% if is_incremental() %}
        where id > (select max(order_id) from {{ this }}) or id = 2
    {% endif %}
),

renamed as (

    select
        id as order_id,
        user_id as customer_id,
        order_date,
        status

    from source

)

select * from renamed
