Select concat(indexer.db,indexer.item_id)item_id,
indexer.order_nr,
indexer.ordered_at,
indexer.sku,indexer.bids,
indexer.item_name,
(select max(model_no) from onboarding where onboarding.wadi_sku_num = indexer.bids)model_no,
indexer.unit_price,
indexer.bob_item_status,
CASE
	WHEN mid(indexer.sku,6,2)='NM' THEN 'Fashion - Namshi'
        ELSE LEFT(REPLACE(REPLACE(indexer.category_list,'Root Category | ',''),' | ','|'),LOCATE('|',REPLACE(REPLACE(indexer.category_list,'Root Category | ',''),' | ','|'))-1)
    END AS Super_Category,
(Exportable.occured_at)exported_at,
(TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR))/60) AS Hours_Since,
IF(mid(indexer.sku,6,2) = 'NM','Namshi','Wadi') AS type,
indexer.db as order_location,

CASE
  WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'Yes' ELSE 'No'
END AS pending_PO,
erp.po_number,
CASE
	WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'No PO'
    WHEN erp.po_number <> 'No' AND erp.arrivel_datetime = 'No' THEN 0
	WHEN erp.po_number <> 'No' AND erp.arrivel_datetime <> 'No' THEN 1
	ELSE 0
END AS arrival_quantity,
CASE
	WHEN erp.pick_line = 'Yes' AND erp.location_code = 'DXB' THEN 'DXB Inventory pickup'
    WHEN erp.pick_line = 'Yes' AND erp.location_code = 'KSA' THEN 'KSA Inventory pickup'
    ELSE 'No'
END AS picking_pending,
erp.pick_registered,
CASE
	WHEN erp.arrivel_datetime ='Yes' AND erp.pick_registered = 'Yes' THEN 'Arrived'
	WHEN erp.pick_line = 'Yes' OR (erp.arrivel_datetime = 'No' And erp.pick_registered = 'Yes') AND erp.location_code = 'DXB' THEN 'DXB Inventory pickup'
	WHEN erp.pick_line = 'Yes' OR (erp.arrivel_datetime = 'No' And erp.pick_registered = 'Yes') AND erp.location_code = 'KSA' THEN 'KSA Inventory pickup'
	WHEN erp.sales_order_item_id IS NULL THEN 'Not in ERP'
	WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' THEN 'PO Created'
	WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'TP Confirmation'
END AS Status,
CASE
	WHEN mid(indexer.sku,6,2)='NM' THEN 'Namshi order'
	WHEN indexer.bob_item_status='confirmation_pending' THEN 'confirmation_pending'
	WHEN indexer.bob_item_status='shipped' THEN 'shipped'
	WHEN erp.pick_line = 'Yes' THEN 'Inventory Pickup'
	WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
	WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'Handover priority 2'
	WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'Handover priority 3'
	WHEN erp.sales_order_item_id IS NULL OR erp.arrivel_datetime <> 'No' OR erp.pick_registered = 'Yes' THEN 'No Action'
	WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 3600 THEN 'Hunting'
	WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 3600 AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 2160 THEN 'TP confirmation priority 1'
	WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 2160 AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) > 1440 THEN 'TP confirmation priority 2'
	WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' AND TIMESTAMPDIFF(MINUTE,Exportable.occured_at,DATE_ADD(now(),INTERVAL 4 HOUR)) <= 1440 THEN 'TP confirmation priority 3'
END AS Action,
CASE
	WHEN restricted.bids IS NOT NULL THEN if(indexer.db='SA','KSA Restricted','DXB Restricted')	ELSE 'No' END as is_restricted,
erp.vendor_code


from wadi_indexer as indexer

LEFT OUTER JOIN
    (SELECT
        db,item_id,min(occured_at) as occured_at
    FROM
        reporting.status_cache
    WHERE
        status='exportable'
        and occured_at > CURDATE() - INTERVAL 60 DAY
    GROUP BY
        1,2) as Exportable on Exportable.db=indexer.db AND Exportable.item_id=indexer.item_id

LEFT OUTER JOIN
    reporting.order_item_status as erp ON erp.sales_order_item_id=CONCAT(indexer.db,indexer.id_sales_order_item)

LEFT OUTER JOIN
    (select bids from reporting.restricted_items group by 1)restricted on restricted.bids = indexer.bids

where indexer.bob_item_status in ('exported','exportable') limit 100;


Select count(*) from wadi_indexer