--Function 1: How much revenue has a specific customer generated?
create or replace function get_customer_revenue(
	p_customer_id int
)
returns numeric
language plpgsql
as $$
declare
	v_revenue numeric;
begin
	select coalesce(sum(oi.quantity*oi.unit_price),0)
	into v_revenue
	from orders o join order_items oi
	on o.id=oi.order_id
	where o.customer_id = p_customer_id and o.status in ('PAID', 'SHIPPED', 'DELIVERED');
	return v_revenue;
end;
$$;

SELECT get_customer_revenue(15);

--Function 2: How many completed orders has a customer placed?
create or replace function get_customer_orders_count(
	p_customer_id int 
)
returns integer
language plpgsql
as $$
declare 
	v_count_orders int;
begin
	select count(id)
	into v_count_orders
	from orders 
	where status in ('PAID', 'SHIPPED', 'DELIVERED') and customer_id=p_customer_id;
	return v_count_orders;
end;
$$;

SELECT get_customer_orders_count(15);

--Function 3: How much revenue has a category generated?
create or replace function get_category_revenue(
	p_category_name varchar
)
returns numeric(10,2)
language plpgsql
as $$
declare 
	v_category_revenue numeric;
begin
	select coalesce(sum(oi.quantity*unit_price),0) into v_revenue_category
	from products p  join order_items oi on p.id=oi.product_id
	join orders o on oi.order_id=o.id
	join categories c on p.category_id=c.id
	where UPPER(c.category) = upper(p_category_name) and o.status in ('PAID', 'SHIPPED', 'DELIVERED');
	return v_revenue_category;
end;
$$

SELECT get_revenue_category('sports');

--Function 4: What is the return rate of a specific product?
create or replace function get_product_return_rate(
	p_product_id INT 
)
returns numeric(10,2)
language plpgsql
as $$
declare
	v_return_rate numeric;
begin
	select return_rate into v_return_rate
	from vw_product_return_performance
	where product_id=p_product_id;
	RETURN v_return_rate;
end;
$$;

SELECT get_product_return_rate(15);

--Function 5: What customer tier does a customer belong to?
create or replace function get_customer_tier(
	p_customer_id int
)
returns varchar
language plpgsql
as $$
declare
	v_customer_revenue numeric;
begin
	v_customer_revenue := get_customer_revenue(p_customer_id);
	if v_customer_revenue <= 999.99 then
		return  'BRONZE';
	elsif v_customer_revenue >= 1000 AND v_customer_revenue <=2999.99 then
		return 'SILVER';
	elsif v_customer_revenue >= 3000 AND v_customer_revenue <=4999.99 then
		return 'GOLD';
	else return 'PLATINUM';
	end if;
end;
$$;