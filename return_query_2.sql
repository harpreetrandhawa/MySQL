
select rsoi.item_id,rsoi.item_status,fst_scan.* from 

(select return_id,
min(if(boom_status in (3,22,1),timestamp,'NA')) as first_scan_time, 
min(if(boom_status in (13),timestamp,'NA')) as third_scan_time 
       
from boomerang.log_table 
where boom_status in (1,3,13,22)	
   group by 1
) 
as fst_scan
left join boomerang.return_sales_order_item rsoi
on rsoi.id=fst_scan.return_id



order by fst_scan.first_scan_time desc;