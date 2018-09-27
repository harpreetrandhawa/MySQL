Select incfriday,sum(unit_price)
from (Select unit_price,
case when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24) <= 1 then '24 Hrs'
	when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24) between 1 and 2 then '48 Hrs'
    when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24) between 2 and 3 then '72 Hrs'
    when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24) > 3 then 'Above 72 Hrs'

end incfriday,
timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24 inc_friday,
case when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24 - floor((dayofweek(sc.exportable_at- interval 6 day) + timestampdiff(day,sc.exportable_at,sc.shipped_at))/7)) <= 1 then '24 Hrs'
	when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24 - floor((dayofweek(sc.exportable_at- interval 6 day) + timestampdiff(day,sc.exportable_at,sc.shipped_at))/7)) between 1 and 2 then '48 Hrs'
    when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24 - floor((dayofweek(sc.exportable_at- interval 6 day) + timestampdiff(day,sc.exportable_at,sc.shipped_at))/7)) between 2 and 3 then '72 Hrs'
    when (timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24 - floor((dayofweek(sc.exportable_at- interval 6 day) + timestampdiff(day,sc.exportable_at,sc.shipped_at))/7)) > 3 then 'Above 72 Hrs'

end as exfriday,


(timestampdiff(hour,sc.exportable_at,sc.shipped_at)/24 - floor((dayofweek(sc.exportable_at- interval 6 day) + timestampdiff(day,sc.exportable_at,sc.shipped_at))/7))ex_friday


from wadi_indexer
left join
(select db,
	item_id, 
	min(if(status = 'exportable',occured_at+ interval 4 hour,NULL))exportable_at, 
    min(if(status = 'shipped',occured_at + interval 4 hour,NULL))shipped_at 
    from status_cache
    where  status in ('exportable','shipped') and date((occured_at + interval 4 hour)) >= date_format(curdate(),'%Y-%m-01') group by 1,2)sc 
    on wadi_indexer.db = sc.db and wadi_indexer.item_id = sc.item_id
where sc.exportable_at is not null 
and vendor_code > 999 and vendor_warehouse_country in ('AE','SA')
and category_level_1 != 'daily_needs')main group by 1;


Select count(1) from wadi_indexer;