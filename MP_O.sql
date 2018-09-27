select
concat(wadi_indexer.db, wadi_indexer.item_id) as item_id
,wadi_indexer.order_nr
,sales_order_item.id_sales_order_item as item_id
,wadi_indexer.shipping_location
,wadi_indexer.hawb_number
,case when seller_centre_sa_replica.sales_order_item.fk_shipment_type = 3 then "crossdock"
when seller_centre_sa_replica.sales_order_item.fk_shipment_type = 2 then "dropship"
end as fulfillment_mode
,seller.src_id as seller_id
,sales_order_item.created_at as seller_centre_created_at
,sales_order_item.target_to_ship
,(select name from seller_centre_sa_replica.seller where id_seller = sales_order_item.fk_seller) as seller_name
,sales_order_item.sku_seller
,IF(LENGTH(sales_order_item.name) = CHAR_LENGTH(sales_order_item.name), sales_order_item.name,'NA') as item_name
,sales_order_item.unit_price
,sales_order_item_status.name as item_status
,wadi_indexer.bob_item_status
,(select min(created_at) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 1 and fk_sales_order_item = sales_order_item.id_sales_order_item) as created_at
,(select min(created_at) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 8 and fk_sales_order_item = sales_order_item.id_sales_order_item) as ready_to_ship_at
,(select min(created_at) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 2 and fk_sales_order_item = sales_order_item.id_sales_order_item) as shipped_at
,(select min(created_at) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 6 and fk_sales_order_item = sales_order_item.id_sales_order_item) as delivered_at
,(select min(created_at) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 4 and fk_sales_order_item = sales_order_item.id_sales_order_item) as returned_at
,(select min(occurred_at) from logistics.shipment_update where awb = wadi_indexer.hawb_number and reference = 'Aramex-SH014') as aramex_pickup
,(select min(occurred_at) from logistics.shipment_update where awb = wadi_indexer.hawb_number and reference = 'Aramex-SH047') as aramex_recd_at_origin

from 
seller_centre_sa_replica.sales_order_item
left join seller_centre_sa_replica.sales_order_item_status on sales_order_item.fk_sales_order_item_status = sales_order_item_status.id_sales_order_item_status
left join buy_sell.wadi_indexer on wadi_indexer.item_id = sales_order_item.src_id and wadi_indexer.db = 'SA'
left join seller_centre_sa_replica.seller on seller.id_seller = sales_order_item.fk_seller
where
sales_order_item.fk_seller not in (1, 11)
