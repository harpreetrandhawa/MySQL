select
concat(wadi_indexer.db, wadi_indexer.item_id) as item_id
,wadi_indexer.order_nr
,wadi_indexer.ordered_at
,(select min(occured_at) from status_cache where status = 'exportable' and db= wadi_indexer.db and item_id = wadi_indexer.item_id)exportable_at 
,wadi_indexer.exported_at
,if(wadi_indexer.db = 'SA',sc_sa.created_at,sc_ae.created_at) as created_at
,if(wadi_indexer.db = 'SA',
	(select min(created_at) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 8 and fk_sales_order_item=sc_sa.id_sales_order_item),
    (select min(created_at) from seller_centre_ae_replica.sales_order_item_status_history where fk_sales_order_item_status = 8 and fk_sales_order_item=sc_ae.id_sales_order_item)) as ready_to_ship_at
,if(wadi_indexer.db = 'SA',
	(select min(created_at) from seller_centre_sa_replica.sales_order_item_status_history where fk_sales_order_item_status = 2 and fk_sales_order_item=sc_sa.id_sales_order_item),
    (select min(created_at) from seller_centre_ae_replica.sales_order_item_status_history where fk_sales_order_item_status = 2 and fk_sales_order_item=sc_ae.id_sales_order_item)) as shipped_at
,logistics.occurred_at as carrier_confirmation_at
,if(wadi_indexer.db = 'SA',sc_sa.target_to_ship,sc_ae.target_to_ship) target_to_ship
,wadi_indexer.bob_item_status
,mp_status.name as SC_item_status
,null as account_manager
,if(wadi_indexer.db = 'SA',sa_seller.src_id,ae_seller.src_id) as seller_id #vendor_code
,if(wadi_indexer.db = 'SA',sa_seller.short_code,ae_seller.short_code) as seller_code #short_code
,if(wadi_indexer.db = 'SA',sa_seller.name,ae_seller.name) as seller_name
,if(wadi_indexer.db = 'SA',sa_seller.email,ae_seller.email) as seller_email
,if(wadi_indexer.db = 'SA',sc_sa.sku_seller,sc_ae.sku_seller) as sku_seller
,wadi_indexer.unit_price
,wadi_indexer.HAWB_number
,if(wadi_indexer.db = 'SA',sc_sa.fk_shipment_provider,sc_ae.fk_shipment_provider) as carrier
,null as order_ageing
,null as exportable_ageing
,null as pending_ageing
,null as ready_to_ship_ageing
,null as shipped_ageing
,null as carrier_confirmation_ageing
,wadi_indexer.vendor_warehouse_country as source_country
,null as mp_cancel
,null as priority
,wadi_indexer.item_name
,null as target_to_ship_range

from  wadi_indexer

left join
seller_centre_ae_replica.sales_order_item sc_ae on sc_ae.src_id = wadi_indexer.item_id and wadi_indexer.db = 'AE'
left join
seller_centre_sa_replica.sales_order_item sc_sa on sc_sa.src_id = wadi_indexer.item_id and wadi_indexer.db = 'SA'
left join
seller_centre_sa_replica.sales_order_item_status  mp_status on mp_status.id_sales_order_item_status = sc_sa.fk_sales_order_item_status or mp_status.id_sales_order_item_status = sc_ae.fk_sales_order_item_status
left join
(select awb, min(occurred_at)occurred_at from logistics.shipment_update where reference in ('Aramex-SH001','Lastmiledx-003','SMSAKSA-AF')) logistics on logistics.awb = wadi_indexer.HAWB_number

left join
seller_centre_ae_replica.seller ae_seller on ae_seller.id_seller = sc_ae.fk_seller
left join
seller_centre_ae_replica.seller sa_seller on sa_seller.id_seller = sc_sa.fk_seller



where wadi_indexer.order_nr= 'SA614334871';
