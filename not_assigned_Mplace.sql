select productdescription,vendor_id,vendor_name 
from tbl_lightbox_vendor_update 
where date(created_date)=curdate() and vendor_id like 'MV%' and (owner is null or owner ='') and vendor_id not in ('MVSA002004') group by 2;