SELECT * FROM sentinel.tbl_shipped_data_dropship where user_status != null and date(created_date) = curdate() - interval 10 day