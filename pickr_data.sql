Select productdescription as AWB_number
,pickr.erpid as erp_id
,pickr.paymentterms as paymentMethod
,ucase(pickr.itemid)item_id
,order_nr
,pickr.vendor_code
,pickr.vendor_name
,if(pickr.manager_name = '','Mass Account Manager',ifnull(pickr.manager_name,'Mass Account Manager')) manager_name
,CASE WHEN vm.routedetails = 'Warehouse Delivery' THEN 'Warehouse'
 ELSE replace(ifnull(ifnull(pickr.driver,user_master.first_name),'Not Assigned'),' ','')
 END as actual_driver
,pickr.pickup_address
,pickr.location fk_city
,pickr.country as destination_city
,pickr.country as state
,pickr.productdescription1 item_discreption
,pickr.price as unit_price
,pickr.qty
,pickr.recd_qty
,pickr.is_active
,pickr.created_date
,pickr.modified_date
,pickr.last_modified last_update_at
,pickr.driver
,ifnull(vm.routedetails,driver_update.route) as route
,pickr.newitems
,pickr.Attempt
,pickr.flg
,pickr.status_app
,pickr.action as lastremarks
,ifnull(driver_update.ddltext,'N/A') as remarks
,driver_update.cmt as comments
,CASE
  WHEN pickr.recd_qty =0 and pickr.is_active=1 and pickr.status_app is null and (driver_update.ddltext is null or driver_update.ddltext = '') and (select ifnull(max(Attempt),0) from tbl_lightbox_pickr_details
  where date(pickup_date)=curdate()-1 and vendor_code = pickr.vendor_code) <=0 THEN 'Not Attempted'
  WHEN pickr.recd_qty = 1 or pickr.is_active =  0  Then 'Picked'
 ELSE
 'Not Picked'
 END as Status
,pickr.dtype
,pickr.in_scan
,pickr.out_scan
,CASE 
 WHEN timestampdiff(hour,pickr.created_date,now()) -
  floor((dayofweek(date(pickr.created_date) - interval 6 day)
  +timestampdiff(day,date(pickr.created_date),curdate()))/7) * 24 < 24 THEN '0-1 Day'
 WHEN timestampdiff(hour,pickr.created_date,now()) -
  floor((dayofweek(date(pickr.created_date) - interval 6 day)
  +timestampdiff(day,date(pickr.created_date),curdate()))/7) * 24 between  24 and 48 THEN '1-2 Day'
 WHEN timestampdiff(hour,pickr.created_date,now()) -
  floor((dayofweek(date(pickr.created_date) - interval 6 day)
  +timestampdiff(day,date(pickr.created_date),curdate()))/7) * 24 between  48 and 72 THEN '2-3 Day'
 WHEN timestampdiff(hour,pickr.created_date,now()) -
  floor((dayofweek(date(pickr.created_date) - interval 6 day)
  +timestampdiff(day,date(pickr.created_date),curdate()))/7) * 24 > 72 THEN '3 + Day'
 END as ready_to_ship_ageing

from tbl_lightbox_pickr_details pickr 
Left Join
(select * from tbl_lightbox_pickr_details_updates where date(created_date) = curdate()- interval 1 day) driver_update 
on driver_update.awb = pickr.skucode
left join sentinel.tbl_sentinel_vendor_mapping vm on vm.vendorcode = pickr.vendor_code
left join sentinel.tbl_picker_driver_run_details run_detail on run_detail.route = vm.routedetails
left join sentinel.tbl_senitel_user_master user_master on user_master.uid = run_detail.did
Where ((date(pickr.last_modified) = curdate()- interval 1 day)   or date(pickr.modified_date) >= curdate()- interval 1 day) 
and date(pickr.created_date) != curdate()
and ifnull(status_app,'N/A') not in ('mp_cancel','sc_shipped')
and pickr.dtype = 'DropShip'
and pickr.vendor_code not in ('MVAE001517', 'MVSA001024','MVAE001064','MVSA002294','MVSA001290','MVSA006797','MVSA006818')
group by pickr.id, pickr.vendor_code;