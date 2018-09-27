SELECT DISTINCT
    erp.po_number,
    if(erp.po_created_at=0,'',erp.po_created_at)po_created_at,
    erp.item_id,
    erp.vendor_code AS vendor_id,
    erp.vendor_name,
    sd.address2 corporate_address,
    sd.address1 pickup_address,
    sd.contact_phone contact_no,
    sd.contact_email escalation1_email,
    erp.sku AS bids,
    onb.name,
    onb.color,
    IFNULL(onb.size, '') AS size,
    CAST(COUNT(erp.sku) AS CHAR) AS qty,
    CAST(ROUND(erp.transfer_price, 0) AS CHAR) AS transfer_price,
    CAST(ROUND((COUNT(erp.sku)) * (CAST(erp.transfer_price AS UNSIGNED INT)),
                0)
        AS CHAR) AS total_price,
    '' as  currency,
    erp.order_item_status,
    if(erp.arrived_at=0,'',erp.arrived_at)arrived_at
FROM
    replica_sales_order_item_erp erp
        LEFT OUTER JOIN
    my_procurement.seller_details_combo sd ON erp.vendor_code = sd.vendor_code
        LEFT OUTER JOIN
    (SELECT DISTINCT
        bids, product_name AS name, brand, color, size
    FROM
        replica_wadi_catalog) AS onb ON erp.sku = onb.bids
WHERE
    erp.erp_updated_at >= DATE_SUB(NOW(), INTERVAL 2 DAY)
        AND MID(erp.sku, 6, 2) != 'NM'
        AND erp.vendor_code != 'V00013'
        AND erp.po_created_at !=0
GROUP BY erp.sku , po_number;
