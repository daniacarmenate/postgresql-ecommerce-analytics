--MV 1: Customer revenue summary
create materialized view mv_customer_revenue as
WITH customer_orders AS (
    SELECT
        o.id,
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.id = oi.order_id
    WHERE o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
    GROUP BY o.id, o.customer_id
)
SELECT
    c.id AS customer_id,
    c.name AS customer_name,
    COUNT(co.customer_id) AS total_orders,
    COALESCE(SUM(co.revenue),0) AS total_revenue,
    COALESCE(ROUND(AVG(co.revenue)::numeric,2),0) AS avg_order_value
FROM customers c
LEFT JOIN customer_orders co
    ON c.id = co.customer_id
GROUP BY c.id, c.name;

SELECT *
FROM mv_customer_revenue;

--Para actualizar una MV
--REFRESH MATERIALIZED VIEW mv_customer_revenue;
--REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_revenue;

CREATE UNIQUE INDEX idx_mv_customer_revenue
ON mv_customer_revenue(customer_id);

--MV 2: How vas the bussiness performed each month?
create materialized view mv_monthly_sales_summary as
with info_orders as (
select o.id,
		sum(oi.quantity*oi.unit_price) as revenue
from order_items oi join orders o on o.id=oi.order_id
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by o.id
)
select extract(year from o.order_date) as year,
		extract(month from o.order_date) as month,
		count(o.id) as total_orders,
		sum(io.revenue) as total_revenue,
		ROUND(avg(io.revenue):: numeric, 2)  as average_order_value
from orders o join info_orders io on o.id=io.id
group by year, month;

