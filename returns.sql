Select HAWB_number,
null as return_awb,
concat(db,item_id)item_id,
erp_id,
order_nr,
bob_item_status,
(select min(occured_at) from status_cache where status = 'shipped' and db = wadi_indexer.db and item_id = wadi_indexer.item_id)shipped,
(select min(occured_at) from status_cache where status in ('return_request','return_undeliverable') and db = wadi_indexer.db and item_id = wadi_indexer.item_id)RTO_initiated,
vendor_id,
vendor_name,
vendor_code,
if(vendor_code <999, 'JIT', 'Dropship')consignment_type,
if(db = 'SA',sa.short_code,ae.short_code)short_code,
null as vendor_address,
null as vendor_contact,
if(db = 'SA',sa.email,ae.email)vendor_email,
null as route,
unit_price,
(select min(occured_at) from status_cache where status in ('delivered','delivered_and_paid') and db = wadi_indexer.db and item_id = wadi_indexer.item_id)delivered_at,
if((select min(occured_at) from status_cache where status in ('delivered','delivered_and_paid') and db = wadi_indexer.db and item_id = wadi_indexer.item_id) is null, 'NDR','CIR')return_type,
item_name,
po_number,
po_created_at,
ordered_at,
vendor_warehouse_country

from wadi_indexer 
left join
seller_centre_ae_replica.seller ae on ae.src_id = wadi_indexer.vendor_code
left join
seller_centre_sa_replica.seller sa on sa.src_id = wadi_indexer.vendor_code
where bob_item_status in ('return_request','return_undeliverable','shipped')