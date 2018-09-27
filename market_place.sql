Select concat(ucase(cust.db),cust.id_sales_order_item)item_id,
erp.order_nr, erp.exportable_at, cust.sku, cust.bids, 
REPLACE(REPLACE(REPLACE(cust.item_name,',',''),'\n',''),'\r','') as item_name,

erp.unit_price,cust.status,erp.exported_at,
(timestampdiff(minute,exportable_at,now())/60)hour_since,
erp.location,
erp.po_number,
CASE
WHEN po_number !='' and arrived_at=0 then 'PO Created'
WHEN po_number ='' and arrived_at=0 then 'TP Confirmation'
END as Status,
case when erp.arrived_at !=0 then 'No Action'
when po_number !='' and arrived_at=0 and TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
when po_number !='' and arrived_at=0 and TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 1440 AND 2160 THEN 'Handover priority 2'
when po_number !='' and arrived_at=0 and TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover priority 3'
when po_number ='' and arrived_at=0 and  TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 3600 THEN 'Hunting'
when po_number ='' and arrived_at=0 and TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 2160 AND 3599 THEN 'TP confirmation 1'
when po_number ='' and arrived_at=0 and TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 1441 AND 2159 THEN 'TP confirmation 2'
when po_number ='' and arrived_at=0 and TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'TP confirmation 3'
END Action,
erp.vendor_code,
erp.vendor_name,
round(if(erp.transfer_price=0,erp.paid_price,erp.transfer_price),2)transfer_price,
ifnull(owner.procurement_distribution,'Not Assigned') as Owner,
DATE_ADD(DATE(DATE_ADD(DATE(DATE_ADD(erp.exportable_at, INTERVAL 4 HOUR)), INTERVAL IF(cust.db = 'SA', cust.seller_shipping_time_max_sa, cust.seller_shipping_time_max_ae) DAY)), 
INTERVAL (FLOOR((IF(cust.db = 'SA', cust.seller_shipping_time_max_sa, cust.seller_shipping_time_max_ae) 
+ DAYOFWEEK(DATE(DATE(DATE_ADD(ifnull(erp.exportable_at,erp.exported_at), INTERVAL 4 HOUR)) - INTERVAL 6 DAY)))/7)) + 1 DAY)
	AS max_shipping_date



from sales_order_item_custom cust
left outer join
replica_sales_order_item_erp erp on concat(ucase(cust.db),cust.id_sales_order_item) = erp.item_id
left outer join
replica_am_vendor_mapping owner on owner.vendor_name = erp.vendor_code

where cust.status in ('exported','exportable') and erp.location in ('DXBM','KSAM') and erp.arrived_at =0;

select * from sales_order_item_erp limit 5