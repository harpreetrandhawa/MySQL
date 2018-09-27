select
concat(wadi_indexer.db, wadi_indexer.item_id) as item_id
,wadi_indexer.order_nr
,soi.id_sales_order_item as item_id
,seller.src_id as seller_id
,soi.target_to_ship
,(select name from seller_centre_sa_replica.seller where id_seller = soi.fk_seller) as seller_name
,(select email from seller_centre_sa_replica.seller where id_seller = soi.fk_seller) as seller_email
,soi.sku_seller
,soi.unit_price
,sales_order_item_status.name as item_status
,wadi_indexer.bob_item_status
,soi.created_at as ordered_at
,soih.ready_for_ship_at
,soih.shipped_at
,wadi_indexer.HAWB_number
,timestampdiff(day,soi.created_at,soi.target_to_ship) days
,timestampdiff(hour,soi.created_at,now()) as pickup_ageing
,soih.rfs_ageing
,soih.ship_ageing
,case when timestampdiff(hour,wadi_indexer.ordered_at,now()) >= 36 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_0"
when timestampdiff(hour,soi.created_at,now()) between 24 and 35 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_1"
when timestampdiff(hour,soi.created_at,now()) between 12 and 23 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_2"
when timestampdiff(hour,soi.created_at,now()) < 12 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_3"
when soih.rfs_ageing >= 36 and sales_order_item_status.name = 'ready_to_ship' then "Handover_Priority_0"
when soih.rfs_ageing between 24 and 35 and sales_order_item_status.name = 'ready_to_ship' then "Handover_Priority_1"
when soih.rfs_ageing < 24 and sales_order_item_status.name = 'ready_to_ship' then "Handover_Priority_2"
when sales_order_item_status.name = 'shipped' and su.pickup is null and  soih.ship_ageing >= 48 then "Carrier_Confirmation_Priority_1"
when sales_order_item_status.name = 'shipped' and su.pickup is null and  soih.ship_ageing between 24 and 47 then "Carrier_Confirmation_Priority_2"
when sales_order_item_status.name = 'shipped' and su.pickup is null and  soih.ship_ageing < 24 then "Carrier_Confirmation_Priority_2"
end Priority
,IF(LENGTH(soi.name) = CHAR_LENGTH(soi.name), soi.name,'NA') as item_name

 from  seller_centre_sa_replica.sales_order_item as soi
left join seller_centre_sa_replica.sales_order_item_status on soi.fk_sales_order_item_status = sales_order_item_status.id_sales_order_item_status
left join buy_sell.wadi_indexer on wadi_indexer.item_id = soi.src_id and wadi_indexer.db = 'SA'
left join seller_centre_sa_replica.seller on seller.id_seller = soi.fk_seller

left join
	(select
    fk_sales_order_item
    ,fk_sales_order_item_status
    ,min(if(fk_sales_order_item_status = 2,created_at,null)) as shipped_at
    ,min(if(fk_sales_order_item_status = 8,created_at,null)) as ready_for_ship_at
    ,timestampdiff(hour,min(if(fk_sales_order_item_status = 8,created_at,null)),now()) as rfs_ageing
    ,timestampdiff(hour,min(if(fk_sales_order_item_status = 2,created_at,null)),now()) as ship_ageing
   
   from  seller_centre_sa_replica.sales_order_item_status_history 
   where created_at > curdate() - interval 90 day
   group by 1
	) as soih on soi.id_sales_order_item = soih.fk_sales_order_item 
    
left join
(select 
awb
,min(occurred_at) as pickup
from logistics.shipment_update 
where
reference = 'Aramex-SH014' and occurred_at > curdate() - interval 90 day
group by 1 having pickup is not null)as su on su.awb = buy_sell.wadi_indexer.HAWB_number

where
soi.fk_seller not in (1, 11) and soi.fk_shipment_type = '2'
and soi.fk_sales_order_item_status in (1)
order by seller_name;