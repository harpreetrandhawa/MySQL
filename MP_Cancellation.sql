SELECT null as id,item_id,order_nr,sku,bids,item_name,Super_Category,ExportableDateTime,timestampdiff(minute,ExportableDateTime,now())/60 as Hours_Since,
  (ExportableDateTime + interval 3 day)shipping_date,type,po_number,Status,
case when timestampdiff(hour,ExportableDateTime,now()) > 24 and Status = 'pending' then "Pickup_Confirmation_Priority_1"
when timestampdiff(hour,ExportableDateTime,now()) between 12 and 24 and Status = 'pending' then "Pickup_Confirmation_Priority_2"
when timestampdiff(hour,ExportableDateTime,now()) < 12 and Status = 'pending' then "Pickup_Confirmation_Priority_3"
when timestampdiff(hour,RTS,now()) > 36 and Status = 'ready_to_ship' then "Handover_Priority_1"
when timestampdiff(hour,RTS,now()) between 24 and 36 and Status = 'ready_to_ship' then "Handover_Priority_2"
when timestampdiff(hour,RTS,now()) < 24 and Status = 'ready_to_ship' then "Handover_Priority_2"
end Action

,is_restricted,vendor_id as vendor_code,
  vendor_name,TP_Price,null as owner,
date((ExportableDateTime + interval 3 day) + interval 
floor((dayofweek(date(ExportableDateTime)- interval 6 day) + 3)/7) day + interval 1 day)
max_shipping_date,actvendor,pocreateddate,category,
  now() as created_date
  
FROM 

(select null as id, 
concat(db,item_id)item_id, 
order_nr, 
wadi_indexer.sku, wadi_indexer.bids, 
item_name, 
category_level_1 as Super_Category, 
category_level_2 as category, 
-- if(db = 'SA',sc_sa.created_at,sc_ae.created_at)ExportableDateTime,
(select min(occured_at + interval 4 hour) from status_cache where status = 'exportable' and db = wadi_indexer.db and item_id = wadi_indexer.item_id)ExportableDateTime, 
-- (select min(occured_at + interval 4 hour) from status_cache where status = 'exportable' and db = wadi_indexer.db and item_id = wadi_indexer.item_id) as shipping_date, 
'dropship' as type, 
po_number,
po_created_at as pocreateddate, 
mp_status.name as Status, 

if(ri.bids is null,0,1) as is_restricted, 
vendor_code as actvendor,
if(db = 'SA',sa_seller.short_code,ae_seller.short_code) as vendor_id,
if(db = 'SA',sa_seller.name,ae_seller.name) as vendor_name, 
wadi_indexer.unit_price as TP_Price, 
if(db = 'SA',(select min(created_at + interval 4 hour) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 8 and fk_sales_order_item = sc_sa.id_sales_order_item),
(select min(created_at + interval 4 hour) from seller_centre_ae_replica.sales_order_item_status_history where fk_sales_order_item_status = 8 and fk_sales_order_item = sc_ae.id_sales_order_item) )RTS, 
now() as created_date


from wadi_indexer 
left join
wadi_retail.restricted_items ri on ri.bids = wadi_indexer.seller_sku
left join
seller_centre_ae_replica.sales_order_item sc_ae on sc_ae.src_id = wadi_indexer.item_id and wadi_indexer.db = 'AE'
left join
seller_centre_sa_replica.sales_order_item sc_sa on sc_sa.src_id = wadi_indexer.item_id and wadi_indexer.db = 'SA'
left join
seller_centre_sa_replica.sales_order_item_status  mp_status on mp_status.id_sales_order_item_status = sc_sa.fk_sales_order_item_status or mp_status.id_sales_order_item_status = sc_ae.fk_sales_order_item_status

left join
seller_centre_ae_replica.seller ae_seller on ae_seller.id_seller = sc_ae.fk_seller
left join
seller_centre_ae_replica.seller sa_seller on sa_seller.id_seller = sc_sa.fk_seller

where (sc_sa.fk_sales_order_item_status in (1,8) or sc_ae.fk_sales_order_item_status in (1,8))
and wadi_indexer.vendor_code >999)main
Having max_shipping_date <= curdate()