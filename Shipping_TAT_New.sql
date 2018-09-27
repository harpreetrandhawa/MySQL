SELECT
    t.item_id,    t.order_nr,    t.sku,    t.bids,
    CONCAT('"', REPLACE(REPLACE(REPLACE(REPLACE(t.item_name, '"', "'"), ',', ' '), ',', ' '), ' ', ' '), '"') as item_name,
    CONCAT('"', t.Super_Category,'"') as Super_Category,
    t.ExportableDateTime,    t.Hours_Since,    t.shipping_date,    t.type,
    t.po_number,    t.Status,    t.Action,    t.is_restricted,    t.vendor_code,    t.vendor_name,
    t.TP_Price,    t.owner,    t.max_shipping_date
FROM
    (select CONCAT(UCASE(ind.db),ind.id_sales_order_item)as item_id,
	order_status.order_nr,
    date_add(order_status.exported_at,interval 4 hour)exported_at,
	ind.sku as sku,
    ind.bids as bids,
	REPLACE(REPLACE(REPLACE(ind.item_name,',',''),'\n',''),'\r','') as item_name,
    order_status.unit_price,
    ind.status as bob_item_status,
	ifnull(wc.sup_category,'') as super_category,
    date_add(ifnull(erp.updated_at,order_status.exported_at),interval 4 hour)ExportableDateTime,
    DATE_ADD(DATE_ADD(ifnull(erp.updated_at,order_status.exported_at), INTERVAL 4 HOUR), INTERVAL IF(ind.db = 'SA', ind.seller_shipping_time_max_sa, ind.seller_shipping_time_max_ae) DAY) AS shipping_date,
	(TIMESTAMPDIFF(MINUTE,date_add(ifnull(erp.updated_at,order_status.exported_at),interval 4 hour),now())/60) AS Hours_Since,
	IF(mid(ind.sku,6,2) = 'NM','Namshi','Wadi')  AS type,
    ucase(ind.db) as order_location,
    CASE 
		WHEN erp.po_number = 'No' AND order_status.po_number ='' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'Yes' ELSE 'No' 
	END AS pending_PO,
	CASE WHEN order_status.po_number ='' and erp.po_number = 'No' then 'No' 
		WHEN erp.po_number='No' AND order_status.po_number!='' THEN order_status.po_number
        ELSE erp.po_number END as po_number,
	CASE 
		WHEN erp.po_number = 'No' AND order_status.po_number='' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'No PO' 
		WHEN erp.arrivel_datetime = 'No' and order_status.arrived_at is null THEN 0 
		WHEN erp.po_number <> 'No' AND order_status.po_number <>'' AND erp.arrivel_datetime <> 'No' AND order_status.arrived_at is NOT null THEN 1
		ELSE 0
	END AS arrival_quantity,
	CASE
		WHEN erp.pick_line = 'Yes' AND erp.location_code = 'DXB' THEN 'DXB Inventory pickup'
		WHEN erp.pick_line = 'Yes' AND erp.location_code = 'KSA' THEN 'KSA Inventory pickup'
		ELSE 'No'
	END AS picking_pending,
    erp.pick_registered,
    CASE 
		WHEN erp.arrivel_datetime <>'No' OR erp.pick_registered = 'Yes' THEN 'Arrived'
		WHEN erp.pick_line = 'Yes' AND erp.location_code = 'DXB' THEN 'DXB Inventory pickup'
		WHEN erp.pick_line = 'Yes' AND erp.location_code = 'KSA' THEN 'KSA Inventory pickup'
		WHEN erp.sales_order_item_id IS NULL THEN 'Not in ERP'
		WHEN erp.arrivel_datetime = 'No' AND (erp.po_number <> 'No' or order_status.po_number <>'') THEN 'PO Created'
		WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'TP Confirmation'
	END AS Status,
    CASE
		WHEN mid(ind.sku,6,2)='NM' THEN 'Namshi order'
		WHEN ind.status='confirmation_pending' THEN 'confirmation_pending'
		WHEN ind.status='shipped' THEN 'shipped'
		WHEN erp.pick_line = 'Yes' THEN 'Inventory Pickup'
		WHEN erp.arrivel_datetime = 'No' AND (erp.po_number <> 'No' or order_status.po_number <>'') AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
		WHEN erp.arrivel_datetime = 'No' AND (erp.po_number <> 'No' or order_status.po_number <>'') AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 1440 AND 2160 THEN 'Handover priority 2'
		WHEN erp.arrivel_datetime = 'No' AND (erp.po_number <> 'No' or order_status.po_number <>'') AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover priority 3'
		WHEN erp.sales_order_item_id IS NULL OR erp.arrivel_datetime <> 'No' OR erp.pick_registered = 'Yes' THEN 'No Action'
		WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 3600 THEN 'Hunting'
		WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 3600 AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'TP confirmation priority 1'
		WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'TP confirmation priority 2'
		WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,erp.updated_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'TP confirmation priority 3'
	END AS Action,
    CASE WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' then
		CASE
		WHEN ind.vendor_code = 'V00685'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find UAE Seller')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find KSA Seller')

		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find UAE Seller')

		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')
		END
    ELSE if(erp.vendor_code='None',order_status.vendor_code,erp.vendor_code) END as vendor_code,
    CASE WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' then
		CASE
		WHEN ind.vendor_code = 'V00685'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.seller_name,',',''),'\n',''),'\r',''),'Find UAE Seller')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.seller_name,',',''),'\n',''),'\r',''),'Find KSA Seller')

		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.seller_name,',',''),'\n',''),'\r',''),'Find UAE Seller')

		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.seller_name,',',''),'\n',''),'\r',''),'Find Seller')
		END
	 ELSE if(erp.vendor_name='None',order_status.vendor_name,erp.vendor_name) END as vendor_name,
    CASE WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' then
		CASE
		WHEN ind.vendor_code = 'V00685'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.TP,',',''),'\n',''),'\r',''),'')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.TP,',',''),'\n',''),'\r',''),'')

		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.TP,',',''),'\n',''),'\r',''),'')


		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.TP,',',''),'\n',''),'\r',''),'')
		END
    ELSE order_status.transfer_price END as TP_Price,
	CASE WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' then
		CASE
		WHEN ind.vendor_code = 'V00685'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.owner,',',''),'\n',''),'\r',''),'Not Assigned')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.owner,',',''),'\n',''),'\r',''),'Not Assigned')

		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.owner,',',''),'\n',''),'\r',''),'Not Assigned')

		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.owner,',',''),'\n',''),'\r',''),'Not Assigned')
		END
    ELSE CASE WHEN erp.vendor_code = 'V00013' THEN 'Namshi'ELSE
    IFNULL(REPLACE(REPLACE(REPLACE(owner.procurement_distribution,',',''),'\n',''),'\r',''),'Not Assigned') END END as owner,
    CASE WHEN restricted.bids is NULL then 0
     else 1 END as is_restricted,
	DATE_ADD(DATE(DATE_ADD(DATE(DATE_ADD(ifnull(erp.updated_at,order_status.exported_at), INTERVAL 4 HOUR)), INTERVAL IF(ind.db = 'SA', ind.seller_shipping_time_max_sa, ind.seller_shipping_time_max_ae) DAY)), INTERVAL (FLOOR((IF(ind.db = 'SA', ind.seller_shipping_time_max_sa, ind.seller_shipping_time_max_ae) + DAYOFWEEK(DATE(DATE(DATE_ADD(ifnull(erp.updated_at,order_status.exported_at), INTERVAL 4 HOUR)) - INTERVAL 6 DAY)))/7)) + 1 DAY)
	AS max_shipping_date
    
from nm_sourcing.sales_order_item_custom as ind 

	LEFT outer JOIN
	nm_sourcing.order_item_status as erp on concat(Ucase(db),id_sales_order_item) = erp.sales_order_item_id
    
    LEFT outer JOIN
	nm_sourcing.sales_order_item_erp as order_status on ind.db = order_status.db and ind.id_sales_order_item = order_status.id_sales_order_item
    
    LEFT OUTER JOIN
	my_procurement.restricted_bids as restricted on restricted.bids collate utf8_general_ci = ind.bids
    
    LEFT OUTER JOIN
	nm_sourcing.am_vendor_mapping as owner on owner.vendor_name = erp.vendor_code or owner.vendor_name = order_status.vendor_code
    
    LEFT OUTER JOIN
	(select bids,product_name,sup_category from wadi_catalog) as wc on wc.bids  = ind.bids
	
    LEFT OUTER JOIN
	my_procurement.all_vendor as first_vendor  on ind.bids = first_vendor.wadi_sku_num
    
    LEFT OUTER JOIN
	my_procurement.uae_vendor as uae_vendor  on ind.bids = uae_vendor.wadi_sku_num
    
    LEFT OUTER JOIN
	my_procurement.ksa_vendor as ksa_vendor  on ind.bids = ksa_vendor.wadi_sku_num

where ind.status in ('exported','exportable') group by 1) t
WHERE t.status in('TP Confirmation','PO Created','Arrived','DXB Inventory pickup','KSA Inventory pickup') AND t.max_shipping_date <= CURDATE() AND t.bids != 'W1315999999'