select itemid,erpid,order_nr,skucode,sellersku,productdescription,productdescription1,manager_name,
vendor_code,vendor_name,fk_city,country,created_date,
CASE
 WHEN dtype = 'return' THEN last_modified ELSE pickup_date END as Action_date ,dtype,Action
from sentinel.tbl_lightbox_pickr_details where date(created_date) >= '2018-03-01' and dtype in ('dropship' ,'JIT','Return')
and vendor_code in (select vendorcode from tbl_sentinel_vendor_mapping where routedetails != 'Warehouse Delivery');

