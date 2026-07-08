--Trigger 1: Actualizar stock automáticamente cuando se inserta un order_item
CREATE OR REPLACE FUNCTION update_product_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE products
    SET stock = stock - NEW.quantity
    WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$;

create trigger update_stock_products
after insert on order_items
for each row
execute function update_product_stock();

CREATE TABLE product_price_audit (
	audit_int bigint,
    product_id INT,
    old_price NUMERIC(10,2),
    new_price NUMERIC(10,2),
    change_date TIMESTAMP
);

--Trigger 2: Price Audit Trigger
create or replace function insert_product_audit()
returns trigger
language plpgsql
as $$
begin
	if old.price <> new.price then
		insert into product_price_audit (product_id, old_price, new_price, change_date)
		values (old.id, old.price, new.price, now());
	end if;
	return new;
end;
$$;

create trigger insert_prod_audit
after update on products
for each row
execute function insert_product_audit();
