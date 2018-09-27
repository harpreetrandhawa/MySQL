select distinct concat(UCASE(ind.db),ind.id_sales_order_item)as item_id,order_status.order_nr,
    DATE_ADD(order_status.exported_at,INTERVAL 4 HOUR) as ordered_at,ind.sku_config as config_sku,ind.bids as bids,
   REPLACE(REPLACE(REPLACE(ind.item_name,',',''),'\n',''),'\r','') as item_name,
    CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.model_no,',',''),'\n',''),'\r',''),'')
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.model_no,',',''),'\n',''),'\r',''),'')
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.model_no,',',''),'\n',''),'\r',''),'')
   END  as model_no,
    wc.size as size,order_status.unit_price,ind.status as bob_item_status,ifnull(wc.sup_category,'') as Super_Category,
    ifnull(erp.updated_at,order_status.exported_at)as ExportableDateTime,(TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR))/60) AS Hours_Since,ucase(ind.db) as order_location,
    ifnull(order_status.po_number,'No') po_number,
   if(order_status.po_created_at = '',erp.po_number,order_status.po_created_at) as po_created_at,
    CASE
	  WHEN erp.sales_order_item_id IS NULL  and order_status.id_sales_order_item is null THEN 'Not in ERP'
      WHEN erp.arrivel_datetime <>'No' OR erp.pick_registered = 'Yes' THEN 'Arrived'
      WHEN erp.pick_line = 'Yes' AND erp.location_code = 'DXB' THEN 'DXB Inventory pickup'
      WHEN erp.pick_line = 'Yes' AND erp.location_code = 'KSA' THEN 'KSA Inventory pickup'
      WHEN (erp.arrivel_datetime = 'No' and erp.po_number != 'No') or order_status.po_number != '' THEN 'PO Created'
      WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'TP Confirmation'
	   END AS Status,
    CASE
      WHEN erp.sales_order_item_id IS NULL  and order_status.id_sales_order_item is null THEN 'Not in ERP'
      WHEN mid(ind.sku_config,6,2)='NM' THEN 'Namshi order'
      WHEN ind.status='confirmation_pending' THEN 'confirmation_pending'
      WHEN ind.status='shipped' THEN 'shipped'
      WHEN erp.pick_line = 'Yes' THEN 'Inventory Pickup'
      WHEN ((erp.arrivel_datetime = 'No' and erp.po_number != 'No') or order_status.po_number != '') AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
      WHEN ((erp.arrivel_datetime = 'No' and erp.po_number != 'No') or order_status.po_number != '') AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) BETWEEN 1440 AND 2160 THEN 'Handover priority 2'
      WHEN ((erp.arrivel_datetime = 'No' and erp.po_number != 'No') or order_status.po_number != '') AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover priority 3'
      WHEN erp.sales_order_item_id IS NULL OR erp.arrivel_datetime <> 'No' OR erp.pick_registered = 'Yes' THEN 'No Action'
      WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 3600 THEN 'Hunting'
      WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 3600 AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'TP confirmation priority 1'
      WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'TP confirmation priority 2'
      WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,ifnull(order_status.exportable_at,order_status.exported_at),DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'TP confirmation priority 3'
   END AS Action,
   if(order_status.transfer_price='0.000',order_status.unit_price,order_status.transfer_price)as transfer_price,
   order_status.cancel_reason_code as cancellation_reason_code,
    ifnull(CASE
                WHEN erp.vendor_code = 'V00013' THEN 'Namshi'
                WHEN
                    IFNULL(erp.vendor_code, 'None') = 'None'
                THEN CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.procurement_owner,',',''),'\n',''),'NULL',ifnull((select procurement_owner from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'Not Assigned')),ifnull((select procurement_owner from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'Not Assigned'))
       WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.procurement_owner,',',''),'\n',''),'NULL',ifnull((select procurement_owner from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'Not Assigned')),ifnull((select procurement_owner from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'Not Assigned'))
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.procurement_owner,',',''),'\n',''),'NULL',ifnull((select procurement_owner from vendor_ranking where wadi_sku_num=ind.bids  order by rank limit 1),'Not Assigned')),ifnull((select procurement_owner from vendor_ranking where wadi_sku_num=ind.bids  order by rank limit 1),'Not Assigned'))
     END
      ELSE IFNULL(REPLACE(REPLACE(owner.procurement_distribution, '\r', ''), '\n', ''), 'Not Assigned')
      END,'Not Assigned') AS owner,
    CASE WHEN restricted.bids is NULL then 0
     else 1 END as is_restricted,
     CASE when order_status.vendor_code != "" then order_status.vendor_code
     else
     CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.vendor_code,',',''),'\n',''),'\r',''),ifnull((select vendor_code from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'Find Seller'))
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.vendor_code,',',''),'\n',''),'\r',''),ifnull((select vendor_code from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'Find Seller'))
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.vendor_code,',',''),'\n',''),'\r',''),ifnull((select vendor_code from vendor_ranking where wadi_sku_num=ind.bids  order by rank limit 1),'Find Seller'))
   END end as first_vendor
   ,CASE when order_status.vendor_name != "" then order_status.vendor_name
     else
    CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.registered_name,',',''),'\n',''),'\r',''),ifnull((select registered_name from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'Find Seller'))
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.registered_name,',',''),'\n',''),'\r',''),ifnull((select registered_name from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'Find Seller'))
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.registered_name,',',''),'\n',''),'\r',''),ifnull((select registered_name from vendor_ranking where wadi_sku_num=ind.bids order by rank limit 1),'Find Seller'))
   END END as first_vendor_name
   ,'' as first_vendor_contact_no
    ,'' as first_vendor_address
    ,CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.TP,',',''),'\n',''),'\r',''),ifnull((select TP from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'0'))
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.TP,',',''),'\n',''),'\r',''),ifnull((select TP from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'0'))
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.TP,',',''),'\n',''),'\r',''),ifnull((select TP from vendor_ranking where wadi_sku_num=ind.bids order by rank limit 1),'0'))
   END as first_vendor_TP
    ,CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.vendor_location,',',''),'\n',''),'\r',''),ifnull((select vendor_location from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'0'))
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.vendor_location,',',''),'\n',''),'\r',''),ifnull((select vendor_location from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'0'))
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.vendor_location,',',''),'\n',''),'\r',''),ifnull((select vendor_location from vendor_ranking where wadi_sku_num=ind.bids order by rank limit 1),'0'))
END as first_vendor_location
   , CASE WHEN erp.po_number = 'No' AND order_status.po_number = '' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' then
      CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(REPLACE(ksa_vendor.procurement_owner,',',''),'\n',''),'\r',''),'NULL',ifnull((select procurement_owner from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'Not Assigned')),'Not Assigned')
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(REPLACE(uae_vendor.procurement_owner,',',''),'\n',''),'\r',''),'NULL',ifnull((select procurement_owner from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'Not Assigned')),'Not Assigned')
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(REPLACE(first_vendor.procurement_owner,',',''),'\n',''),'\r',''),'NULL',ifnull((select procurement_owner from vendor_ranking where wadi_sku_num=ind.bids  order by rank limit 1),'Not Assigned')),'Not Assigned')
      END
    ELSE CASE WHEN erp.vendor_code = 'V00013' THEN 'Namshi'ELSE
    IFNULL(REPLACE(REPLACE(REPLACE(owner.procurement_distribution,',',''),'\n',''),'\r',''),'Not Assigned') END 
    END as  first_vendor_owner,
CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.payment_terms,',',''),'\n',''),'\r',''),ifnull((select payment_terms from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'Not Assigned'))
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.payment_terms,',',''),'\n',''),'\r',''),ifnull((select payment_terms from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'Not Assigned'))
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.payment_terms,',',''),'\n',''),'\r',''),ifnull((select payment_terms from vendor_ranking where wadi_sku_num=ind.bids  order by rank limit 1),'Not Assigned'))
   END as first_vendor_payment_terms,
   CASE
      WHEN restricted.bids IS NOT NULL AND ind.db = 'SA'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(ksa_vendor.rank,',',''),'\n',''),'\r',''),ifnull((select rank from vendor_ranking where vendor_location = 'KSA' and wadi_sku_num=ind.bids order by ksa_rank limit 1),'Not Assigned'))
      WHEN ind.db = 'AE'
      THEN IFNULL(REPLACE(REPLACE(REPLACE(uae_vendor.rank,',',''),'\n',''),'\r',''),ifnull((select rank from vendor_ranking where vendor_location = 'UAE' and wadi_sku_num=ind.bids order by uae_rank limit 1),'Not Assigned'))
      ELSE IFNULL(REPLACE(REPLACE(REPLACE(first_vendor.rank,',',''),'\n',''),'\r',''),ifnull((select rank from vendor_ranking where wadi_sku_num=ind.bids  order by rank limit 1),'Not Assigned'))
   END as rank,
    ifnull(erp.arrivel_datetime,'No') as arrived_at,
    ifnull(wadiff.variant_decision,'')as variant_decision,
    ifnull(wadiff.is_src_variantemail,'') as is_src_variant_available,
  ifnull(wadiff.erp_status,'')as erp_status,
  wc.category,
  order_status.arrived_at as arrived_date,wc.brand,ifnull(ind.seller_sku,ind.bids)seller_sku,
  if(left(order_status.vendor_code,1) ='M','Yes','No') is_marketplace
from nm_sourcing.sales_order_item_custom as ind
   LEFT outer JOIN
   nm_sourcing.order_item_status as erp on concat(Ucase(db),id_sales_order_item) = erp.sales_order_item_id
    LEFT outer JOIN
   nm_sourcing.sales_order_item_erp as order_status on ind.db = order_status.db
    and ind.id_sales_order_item = order_status.id_sales_order_item
   left outer join
    (select variant_decision,is_src_variantemail,item_id,erp_status from  nm_sourcing.zd_tickets_wadiff) as wadiff
    on wadiff.item_id= concat(order_status.db,order_status.id_sales_order_item)
    LEFT OUTER JOIN
   nm_sourcing.restricted_items as restricted on restricted.bids = ind.bids
    LEFT OUTER JOIN
   nm_sourcing.am_vendor_mapping as owner on (replace(replace(owner.vendor_name,'\n',''),'\r','') = erp.vendor_code or replace(replace(owner.vendor_name,'\n',''),'\r','') = order_status.vendor_code)
    LEFT OUTER JOIN
   (select bids,product_name,sup_category,size,category,brand from wadi_catalog) as wc on wc.bids  = ifnull(ind.seller_sku,ind.bids)
    LEFT OUTER JOIN
   (select * from nm_sourcing.vendor_ranking where in_stock !=0 order by rank ) as first_vendor  on ifnull(ind.seller_sku,ind.bids) = first_vendor.wadi_sku_num
    LEFT outer JOIN
   (select * from nm_sourcing.vendor_ranking where in_stock !=0 and vendor_location = 'UAE' order by uae_rank) as uae_vendor
    on ifnull(ind.seller_sku,ind.bids) = uae_vendor.wadi_sku_num
    LEFT outer JOIN
   (select * from nm_sourcing.vendor_ranking where in_stock !=0 and vendor_location = 'KSA' order by ksa_rank) as ksa_vendor
    on ifnull(ind.seller_sku,ind.bids) = ksa_vendor.wadi_sku_num
where ind.status in ('exported','exportable','carrier_selection_pending') and (erp.pick_line <> 'Yes' or erp.pick_line is null or pick_registered <> 'Yes') having first_vendor not in ('SV00596','SV00602','SV00601','SV00600','SV00599','SV00598','SV00597','SV00595','SV00646')