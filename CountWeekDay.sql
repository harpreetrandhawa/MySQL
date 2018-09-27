select indexer.exported_at,indexer.seller_shipping_time_max_ae 
,dayofweek((date(indexer.exported_at)-6)) as count_friday
,round((indexer.seller_shipping_time_max_ae+dayofweek((date(indexer.exported_at)-6)))/7) as friday_nr
from wadi_indexer as indexer

where exported_at between '2015-12-24' and '2015-12-25'
order by exported_at limit 5
