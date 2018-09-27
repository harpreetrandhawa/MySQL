SELECT
	CONCAT(indexer.db,indexer.id_sales_order_item) as item_id
    ,indexer.order_nr
    ,indexer.bob_item_status
	,Exportable.occured_at AS ExportableDateTime
    ,CASE 
		WHEN erp.arrivel_datetime <>'No' OR erp.pick_registered = 'Yes' THEN 'Arrived'
		WHEN erp.pick_line = 'Yes' AND erp.location_code = 'DXB' THEN 'DXB Inventory pickup'
		WHEN erp.pick_line = 'Yes' AND erp.location_code = 'KSA' THEN 'KSA Inventory pickup'
		WHEN erp.sales_order_item_id IS NULL THEN 'Not in ERP'
		WHEN erp.arrivel_datetime = 'No' AND erp.po_number <> 'No' THEN 'PO Created'
		WHEN erp.po_number = 'No' AND erp.pick_line = 'No' AND erp.pick_registered = 'No' THEN 'TP Confirmation'
	END AS Status
    ,indexer.seller_shipping_time_max_ae
    ,indexer.seller_shipping_time_max_sa
    from buy_sell.wadi_indexer indexer 
    LEFT OUTER JOIN
    (SELECT
		db,item_id,min(occured_at) as occured_at
	FROM buy_sell.status_cache WHERE
		status='exportable') Exportable on Exportable.db=indexer.db AND Exportable.item_id=indexer.id_sales_order_item
    LEFT OUTER JOIN
	erp.order_item_status as erp ON erp.sales_order_item_id=CONCAT(indexer.db,indexer.id_sales_order_item)
    where indexer.bob_item_status in ('exported', 'exportable');
    
    
    
Select * from wadi_indexer limit 5
    
    
    