select item_name,Super_Category,mapped_vendor,mapped_vendor_name from tbl_run_details 
 where date(created_date) = curdate() and (owner is null or owner  = '') 
 and mapped_vendor not in ('Find Seller','Find KSA Seller') group by 3;