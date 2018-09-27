SELECT
 CONCAT(wadi_indexer.db,wadi_indexer.item_id) as item_id
 ,wadi_indexer.order_nr
 ,wadi_indexer.sku
 ,wadi_indexer.bids
 ,CONCAT('"',REPLACE(REPLACE(REPLACE(REPLACE(wadi_indexer.item_name,'"',"'"),',',' '),',',' '),'\n',' '),'"') as item_name
 ,Ifnull(first_vendor.model_no,'') as model_no
    ,wadi_indexer.brand
 ,wadi_indexer.unit_price
 ,CASE
  WHEN wadi_indexer.vendor_code = 'V00013' THEN 'Fashion - Namshi'
  ELSE REPLACE(REPLACE(wadi_indexer.category_level_1,'\r',''),'\n','')
 END AS super_category
 ,(TIMESTAMPDIFF(MINUTE,sc.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR))/60) AS hours_since
 ,erp.po_number
    ,CASE
  WHEN erp.sales_order_item_id IS NULL THEN 'Not in ERP'
  WHEN wadi_indexer.vendor_code = 'V00013' THEN 'Namshi Order'
  WHEN wadi_indexer.bob_item_status = 'confirmation_pending' THEN 'Confirmation Pending'
  WHEN wadi_indexer.bob_item_status = 'shipped' THEN 'Shipped'
  WHEN erp.pick_line = 'Yes' THEN 'Inventory Pickup'
  WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover Priority 1'
  WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'Handover Priority 2'
  WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover Priority 3'
  WHEN erp.sales_order_item_id IS NULL OR erp.arrivel_datetime <> 'No' OR erp.pick_registered = 'Yes' THEN 'No Action'
  WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 3600 THEN 'Hunting'
  WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 3600 AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'TP Confirmation Priority 1'
  WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'TP Confirmation Priority 2'
  WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND (TIMESTAMPDIFF(MINUTE,wadi_indexer.exported_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 OR wadi_indexer.bob_item_status = 'exportable' OR wadi_indexer.bob_item_status = 'exported') THEN 'TP Confirmation Priority 3'
 END AS action
    ,CASE
  WHEN restricted.bids IS NOT NULL
  THEN 1
  ELSE 0
 END as is_restricted
    ,ifnull(CASE
  WHEN IFNULL(erp.vendor_code, 'None') = 'None' OR IFNULL(wadi_indexer.vendor_id,"") = "" THEN
  CASE
   WHEN wadi_indexer.db = 'AE'
   THEN first_vendor_uae.vendor_code
   WHEN restricted.bids IS NOT NULL AND wadi_indexer.db = 'SA'
   THEN first_vendor_ksa.vendor_code
   ELSE first_vendor.vendor_code
  END
  ELSE erp.vendor_code
 END,'Find Seller') as vendor_code
 ,ifnull(CASE
  WHEN IFNULL(erp.vendor_code, 'None') = 'None' OR IFNULL(wadi_indexer.vendor_id,"") = "" THEN
  CASE
   WHEN wadi_indexer.db = 'AE'
   THEN first_vendor_uae.registered_name
   WHEN restricted.bids IS NOT NULL AND wadi_indexer.db = 'SA'
   THEN first_vendor_ksa.registered_name
   ELSE first_vendor.registered_name
  END
  ELSE REPLACE(REPLACE(REPLACE(REPLACE(seller_details.registered_name,'"',"'"),',',' '),',',' '),'\n',' ')
 END, 'Find Seller') as vendor_name
 ,round(ifnull(CASE
  WHEN IFNULL(erp.vendor_code, 'None') = 'None' OR IFNULL(wadi_indexer.vendor_id,"") = "" THEN
  CASE
   WHEN wadi_indexer.db = 'AE'
   THEN first_vendor_uae.TP
   WHEN restricted.bids IS NOT NULL AND wadi_indexer.db = 'SA'
   THEN first_vendor_ksa.TP
   ELSE first_vendor.TP
  END
  ELSE wadi_indexer.transfer_price
 END,'Find Seller'),'0') as transfer_price 
 ,ifnull(CASE
  WHEN erp.vendor_code = 'V00013' THEN 'Namshi'
  WHEN IFNULL(erp.vendor_code, 'None') = 'None' THEN
  CASE
   WHEN wadi_indexer.db = 'AE'
   THEN If(first_vendor_uae.procurement_owner='NULL','Not Assigned',replace(replace(first_vendor_uae.procurement_owner,'\r', ''), '\n' ,''))
   WHEN restricted.bids IS NOT NULL AND wadi_indexer.db = 'SA'
   THEN If(first_vendor_ksa.procurement_owner='NULL','Not Assigned',replace(replace(first_vendor_ksa.procurement_owner,'\r', ''), '\n' ,''))
   ELSE If(first_vendor.procurement_owner='NULL','Not Assigned',replace(replace(first_vendor.procurement_owner,'\r', ''), '\n' ,''))
  END
  ELSE IFNULL(REPLACE(REPLACE(am_vendor_mapping.owner,'\n',''),'\r',''),'Not Assigned')
 END,'Not Assigned') as owner

 ,date_format(date_add(date(date_add(date(date_add(sc.occured_at,interval 4 hour)),interval if(wadi_indexer.db = 'SA',seller_shipping_time_max_sa,seller_shipping_time_max_ae) day)), interval (floor((if(wadi_indexer.db = 'SA',wadi_indexer.seller_shipping_time_max_sa,wadi_indexer.seller_shipping_time_max_ae)+ dayofweek(date(date(date_add(sc.occured_at, interval 4 hour))-interval 6 day)))/7)) + 1 day),'%Y-%m-%d') as max_shipping_date
 ,wadi_indexer.vendor_code as wadi_vendor
FROM
 buy_sell.wadi_indexer
    
    lEFT OUTER JOIN
    (select db,item_id,min(occured_at)occured_at from buy_sell.status_cache where status = 'exportable'  group by 1,2) sc on sc.db = wadi_indexer.db and sc.item_id = wadi_indexer.item_id
  
 LEFT OUTER JOIN
 erp.order_item_status as erp ON erp.sales_order_item_id = CONCAT(wadi_indexer.db,wadi_indexer.item_id)

 LEFT OUTER JOIN
 (SELECT
  wadi_sku_num
  ,vendor_code
  ,vendor_location
  ,model_no
  ,payment_terms
  ,TP
  ,procurement_owner
  ,registered_name
  ,in_stock
 FROM
  wadi_retail.vendor_ranking
 WHERE
  rank = 1
  and wadi_sku_num in (SELECT bids FROM buy_sell.wadi_indexer WHERE bob_item_status in ('exported', 'exportable') )
 ) as first_vendor on first_vendor.wadi_sku_num = wadi_indexer.bids

 LEFT OUTER JOIN
 (SELECT
  wadi_sku_num
  ,vendor_code
  ,vendor_location
  ,model_no
  ,payment_terms
  ,TP
  ,procurement_owner
  ,registered_name
  ,in_stock
 FROM
  wadi_retail.vendor_ranking
 WHERE
  ksa_rank = 1
  and wadi_sku_num in (SELECT bids FROM buy_sell.wadi_indexer WHERE bob_item_status in ('exported', 'exportable') )
 ) as first_vendor_ksa on first_vendor_ksa.wadi_sku_num = wadi_indexer.bids

 LEFT OUTER JOIN
 (SELECT
  wadi_sku_num
  ,vendor_code
  ,vendor_location
  ,model_no
  ,payment_terms
  ,TP
  ,procurement_owner
  ,registered_name
  ,in_stock
 FROM
  wadi_retail.vendor_ranking
 WHERE
  uae_rank = 1
  and wadi_sku_num in (SELECT bids FROM buy_sell.wadi_indexer WHERE bob_item_status in ('exported', 'exportable') )
 ) as first_vendor_uae on first_vendor_uae.wadi_sku_num = wadi_indexer.bids
 
 
 LEFT OUTER JOIN
 (SELECT
  vendor_name
  ,procurement_distribution as owner
 FROM
  erp.am_vendor_mapping
 ) as am_vendor_mapping on am_vendor_mapping.vendor_name COLLATE utf8_unicode_ci = erp.vendor_code
  
 
 LEFT OUTER JOIN
 (SELECT
  seller_code
  ,registered_name as registered_name
  ,contact_no as contact_no
  ,payment_terms as payment_terms
  ,REPLACE(pickup_address,',',';') as pickup_address
 FROM
  erp.seller_details
 ) as seller_details on erp.vendor_code = seller_details.seller_code
 
 
 LEFT OUTER JOIN
 (select 
  bids
 from 
  wadi_retail.restricted_items
 group by
  1
 ) as restricted on restricted.bids = wadi_indexer.bids
WHERE
 wadi_indexer.bob_item_status in ('exported', 'exportable')
	
	and wadi_indexer.vendor_code <> 'V00013'