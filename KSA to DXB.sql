Select item_id from tbl_master_run where order_location = 'KSA' and left(first_vendor,1) ='V' and is_restricted = 0 and arrived_at ='No' and cancellation_reason_code = ''  
and status in ('TP Confirmation') group by 1; 

