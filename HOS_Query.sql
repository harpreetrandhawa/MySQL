SELECT 
    CONCAT(ucase(indexer.db), indexer.id_sales_order_item) AS item_id,
    CAST(ifnull(indexer.exportable_at,exported_at) + interval 4 HOUR AS CHAR (100)) AS exported_at,
    indexer.order_nr,
    indexer.sku AS sku_code,
    c.sku as Seller_SKU_code,
    (select product_name from wadi_catalog where bids = indexer.sku) AS Product_Description,
    '1' AS Qty,
    CAST(ROUND(indexer.transfer_price, 2) AS CHAR (10)) AS transfer_price,
    indexer.po_number,
    CAST(indexer.po_created_at + interval 4 hour AS CHAR (100)) AS po_created_at,
    indexer.vendor_name,
    indexer.vendor_code as vendor_id,
    sd.country AS country,
    sd.pickup_address as pickup_address,
    sd.escalation1_email AS email,
    sd.contact_no AS vendor_contact_details,
    IF(sd.payment_terms = '0+0'
            OR sd.payment_terms = '0 days',
        'Cash',
        'Credit') payment_terms,
	(SELECT 
            procurement_distribution
        FROM
            am_vendor_mapping
        WHERE
            indexer.vendor_code  =  am_vendor_mapping.vendor_name) Owner,
	if(indexer.arrived_at is NULL,'No','Yes') AS arrivel_datetime,
    CASE
        WHEN TIMESTAMPDIFF(MINUTE,ifnull(indexer.exportable_at,exported_at),DATE_ADD(NOW(), INTERVAL 4 HOUR)) > 2160 THEN 'Handover priority 1'
        WHEN TIMESTAMPDIFF(MINUTE,ifnull(indexer.exportable_at,exported_at),DATE_ADD(NOW(), INTERVAL 4 HOUR)) BETWEEN 1440 AND 2160 THEN 'Handover priority 2'
        WHEN TIMESTAMPDIFF(MINUTE,ifnull(indexer.exportable_at,exported_at),DATE_ADD(NOW(), INTERVAL 4 HOUR)) <= 1440 THEN'Handover priority 3'
    END AS Action,
    onb.brand,
    onb.model_no,
    onb.color,
    IF(onb.size IS NULL OR onb.size = 'None',
        '-',
        onb.size) AS size
    
    
FROM
    sales_order_item_erp AS indexer 
    left join
    sales_order_item_custom c
    on c.id_sales_order_item = indexer.id_sales_order_item and c.db=indexer.db    
    LEFT OUTER JOIN
    seller_details as sd on sd.seller_code = indexer.vendor_code
    LEFT OUTER JOIN
    onboarding as onb on onb.wadi_sku_num = indexer.sku
    
where indexer.po_created_at is not NULL
    and c.status in ('exportable','exported')
    AND indexer.vendor_code != 'V00013'
        AND indexer.vendor_code != 'V00010'; 
    
/*WHERE
    (bob_item_status IN ('exported' , 'exportable')
        AND bob_item_status != 'canceled')
        AND po_created_at IS NOT NULL
        AND vendor_id != 'V00013'
        AND vendor_id != 'V00010';*/