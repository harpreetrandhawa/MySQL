Select sales_order_item_id from order_item_status 
where sales_order_item_id in 
(select concat(cust.db,cust.id_sales_order_item) from sales_order_item_custom_new cust 
Left outer join
replica_sales_order_item_erp erp on erp.item_id = concat(cust.db,cust.id_sales_order_item)
 where cust.status in ('exported','exportable') and cust.bids != 'W1315345634' and erp.canceled_at =0 and erp.po_created_at =0 and erp.arrived_at =0)
and pick_line ='No' and grn = 'No' and cross_dock = 'No' and pick_registered = 'No' and purchase_line = 'No';

