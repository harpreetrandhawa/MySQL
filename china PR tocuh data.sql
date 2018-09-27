select
wadi_indexer.hawb_number
,wadi_indexer.customer_name
,zendesk.zd_tickets_wadi.address
,wadi_indexer.city
,zendesk.zd_tickets_wadi.phone_shipping
,wadi_indexer.category_level_2
,sum(wadi_indexer.paid_price)
,sum(wadi_indexer.seller_shipping_cost)
from 
buy_sell.wadi_indexer
left join zendesk.zd_tickets_wadi on zendesk.zd_tickets_wadi.awb = wadi_indexer.HAWB_number
where
vendor_warehouse_country in ('CN','HK') and bob_item_status in ('exported','shipped')
group by 1

