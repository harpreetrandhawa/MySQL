select 
concat(wadi.db, wadi.item_id) as item_id
,wadi.order_nr
,if(db = 'AE',sc_ae.id_sales_order_item,sc_sa.id_sales_order_item) as item_id
,if(db = 'AE',sc_ae.src_id,sc_sa.src_id)as seller_id
,if(db = 'AE',sc_ae.target_to_ship,sc_ae.target_to_ship)target_to_ship
,if(db = 'AE',ae_seller.name,sa_seller.name)seller_name
,if(db = 'AE',ae_seller.email,sa_seller.email)seller_email
,if(db = 'AE', sc_ae.sku_seller,sc_sa.sku_seller)sku_seller
,if(db = 'AE' , sc_ae.unit_price,sc_ae.unit_price)unit_price
,sales_order_item_status.name as item_status
,wadi.bob_item_status
,wadi.ordered_at as ordered_at
,if(db = 'AE',soae.ready_for_ship_at,sosa.ready_for_ship_at)ready_for_ship_at
,if(db = 'AE' , soae.shipped_at , sosa.shipped_at)shipped_atsales_order_itemsales_order_itemsales_order_item
,wadi.HAWB_number
,timestampdiff(hour,wadi.ordered_at,now()) as pickup_ageing
,if(db = 'AE' , soae.rfs_ageing,sosa.rfs_ageing)rfs_ageing
,if(db ='AE' , soae.ship_ageing,sosa.ship_ageing)ship_ageing
,case when timestampdiff(hour,wadi.ordered_at,now()) >= 36 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_0"
when timestampdiff(hour,wadi.ordered_at,now()) between 24 and 35 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_1"
when timestampdiff(hour,wadi.ordered_at,now()) between 12 and 23 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_2"
when timestampdiff(hour,wadi.ordered_at,now()) < 12 and sales_order_item_status.name = 'pending' then "Pickup_Confirmation_Priority_3"
when if(db = 'AE' , soae.rfs_ageing,sosa.rfs_ageing) >= 36 and sales_order_item_status.name = 'ready_to_ship' then "Handover_Priority_0"
when if(db = 'AE' , soae.rfs_ageing,sosa.rfs_ageing) between 24 and 35 and sales_order_item_status.name = 'ready_to_ship' then "Handover_Priority_1"
when if(db = 'AE' , soae.rfs_ageing,sosa.rfs_ageing) < 24 and sales_order_item_status.name = 'ready_to_ship' then "Handover_Priority_2"
when sales_order_item_status.name = 'shipped' and su.pickup is null and  if(db ='AE' , soae.ship_ageing,sosa.ship_ageing) >= 48 then "Carrier_Confirmation_Priority_1"
when sales_order_item_status.name = 'shipped' and su.pickup is null and  if(db ='AE' , soae.ship_ageing,sosa.ship_ageing) between 24 and 47 then "Carrier_Confirmation_Priority_2"
when sales_order_item_status.name = 'shipped' and su.pickup is null and  if(db ='AE' , soae.ship_ageing,sosa.ship_ageing) < 24 then "Carrier_Confirmation_Priority_2"
end Priority
,IF(LENGTH(sc_sa.name) = CHAR_LENGTH(sc_sa.name), sc_sa.name,'NA') as item_name




from buy_sell.wadi_indexer wadi
left join
sc_live_ae.sales_order_item sc_ae on sc_ae.src_id = wadi.item_id and wadi.db = 'AE' 

left join
sc_live_sa.sales_order_item sc_sa on sc_sa.src_id = wadi.item_id and wadi.db = 'SA'

left join sc_live_sa.sales_order_item_status on sc_sa.fk_sales_order_item_status = sales_order_item_status.id_sales_order_item_status

left join sc_live_sa.seller sa_seller on sa_seller.id_seller = sc_sa.fk_seller
left join sc_live_ae.seller ae_seller on ae_seller.id_seller = sc_ae.fk_seller

left join
	(select
    fk_sales_order_item
    ,fk_sales_order_item_status
    ,min(if(fk_sales_order_item_status = 2,created_at,null)) as shipped_at
    ,min(if(fk_sales_order_item_status = 8,created_at,null)) as ready_for_ship_at
    ,timestampdiff(hour,min(if(fk_sales_order_item_status = 8,created_at,null)),now()) as rfs_ageing
    ,timestampdiff(hour,min(if(fk_sales_order_item_status = 2,created_at,null)),now()) as ship_ageing
   
   from  sc_live_sa.sales_order_item_status_history 
   where created_at > curdate() - interval 90 day
   group by 1
	) as sosa on sc_sa.id_sales_order_item = sosa.fk_sales_order_item
    
    left join
	(select
    fk_sales_order_item
    ,fk_sales_order_item_status
    ,min(if(fk_sales_order_item_status = 2,created_at,null)) as shipped_at
    ,min(if(fk_sales_order_item_status = 8,created_at,null)) as ready_for_ship_at
    ,timestampdiff(hour,min(if(fk_sales_order_item_status = 8,created_at,null)),now()) as rfs_ageing
    ,timestampdiff(hour,min(if(fk_sales_order_item_status = 2,created_at,null)),now()) as ship_ageing
   
   from  sc_live_ae.sales_order_item_status_history 
   where created_at > curdate() - interval 90 day
   group by 1
	) as soae on sc_ae.id_sales_order_item = soae.fk_sales_order_item
    
    left join
(select 
awb
,min(occurred_at) as pickup
from cerberus_live.shipment_update 
where
reference = 'Aramex-SH014' and occurred_at > curdate() - interval 90 day
group by 1 having pickup is not null)as su on su.awb = wadi.HAWB_number

where vendor_code > 999 and vendor_code not in ('1290' , '6797', '6818')
and (sc_sa.fk_sales_order_item_status in (1) or sc_ae.fk_sales_order_item_status in (1))
order by seller_name;

