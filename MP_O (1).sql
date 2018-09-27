select
wadi_indexer.hawb_number
,wadi_indexer.order_nr
,wadi_indexer.customer_name
,zendesk.zd_tickets_wadi.address
,wadi_indexer.city
,zendesk.zd_tickets_wadi.phone_shipping
,wadi_indexer.category_level_2
,sum(seller_centre_sa_replica.sales_order_item.paid_price)
,sum(seller_centre_sa_replica.sales_order_item.shipping_fee)
from 
seller_centre_sa_replica.sales_order_item
left join seller_centre_sa_replica.sales_order_item_status on sales_order_item.fk_sales_order_item_status = sales_order_item_status.id_sales_order_item_status
left join buy_sell.wadi_indexer on wadi_indexer.item_id = sales_order_item.src_id and wadi_indexer.db = 'SA'
left join zendesk.zd_tickets_wadi on zendesk.zd_tickets_wadi.order_number = wadi_indexer.order_nr
where
sales_order_item.fk_seller not in (1, 11) and sales_order_item.fk_shipment_provider in (2,5,14) and fk_sales_order_item_status in (1,2,8)
group by 1
