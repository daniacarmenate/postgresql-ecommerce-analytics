--Index 1:
create index idx_orders_customer on orders(customer_id);

--Index 2:
CREATE INDEX idx_orders_status_date
ON orders(status, order_date);
