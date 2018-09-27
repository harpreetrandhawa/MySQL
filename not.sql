select distinct concat(ucase(cust.db),cust.id_sales_order_item)item_id,timestampdiff(hour,created_at,now()) from sales_order_item_custom cust
left outer join
replica_sales_order_item_erp erp on erp.item_id = concat(ucase(cust.db),cust.id_sales_order_item)
where status in('exported') and erp.item_id is null ;

Select * from replica_sales_order_item_erp  where item_id = 'SA1829083'


