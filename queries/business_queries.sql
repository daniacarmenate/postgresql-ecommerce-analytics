--Query 1: What are the top 10 best-selling products based on total units sold?
select pr, id, 
		pr.name, 
		sum(oi.quantity) as total_unit_sold 
from order_items oi inner join products pr 
on oi.product_id=pr.id 
group by pr.id, pr.name 
order by total_unit_sold desc limit 10;

--Query 2: Who are the top 10 customers by total spending?
with order_total as (
select a.id, 
		a.customer_id, 
		sum(b.quantity*b.unit_price) as total 
from orders a inner join order_items b 
on a.id=b.order_id 
where a.status not in ('PENDING') 
group by a.id, a.customer_id) 
select c.id, 
		c.name, 
		sum(t.total) as total_spend 
from customers c inner join order_total t 
on c.id=t.customer_id 
group by c.id, c.name 
order by total_spend desc limit 10;

--Query 3: Wich product categories generate the highest revenue?
SELECT
    c.category,
    SUM(oi.quantity * oi.unit_price) AS category_revenue
FROM categories c
JOIN products p
    ON c.id = p.category_id
JOIN order_items oi
    ON p.id = oi.product_id
JOIN orders o
    ON oi.order_id = o.id
WHERE o.status <> 'PENDING'
GROUP BY c.id, c.category
ORDER BY category_revenue DESC;


--Query 4: What are the monthly sales trends over time?
select extract(year from o.order_date) as year, 
		extract(month from o.order_date) as month, 
		sum(oi.quantity*oi.unit_price) as revenue 
from order_items oi inner join orders o 
on oi.order_id=o.id 
where o.status <> 'PENDING' 
group by extract(year from o.order_date), extract(month from o.order_date) 
order by year, month;

--Query 5: Which products have the lowest recorded inventory levels and may require restocking?
SELECT
    p.name,
    c.category,
    p.stock
FROM products p
JOIN categories c
    ON p.category_id = c.id
ORDER BY p.stock
LIMIT 10;

--Query 6: What would be the current inventory level after accounting for sales and returns?
with total_return_items as (
select product_id, sum(quantity) as total_return_prod
from return_items 
group by product_id
),
total_products as (select oi.product_id, sum(quantity) as total_prod
from order_items oi inner join orders o
on oi.order_id=o.id 
where o.status <> 'PENDING'
group by oi.product_id)
select p.name, c.category, p.stock + COALESCE(tri.total_return_prod, 0) - COALESCE(tp.total_prod, 0) as actual_stock
from products p left join total_return_items tri on p.id=tri.product_id 
left join total_products tp on p.id=tp.product_id 
join categories c on p.category_id=c.id 
order by actual_stock 
limit 10;

--Query 7: What is the return rate by product category?
with total_return_items as (
select product_id, sum(quantity) as total_return_prod
from return_items 
group by product_id
),
total_products as (select oi.product_id, sum(quantity) as total_prod
from order_items oi inner join orders o
on oi.order_id=o.id 
where o.status <> 'PENDING'
group by oi.product_id)
select c.category,
		sum(coalesce(tp.total_prod,0)) as sold_units,
		sum(coalesce(tri.total_return_prod,0)) as return_units,
		ROUND((sum(coalesce(tri.total_return_prod,0)) * 100.0 / NULLIF(SUM(COALESCE(tp.total_prod,0)), 0))::numeric, 2) as return_rate
from products p join categories c on p.category_id = c.id 
left join total_return_items tri on p.id = tri.product_id 
left join total_products tp on p.id=tp.product_id 
group by c.category
order by return_rate desc;

--Query 8: What is the average order value (AOV) by month?
with amount_total_orders as (
select order_id,
		sum(quantity*unit_price) as total_orders
from order_items
group by order_id
)
select extract(year from o.order_date) as year,
		extract(month from o.order_date) as month,
		round(avg(ato.total_orders)::numeric, 2) as avg_aov
from orders o inner join amount_total_orders ato 
on o.id=ato.order_id
where o.status <> 'PENDING'
group by year, month
order by year, month;
	
--Query 9: Which customers have placed the highest number of orders?
select c.id,
		c.name,
		count(o.id) as total_orders
from customers c left join orders o
on c.id=o.customer_id and o.status <> 'PENDING'
group by c.id, c.name
order by total_orders desc
limit 10;

--Query 10: Which customers have not placed any completed orders?
select c.id,
		c.name
from customers c   
where not exists(select 1 from orders o where o.status IN ( 'PAID', 'SHIPPED', 'DELIVERED') and c.id=o.customer_id)
order by c.id;

--Query 11: Which products have never been sold?
SELECT
    p.id,
    p.name,
    c.category
FROM products p
JOIN categories c
    ON p.category_id = c.id
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.id
    WHERE oi.product_id = p.id
      AND o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
)
ORDER BY p.id;

--Query 12: Which products have generated the highest revenue?
select oi.product_id,
		p.name,
		sum(oi.quantity * oi.unit_price) as revenue
from order_items oi join orders o on oi.order_id=o.id
join products p on oi.product_id = p.id
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by oi.product_id, p.name
order by revenue desc
limit 10;

--Query 13: Which customers have generated the highest revenue through completed purchases?
with total_order as (
select oi.order_id, sum(oi.quantity*oi.unit_price) as total_order
from order_items oi join orders o on oi.order_id=o.id
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by oi.order_id
)
select o.customer_id,
		c.name,
		sum(tot.total_order) as revenue
from orders o join total_order tot on o.id=tot.order_id 
join customers c on o.customer_id=c.id 
group by o.customer_id, c."name" 
order by revenue desc
limit 10;

--Query 14: Which payment methods generate the highest revenue?
select p.payment_method,
		sum(oi.quantity*oi.unit_price) as revenue
from orders o join order_items oi on o.id=oi.order_id 
join payments p on o.id=p.order_id 
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by p.payment_method 
order by revenue desc
;

--Query 15: What percentage of total revenue is generated by each product category?
with total_revenue as (
select sum(oi.quantity*oi.unit_price) as total_revenue 
from order_items oi join orders o on o.id=oi.order_id
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
)
select c.category,
		sum(oi.quantity*oi.unit_price) as revenue,
		ROUND((sum(oi.quantity*oi.unit_price)*100.0/tr.total_revenue)::numeric, 2) as revenue_contribution
from order_items oi join orders o on o.id=oi.order_id
join products p on p.id=oi.product_id join categories c on p.category_id=c.id
cross join total_revenue tr
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by c.category, tr.total_revenue;

--Query 16: Which products have been returned the most?
select ri.product_id,
		p.name,
		sum(ri.quantity) as units_returned
from return_items ri join products p
on ri.product_id=p.id 
group by ri.product_id, p.name
order by units_returned desc
limit 10;

--Query 17: Which categories have the highest return rates?
with total_return as (
select product_id, sum(quantity) as total_return
from return_items 
group by product_id 
),
total_sold as (
select oi.product_id, sum(oi.quantity) as total_sold
from order_items oi join orders o on oi.order_id=o.id 
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by product_id)
select c.category,
		sum(COALESCE(ts.total_sold, 0)) as units_sold,
		sum(COALESCE(tr.total_return, 0)) as units_returned,
		ROUND((sum(COALESCE(tr.total_return, 0))/nullif(sum(COALESCE(ts.total_sold, 0)),0) *100.0)::numeric,2) as return_rate
from products p join categories c on p.category_id = c.id
left join total_return tr on p.id=tr.product_id 
left join total_sold ts on p.id=ts.product_id 
group by category
order by return_rate desc;

--Query 18: Which customers have returned the highest number of products?
select o.customer_id, c.name,
		sum(ri.quantity) as units_returned
from orders o join customers c on o.customer_id=c.id
join returns r on o.id = r.order_id 
join return_items ri on r.id=ri.return_id
group by o.customer_id, c.name
order by units_returned desc 
limit 10;

--Query 19: What is the average number of items per order?
with total_prod_order as (
select oi.order_id, sum(oi.quantity) as total_per_order
from order_items oi join orders o
on o.id=oi.order_id 
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by  oi.order_id 
)
select ROUND(avg(total_per_order)::numeric, 2) as avg_items_per_order from total_prod_order;

--Query 20: Which month generated the highest revenue?
select extract(year from o.order_date) as year,
		extract(month from o.order_date) as month,
		sum(oi.quantity*oi.unit_price) as revenue
from orders o join order_items oi
on o.id=oi.order_id
where o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
group by year, month
order by revenue desc
limit 1;
