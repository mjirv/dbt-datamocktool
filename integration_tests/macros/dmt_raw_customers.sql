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