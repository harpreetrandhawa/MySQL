SELECT
    t.item_id,    t.order_nr,    t.sku,    t.bids,
    CONCAT('"', REPLACE(REPLACE(REPLACE(REPLACE(t.item_name, '"', "'"), ',', ' '), ',', ' '), ' ', ' '), '"') as item_name,
    CONCAT('"', t.Super_Category,'"') as Super_Category,
    t.ExportableDateTime,    t.Hours_Since,    t.shipping_date,    t.type,
    t.po_number,    t.Status,    t.Action,    t.is_restricted,    t.vendor_code,    t.vendor_name,
    t.TP_Price,    if(t.owner='NULL','Not Assigned',t.owner) as owner,    t.max_shipping_date,t.demo,t.po_created_at,
    CONCAT('"', t.category,'"') as category
FROM
    (select concat(UCASE(cust.db),cust.id_sales_order_item)as item_id,
	erp.order_nr,
    DATE_ADD(erp.exported_at,INTERVAL 4 HOUR)exported_at,
	cust.sku_config as sku,
    if(erp.po_created_at=0,'',erp.po_created_at)po_created_at,
    cust.bids as bids,
	REPLACE(REPLACE(REPLACE(cust.item_name,',',''),'\n',''),'\r','') as item_name,
    erp.unit_price,
    cust.status as bob_item_status,
	IFNULL(wc.sup_category,'') as Super_Category,
    ifnull(erp.exportable_at,erp.exported_at) + interval 4 hour as ExportableDateTime,
    DATE_ADD(DATE_ADD(ifnull(erp.exportable_at,erp.exported_at), INTERVAL 4 HOUR), INTERVAL IF(cust.db = 'SA', cust.seller_shipping_time_max_sa, cust.seller_shipping_time_max_ae) DAY) AS shipping_date,
	(TIMESTAMPDIFF(MINUTE,date_add(ifnull(erp.exportable_at,erp.exported_at),interval 4 hour),now())/60) AS Hours_Since,
	IF(mid(cust.sku_config,6,2) = 'NM','Namshi','Wadi') AS type,
    ucase(cust.db) as order_location,
    if(erp.po_number='','No',erp.po_number) po_number,
	CASE
		WHEN order_status.sales_order_item_id IS NULL and erp.item_id is null THEN 'Not in ERP'
		WHEN erp.arrived_at !=0 or erp.shipped_at !=0 or order_status.pick_registered = 'Yes' THEN 'Arrived'
		WHEN order_status.pick_line = 'Yes' AND order_status.location_code = 'DXB' THEN 'DXB Inventory pickup'
		WHEN order_status.pick_line = 'Yes' AND order_status.location_code = 'KSA' THEN 'KSA Inventory pickup'
		WHEN erp.arrived_at =0  and erp.shipped_at =0 and erp.po_created_at !=0 THEN 'PO Created'
		WHEN erp.po_created_at =0  and erp.arrived_at =0 and erp.shipped_at =0 THEN 'TP Confirmation'
	END AS Status,
    CASE
	WHEN order_status.sales_order_item_id IS NULL  and erp.item_id is null THEN 'Not in ERP'
	WHEN order_status.pick_line = 'Yes' THEN 'Inventory Pickup'
    WHEN erp.arrived_at !=0 or erp.shipped_at !=0 or order_status.pick_registered = 'Yes' THEN 'No Action'
	WHEN erp.arrived_at =0  and erp.shipped_at =0 and erp.po_created_at !=0 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
	WHEN erp.arrived_at =0  and erp.shipped_at =0 and erp.po_created_at !=0 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 1440 AND 2160 THEN 'Handover priority 2'
	WHEN erp.arrived_at =0  and erp.shipped_at =0 and erp.po_created_at !=0 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover priority 3'
	#---------
	WHEN erp.po_created_at =0  and erp.arrived_at =0 and erp.shipped_at =0 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 3600 THEN 'Hunting'
	WHEN erp.po_created_at =0  and erp.arrived_at =0 and erp.shipped_at =0 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 3600 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'TP confirmation priority 1'
	WHEN erp.po_created_at =0  and erp.arrived_at =0 and erp.shipped_at =0 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'TP confirmation priority 2'
	WHEN erp.po_created_at =0  and erp.arrived_at =0 and erp.shipped_at =0 AND TIMESTAMPDIFF(MINUTE,ifnull(erp.exportable_at,erp.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'TP confirmation priority 3'
END AS Action,
    CASE WHEN restricted.bids is NULL THEN 0 ELSE 1 END as is_restricted,
IFNULL(CASE WHEN erp.vendor_code !='' THEN erp.vendor_code 
	ELSE
		CASE WHEN restricted.bids IS NOT NULL AND cust.db = 'sa'
			THEN IFNULL(REPLACE(REPLACE(ksa_vendor.vendor_code,'\r',''),'\n',''),'Find KSA Seller')
			WHEN cust.db = 'ae'
			THEN IFNULL(REPLACE(REPLACE(uae_vendor.vendor_code,'\r',''),'\n',''),'Find DXB Seller')
		ELSE 
            IFNULL(REPLACE(REPLACE(first_vendor.vendor_code, '\r', ''), '\n', ''), 'Find Seller')
		END  
	END,'Null') as vendor_code,
    IFNULL(CASE WHEN erp.vendor_code !='' THEN erp.vendor_name 
	ELSE
		CASE WHEN restricted.bids IS NOT NULL AND cust.db = 'sa'
			THEN IFNULL(REPLACE(REPLACE(ksa_vendor.registered_name,'\r',''),'\n',''),'Find KSA Seller')
			WHEN cust.db = 'ae'
			THEN IFNULL(REPLACE(REPLACE(uae_vendor.registered_name,'\r',''),'\n',''),'Find DXB Seller')
		ELSE 
            IFNULL(REPLACE(REPLACE(first_vendor.registered_name, '\r', ''), '\n', ''), 'Find Seller')
		END  
	END,'Null') as vendor_name,
    IFNULL(CASE WHEN erp.vendor_code !='' THEN erp.transfer_price
	ELSE
		CASE WHEN restricted.bids IS NOT NULL AND cust.db = 'sa'
			THEN IFNULL(REPLACE(REPLACE(ksa_vendor.TP,'\r',''),'\n',''),'')
			WHEN cust.db = 'ae'
			THEN IFNULL(REPLACE(REPLACE(uae_vendor.TP,'\r',''),'\n',''),'')
		ELSE 
            IFNULL(REPLACE(REPLACE(first_vendor.TP, '\r', ''), '\n', ''), '')
		END  
	END,'') as TP_Price,
	IFNULL(CASE WHEN erp.vendor_code !='' THEN IFNULL(REPLACE(REPLACE(owner.procurement_distribution, '\r', ''), '\n', ''), 'Not Assigned') 
	ELSE
		CASE WHEN restricted.bids IS NOT NULL AND cust.db = 'sa'
			THEN IFNULL(REPLACE(REPLACE(ksa_vendor.procurement_owner,'\r',''),'\n',''),'Not Assigned')
			WHEN cust.db = 'ae'
			THEN IFNULL(REPLACE(REPLACE(uae_vendor.procurement_owner,'\r',''),'\n',''),'Not Assigned')
		ELSE 
            IFNULL(REPLACE(REPLACE(first_vendor.procurement_owner, '\r', ''), '\n', ''), 'Not Assigned')
		END  
	END,'Null') as owner,
    DATE_ADD(DATE(DATE_ADD(DATE(DATE_ADD(cust.updated_at, INTERVAL 4 HOUR)), INTERVAL IF(cust.db = 'SA', cust.seller_shipping_time_max_sa, cust.seller_shipping_time_max_ae) DAY)), INTERVAL (FLOOR((IF(cust.db = 'SA', cust.seller_shipping_time_max_sa, cust.seller_shipping_time_max_ae) + DAYOFWEEK(DATE(DATE(DATE_ADD(cust.updated_at, INTERVAL 4 HOUR)) - INTERVAL 6 DAY)))/7)) + 1 DAY)
	AS max_shipping_date,
	cust.vendor_code as demo,
    order_status.pick_line,
    ifnull(wc.category,'') as category
FROM sales_order_item_custom cust

LEFT outer JOIN
   nm_sourcing.replica_sales_order_item_erp erp on concat(ucase(cust.db),cust.id_sales_order_item) = erp.item_id 

left outer join
	nm_sourcing.zd_tickets_wadiff as wadiff on wadiff.item_id= erp.item_id

LEFT OUTER JOIN
   replica_wadi_catalog as wc on wc.bids  = ifnull(cust.seller_sku,cust.bids)

LEFT outer JOIN
   replica_order_item_status as order_status on concat(Ucase(cust.db),cust.id_sales_order_item) = order_status.sales_order_item_id

LEFT OUTER JOIN
   nm_sourcing.replica_restricted_items as restricted on restricted.bids = ifnull(cust.seller_sku,cust.bids)
   
LEFT OUTER JOIN
   nm_sourcing.replica_am_vendor_mapping as owner on owner.vendor_name = erp.vendor_code

LEFT OUTER JOIN
	(select * from vendor_ranking where in_stock !=0 order by rank ) as first_vendor  on ifnull(cust.seller_sku,cust.bids) = first_vendor.wadi_sku_num
LEFT outer JOIN
	(select * from vendor_ranking where in_stock !=0 and vendor_location = 'UAE' order by uae_rank) as uae_vendor on ifnull(cust.seller_sku,cust.bids) = uae_vendor.wadi_sku_num
LEFT outer JOIN
	(select * from vendor_ranking where in_stock !=0 and vendor_location = 'KSA' order by ksa_rank) as ksa_vendor on ifnull(cust.seller_sku,cust.bids) = ksa_vendor.wadi_sku_num

where cust.status in ('exported','exportable','carrier_selection_pending')  and (order_status.pick_line !='Yes' or order_status.pick_line !='Yes') group by 1 having vendor_code not in ('V00013','SV00596','SV00602','SV00601','SV00600','SV00599','SV00598','SV00597','SV00595','SV00646') ) t
WHERE t.status in('TP Confirmation','PO Created','Arrived','DXB Inventory pickup','KSA Inventory pickup')
AND t.max_shipping_date <= CURDATE() AND t.bids not in ('W1315999999','W1315345634') and t.Super_Category not like ('%Daily Needs%')  and t.category not like '%Household Supplies%' 