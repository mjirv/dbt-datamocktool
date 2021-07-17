{{
    config(materialized='view')
}}

select 1 as customer_id, 'Michael' as first_name, 'P.' as last_name
union all
select 2 as customer_id, 'Shawn' as first_name, 'M.' as last_name