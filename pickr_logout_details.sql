Select count(distinct t.vendor_id)total_Vendor,count(distinct Case When status != '-' then vendor_id end)visted,
count(distinct t.vendor_id)-count(distinct Case When status != '-' then vendor_id end)not_visted,
count(1)total_item,sum(if(status = 'Qty Recevied',1,0))picked,
count(1)-sum(if(status = 'Qty Recevied',1,0))not_picked,
sum(if(status not in ('Qty Recevied','-'),1,0))visted_not_picked,
sum(if(status in ('-'),1,0))not_visited_not_picked
from  
(select Itemid,skucode,po,productdescription,ifnull(if(recd_qty!=0,'Qty Recevied',ps.status),'-') as status,driver,
paymentterms,country,lvu.vendor_id,vendor_name,group_concat(svm.routedetails)route,modified_date,ifnull(driver_status,'-') as driverstatus from
tbl_lightbox_vendor_update lvu
left join
tbl_sentinel_vendor_mapping svm
on svm.vendorcode = lvu.vendor_id
left join
tbl_pickr_assign_status ps
on ps.id=lvu.driver_action
where date(lvu.created_date)=curdate() and is_arrivel='No' 
and vendor_id in (select vendorcode from tbl_sentinel_vendor_mapping where routedetails='Route 2') group by 1)t 