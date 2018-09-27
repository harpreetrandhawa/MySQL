SELECT 
    slipNumber AS HAWB_number,
    wadi_indexer.sales_order_item_id AS item_id,
    erpId AS erp_id,
    wadi_indexer.order_nr AS order_nr,
    saleorderitmname AS bob_item_status,
    (select min(fk_timestamp) from my_procurement.mk_sales_order_item_status_history where fk_sales_order_item_status = 'Shipped' and fk_sales_order_item = wadi_indexer.sales_order_item_id) AS shipped_at,
    (select min(fk_timestamp) from my_procurement.mk_sales_order_item_status_history where fk_sales_order_item_status in ('return_requested','return_undeliverable','return_received','return_picked_up') and fk_sales_order_item = wadi_indexer.sales_order_item_id) AS RTO_initiated_date,
    wadi_indexer.vendor_code AS vendor_id,
    seller.wh_name AS vendor_display_name,
    seller.wh_company as vendor_company_name,
    seller.wh_idsupplier AS vendor_code,
    if(wadi_indexer.vendor_code in ('V00010','V00502','V00501'),'JIT','MarketPlace') AS consignment_type,
    seller.sp_shortcode AS short_code,
    concat(wh_address1,wh_address2) AS vendor_address,
    (select contact_phone from my_procurement.seller_details_combo where vendor_code = wadi_indexer.vendor_code) AS vendor_contact,
    (select contact_email from my_procurement.seller_details_combo where vendor_code = wadi_indexer.vendor_code) AS vendor_email,
    unitprice AS unit_price,
    (select min(fk_timestamp) from my_procurement.mk_sales_order_item_status_history where fk_sales_order_item_status = 'delivered' and fk_sales_order_item = wadi_indexer.sales_order_item_id) AS delivered_at,
    if((select min(fk_timestamp) from my_procurement.mk_sales_order_item_status_history where fk_sales_order_item_status = 'delivered' and fk_sales_order_item = wadi_indexer.sales_order_item_id) is null,'NDR','CIR') AS return_type,
    wadi_indexer.name AS item_name,
    order_at AS ordered_at,
    seller.wh_city AS city,
    erpLocation AS location
    
FROM my_procurement.mk_sales_order_items wadi_indexer

Left JOIN
my_procurement.mk_sales_order_items_supplier seller on seller.sales_order_item_id = wadi_indexer.sales_order_item_id

where saleorderitmname in ('return_requested','return_undeliverable')