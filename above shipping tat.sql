select Month,count(item_id),
sum(if(loc = 'DXB',1,0))DXB_Arrived,
sum(if(loc = 'DXB' and date(arrived_at)<date(maxshippingdate),1,0))withintat_DXB,
sum(if(loc = 'KSA',1,0))KSA_Arrived,
sum(if(loc = 'KSA' and date(arrived_at)<date(maxshippingdate),1,0))withintat_KSA

 from (select t.*,date(((exportable_at + interval 4 hour) + interval tat day) + interval floor((dayofweek((exportable_at + interval 4 hour) - interval 6 day) + tat)/7) day + interval 1 day) maxshippingdate 

from (Select concat(db,item_id)item_id,concat(monthname(arrived_at + interval 4 hour),"'",Year(arrived_at + interval 4 hour))Month,
(Select min(occured_at) from status_cache where status = 'exportable' and status_cache.db = wadi_indexer.db and status_cache.item_id = wadi_indexer.item_id)exportable_at,
arrived_at,shipping_location as loc,
ifnull(if(db = 'AE',seller_delivery_time_max_ae,seller_delivery_time_max_sa),3)tat
from wadi_indexer
where 
(arrived_at + interval 4 hour)  between '2016-01-01' and '2017-08-31')t)t1 group by 1;

Select shipping_location from wadi_indexer limit 5