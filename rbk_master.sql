Select item_id,
order_nr, exportable_at, sku,
rbk.unit_price,order_item_status,rbk.exported_at,
(timestampdiff(minute,exportable_at,now())/60)hour_since,
location,
if(po_number='','No',po_number)po_number,
CASE
	WHEN allocated_at != '0000-00-00 00:00:00' AND shipped_at = '0000-00-00 00:00:00' THEN 'Allocated'
    WHEN po_number !='' and (arrived_at = '0000-00-00 00:00:00' OR shipped_at = '0000-00-00 00:00:00') THEN 'PO Created'
    ELSE 'TP Confirmation'
END as Status,

CASE 
	WHEN allocated_at != '0000-00-00 00:00:00' AND shipped_at = '0000-00-00 00:00:00' THEN 'No Action'
    WHEN po_number !='' and (allocated_at = '0000-00-00 00:00:00' AND shipped_at = '0000-00-00 00:00:00') and TIMESTAMPDIFF(MINUTE,ifnull(rbk.exportable_at,rbk.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
	WHEN po_number !='' and (allocated_at = '0000-00-00 00:00:00' AND shipped_at = '0000-00-00 00:00:00') and TIMESTAMPDIFF(MINUTE,ifnull(rbk.exportable_at,rbk.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 1440 AND 2160 THEN 'Handover priority 2'
	WHEN po_number !='' and (allocated_at = '0000-00-00 00:00:00' AND shipped_at = '0000-00-00 00:00:00') and TIMESTAMPDIFF(MINUTE,ifnull(rbk.exportable_at,rbk.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover priority 3'

	WHEN po_number ='' and TIMESTAMPDIFF(MINUTE,ifnull(rbk.exportable_at,rbk.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'TP Confirmation 1'
	WHEN po_number ='' and TIMESTAMPDIFF(MINUTE,ifnull(rbk.exportable_at,rbk.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 1440 AND 2160 THEN 'TP Confirmation 2'
	WHEN po_number ='' and TIMESTAMPDIFF(MINUTE,ifnull(rbk.exportable_at,rbk.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'TP Confirmation 3'

END Action,
if(vendor_code='','RVEND00001',vendor_code)vendor_code,
if(vendor_name='','R.B.K. Middle East LLC',vendor_name)vendor_code,
round(if(transfer_price='',paid_price,rbk.transfer_price),2)transfer_price,
po_created_at,
arrived_at,
shipped_at
from replica_rbk_sales_order_item_erp rbk

where rbk.order_item_status ='Released' or (arrived_at != '0000-00-00 00:00:00' AND shipped_at = '0000-00-00 00:00:00');

Select * from replica_rbk_sales_order_item_erp where shipped_at = '0000-00-00 00:00:00' 

