SELECT concat(db, item_id)itemid,
   order_nr,
   bob_item_status,
   vendor_code,
   CASE WHEN vendor_code = 1290 then 'Riyadh'
   WHEN vendor_code = 6797 then 'Jeddah'
   WHEN vendor_code = 6818 then 'Dammam'
   ELSE NULL END as vendor_city,
   selected_date,
   selected_slot,
   ordered_at,
   exported_at,
   date(exported_at)exportable_date,
   shipped_at,
   delivered_at,
   if(delivered_at< promised_delivery_date,1,null)delivered_in_TAT
   
FROM buy_sell.wadi_indexer
WHERE
	date(exported_at) > curdate()- interval day(curdate()) day
    and vendor_code IN (1290,6797,6818);