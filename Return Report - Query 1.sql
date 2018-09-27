Select w.db,concat(w.db, w.item_id)item_id,
w.item_id
,w.order_nr, 
(w.ordered_at+ interval 4 hour)ordered_at, 
w.bob_item_status, 
(w.exported_at + interval 4 hour)exported_at, 
w.vendor_code,
w.unit_price, 
w.paid_price, 
w.sku, w.bids, 
w.shipping_location, 
w.HAWB_number, 
w.erp_id, 
w.city, 
w.bob_carrier, 
w.vendor_warehouse_country,
(w.promised_delivery_date + interval 4 hour)promised_delivery_date, 
w.country, 
w.rsin,
(w.return_undeliverable_at + interval 4 hour)return_undeliverable_at, 
(w.shipped_at + interval 4 hour)shipped_at, 
(w.delivered_at +interval 4 hour)delivered_at
,(select min(occurred_at) from  cerberus_live.shipment_update 
	where awb = w.hawb_number 
		and reference in ('LM-CL-SH080','SMSA-RT ','SMSA-RTO','SMSAKSA-RTS','Lastmilesa-777','Lastmile-777','Lastmilemp-777','Lastmiledx-777','LastMile-LM-R-P-SH170','SMSAEXP-RTS','wadilm-777') group by awb)RTO_delivered_at

from buy_sell.wadi_indexer w

where w.category_level_1 not in ('daily_needs','seller_accessories')
and w.vendor_warehouse_country in ('AE', 'SA')
and w.vendor_code > 999;

Select count(1) from cerberus_live.shipment_update limit 50