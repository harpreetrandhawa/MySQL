select 
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=0.5,1,0))/count(1)*100),2),"%") 12_hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=1,1,0))/count(1)*100),2),"%") 24_hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=2,1,0))/count(1)*100),2),"%") 48_Hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=3,1,0))/count(1)*100),2),"%") 72_Hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) >3,1,0))/count(1)*100),2),"%") Above_72_Hours,
round(sum(timestampdiff(day,exported_at,arrived_at)-Fridays)/count(1),1)avg_arrival_In_Days,
Count(1)arrived_items
 from(select item_id,(exportable_at + interval 4 hour)exported_at,(if(arrived_at>shipped_at,shipped_at,arrived_at)+ interval 4 hour)arrived_at,
 floor((dayofweek(date(exportable_at + interval 4 hour)-interval 6 day)+timestampdiff(day,date(exportable_at + interval 4 hour),Date(if(arrived_at>shipped_at,shipped_at,arrived_at) + interval 4 hour)))/7) Fridays,

CASE
    WHEN vendor_code ='V00013' THEN 'Namshi'
    WHEN vendor_code in ('V00378','SV00336','V01181','V01182','V00719','V00883','V00894','V00874','V00921','V00487','V00895','V00816','V00586','V01053') THEN 'Intl'
    WHEN LEFT(vendor_code,1) = 'V' THEN 'Wadi'
    WHEN LEFT(vendor_code,2) = 'SV' THEN 'Saudi'
	WHEN location = 'KSA' then 'Saudi'
 ELSE 'Wadi' 
  END AS vendor
  
from replica_sales_order_item_erp erp
where (if(arrived_at>shipped_at,shipped_at,arrived_at) + interval 4 hour) >= date_format(curdate() - interval day(curdate()-interval 1 day) day,'%Y-%m-%d 08:00:00')
and (if(arrived_at>shipped_at,shipped_at,arrived_at) + interval 4 hour) < concat(Curdate(),' 08:00:00') and canceled_at = 0
and floor((dayofweek(date(exportable_at + interval 4 hour)-interval 6 day)+timestampdiff(day,date(exportable_at + interval 4 hour),Date(if(arrived_at>shipped_at,shipped_at,arrived_at) + interval 4 hour)))/7) < 100
Having vendor = 'Wadi')t ;




