--WF1: Rank products by revenue within each category
with revenue_products as (
select c.category,
		p.name as product_name,
		coalesce(sum(oi.quantity*oi.unit_price),0) as revenue
from order_items oi join orders o on o.id=oi.order_id
right join products p on oi.product_id=p.id
join categories c on p.category_id=c.id
where o.status in ('PAID', 'SHIPPED', 'DELIVERED')
group by p.name, c.category
)
select *, rank() over(partition by category order by revenue desc)
from revenue_products;

--WF2: Rank customers by total revenue.
with revenue_customers as (
select c.id as customer_id,
		c.name as customer_name,
		sum(oi.quantity*oi.unit_price) as revenue
from order_items oi join orders o on o.id=oi.order_id 
join customers c on o.customer_id=c.id 
where o.status in ('PAID', 'SHIPPED', 'DELIVERED')
group by c.id, c.name
)
select *, dense_rank() over(order by revenue desc) from revenue_customers;

--WF3: Monthly revenue trend using LAG()
with revenue_date as (
select extract(year from o.order_date) as year,
		extract(month from o.order_date) as month,
		sum(oi.quantity*oi.unit_price) as revenue
from orders o join order_items oi on o.id=oi.order_id 
where o.status in ('PAID', 'SHIPPED', 'DELIVERED')
group by year, month
)
select *,
		lag(revenue) over(order by year, month) as previous_month,
		revenue - lag(revenue) over(order by year, month) as difference
from revenue_date;

--WF4: Compare each month's revenue with the next month's revenue
with revenue_date as (
select extract(year from o.order_date) as year,
		extract(month from o.order_date) as month,
		sum(oi.quantity*oi.unit_price) as revenue
from orders o join order_items oi on o.id=oi.order_id 
where o.status in ('PAID', 'SHIPPED', 'DELIVERED')
group by year, month
)
select *,
		lead(revenue) over(order by year, month) as next_month,
		LEAD(revenue) over(order by year, month) - revenue as difference
from revenue_date;

--WF5: Calculate the cumulative monthly revenue over time
with revenue_date as (
select extract(year from o.order_date) as year,
		extract(month from o.order_date) as month,
		sum(oi.quantity*oi.unit_price) as revenue
from orders o join order_items oi on o.id=oi.order_id 
where o.status in ('PAID', 'SHIPPED', 'DELIVERED')
group by year, month
)
select *,
		sum(revenue) over(order by year, month) as cumulative_revenue
from revenue_date;