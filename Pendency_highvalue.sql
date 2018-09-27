SELECT 
    t.item_id,
    t.bids,
    t.item_name,
    t.model_no,
    t.unit_price,
    t.po_number,
    IFNULL(first_vendor,
            IF(t.action IN ('No Action' , 'Inventory Pickup'),
                first_vendor,
                'Find Seller')) AS vendor_code,
    IFNULL(first_vendor_name,
            IF(t.action IN ('No Action' , 'Inventory Pickup'),
                first_vendor_name,
                'Find Seller')) AS vendor_name,
    IFNULL(first_vendor_TP,
            IF(t.action IN ('No Action' , 'Inventory Pickup'),
                first_vendor_TP,
                'Find Seller')) AS transfer_price,
    t.status,
    REPLACE(REPLACE(IFNULL(t.first_vendor_owner, 'Not Assigned'),
            '
            ',
            ''),
        '
',
        '') AS owner,
    DATE_ADD(NOW(), INTERVAL 4 HOUR) AS Date
FROM
    (
select CONCAT(UCASE(ind.db),ind.id_sales_order_item)as item_id,
	ind.bids as bids,
	REPLACE(REPLACE(REPLACE(ind.item_name,',',''),'\n',''),'\r','') as item_name,
    IF(IFNULL(first_vendor.model_no, '') = 0, '', IFNULL(first_vendor.model_no, '')) AS model_no,
    order_status.unit_price,
	
    CASE WHEN order_status.po_number ='' and erp.po_number = 'No' then 'No' 
		WHEN erp.po_number='No' AND order_status.po_number!='' THEN order_status.po_number
        ELSE erp.po_number END as po_number,
	
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
    
    REPLACE(REPLACE(REPLACE(owner.procurement_distribution,',',''),'\n',''),'\r','') as owner,
    
     CASE when order_status.vendor_code != "" then order_status.vendor_code 
     else
     CASE
		WHEN ind.vendor_code = 'V00685' 
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')
		
		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')
		
		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.vendor_code,',',''),'\n',''),'\r',''),'Find Seller')
	END end as first_vendor
	,CASE when order_status.vendor_name != "" then order_status.vendor_name 
     else
    CASE
		WHEN ind.vendor_code = 'V00685' 
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.registered_name,',',''),'\n',''),'\r',''),'Find Seller')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.registered_name,',',''),'\n',''),'\r',''),'Find Seller')
		
		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.registered_name,',',''),'\n',''),'\r',''),'Find Seller')
		
		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.registered_name,',',''),'\n',''),'\r',''),'Find Seller') 
	END END as first_vendor_name
	
    ,CASE when order_status.transfer_price != "" then order_status.transfer_price 
     else
    CASE
		WHEN ind.vendor_code = 'V00685' 
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.TP,',',''),'\n',''),'\r',''),'0')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.TP,',',''),'\n',''),'\r',''),'0')
		
		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.TP,',',''),'\n',''),'\r',''),'0')
		
		
		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.TP,',',''),'\n',''),'\r',''),'0') 
	END end as first_vendor_TP
    
	,CASE
		WHEN ind.vendor_code = 'V00685' 
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.procurement_owner,',',''),'\n',''),'\r',''),'')

		WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.procurement_owner,',',''),'\n',''),'\r',''),'')
		
		WHEN ind.db = 'AE'
		THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.procurement_owner,',',''),'\n',''),'\r',''),'')
		
		ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.procurement_owner,',',''),'\n',''),'\r',''),'') 
	END as first_vendor_owner

	
	
from nm_sourcing.sales_order_item_custom as ind 

	LEFT outer JOIN
	nm_sourcing.order_item_status as erp on concat(Ucase(db),id_sales_order_item) = erp.sales_order_item_id
    
    LEFT outer JOIN
	nm_sourcing.sales_order_item_erp as order_status on ind.db = order_status.db and ind.id_sales_order_item = order_status.id_sales_order_item
    
    LEFT OUTER JOIN
	my_procurement.restricted_bids as restricted on restricted.bids = ind.bids
    
    LEFT OUTER JOIN
	nm_sourcing.am_vendor_mapping as owner on owner.vendor_name = erp.vendor_code or owner.vendor_name = order_status.vendor_code
    
    LEFT OUTER JOIN
	(select bids,product_name,sup_category,size from wadi_catalog) as wc on wc.bids  = ind.bids
	
    LEFT OUTER JOIN
	(select * from nm_sourcing.vendor_ranking where rank =1) as first_vendor  on ind.bids = first_vendor.wadi_sku_num
    
    LEFT OUTER JOIN
	(select * from nm_sourcing.vendor_ranking where vendor_location = 'UAE' order by rank) as uae_vendor  on ind.bids = uae_vendor.wadi_sku_num
    
    LEFT OUTER JOIN
	(select * from nm_sourcing.vendor_ranking where vendor_location = 'KSA' order by rank) as ksa_vendor  on ind.bids = ksa_vendor.wadi_sku_num

where ind.status in ('exported','exportable') group by 1 )t
WHERE
    t.unit_price > '1000.00'
        AND t.status IN ('TP Confirmation' , 'PO Created', 'Arrived') 


ORDER BY unit_price DESC , bids DESC
