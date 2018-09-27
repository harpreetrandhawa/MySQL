Select item_id from tbl_master_run where order_location = 'DXB' and left(first_vendor,1) ='S' and is_restricted = 0 and arrived_at ='No' and cancellation_reason_code = ''  
and status in ('TP Confirmation')  and left(item_id,2) != 'AE' group by 1; 

