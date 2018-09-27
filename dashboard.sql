Select monthname(exportable_at)mnth,
CASE when vendor_code > 999 and vendor_warehouse_country in ('AE','SA') Then 'MarketPlace' 
WHEN vendor_code = 989 then 'JIT'
WHEN vendor_code in (991,995) THEN 'EXPRESS'
ELSE 'China' End as shipment_type,
sum(unit_price)GMV,
sum(if(sc.shipped_at is not null,unit_price,0))shipped,
sum(if(day(exportable_at) < day(curdate()),unit_price,0))tilllast_month,
sum(if(day(exportable_at) < day(curdate()) and day(sc.shipped_at) < day(curdate()),unit_price,0))shipped_last_month

from wadi_indexer
left join
(select db,
	item_id, 
	min(if(status = 'exportable',occured_at+ interval 4 hour,NULL))exportable_at, min(if(status = 'shipped',occured_at + interval 4 hour,NULL))shipped_at 
    from status_cache
    where  status in ('exportable','shipped') and date((occured_at + interval 4 hour)) > ((curdate()- interval 1 month)- interval day(curdate()) day) group by 1,2)sc 
    on wadi_indexer.db = sc.db and wadi_indexer.item_id = sc.item_id
where sc.exportable_at is not null and category_level_1 != 'daily_needs' group by 1,2;