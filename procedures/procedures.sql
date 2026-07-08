--Cancel all pending orders older than 30 days
create or replace procedure cancel_old_pending_orders()
language plpgsql
as $$
DECLARE
	v_rows_updated int;
begin
	UPDATE orders
	SET status = 'CANCELLED'
	WHERE status = 'PENDING'
	AND order_date < CURRENT_DATE - INTERVAL '30 days';
	GET DIAGNOSTICS v_rows_updated = ROW_COUNT;
end;
$$;

CALL cancel_old_pending_orders();


create or replace procedure refresh_reporting_data()
language plpgsql
as $$
begin
	refresh materialized view mv_customer_revenue;
	refresh materialized view mv_monthly_sales_summary;
end;
$$;

CALL refresh_reporting_data();