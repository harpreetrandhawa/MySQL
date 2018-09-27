set SQL_SAFE_UPDATES = 0;

UPDATE tbl_shipped_data SET is_active='0', 
user_status='Will be in W/H', 
user_remarks='Approved by Pratik', 
user_status1='Will be in W/H', 
user_remarks1='Approved by Pratik' WHERE date(created_date) = curdate() and item_id in ('SA1684270','SA1718823','SA1659299','SA1645234','SA1668238','SA1642325','SA1684731','SA1674814','SA1655662','SA1672623','SA1657127','SA1656121','SA1608068','SA1769458','SA1698787','SA1769738','SA1707877','SA1745562');

UPDATE tbl_shipped_data SET is_active='0', 
user_status='To be Cancelled', 
user_remarks='Vendor Issue (Availability Issue)', 
user_status1='To be Cancelled', 
user_remarks1='Vendor Issue (Availability Issue)' WHERE date(created_date) = curdate() and is_active = 1 and owner = 'Not Assigned';

Select item_id from tbl_run_details where inventory != 0 and item_id in
(Select item_id from tbl_shipped_data where owner = 'Not Assigned' and is_active = 1)