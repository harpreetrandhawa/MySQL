select Month,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=0.5,1,0))/count(1)*100),2),"%") 12Hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=1,1,0))/count(1)*100),2),"%") 24_hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=2,1,0))/count(1)*100),2),"%") 48_Hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=3,1,0))/count(1)*100),2),"%") 72_Hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) >3,1,0))/count(1)*100),2),"%") Above_72_Hours
,round(sum(timestampdiff(day,exported_at,arrived_at)-Fridays)/count(1),1)avg_arrival_In_Days1
from (select item_id,concat(monthname(arrived_at),"'",Year(arrived_at))Month,
(exportable_at + interval 4 hour)exported_at,
(arrived_at+ interval 4 hour)arrived_at,
floor((dayofweek(date(exportable_at + interval 4 hour)-interval 6 day)+timestampdiff(day,date(exportable_at + interval 4 hour),Date(arrived_at + interval 4 hour)))/7) Fridays,

CASE
    WHEN vendor_code ='V00013' THEN 'Namshi'
    WHEN vendor_code in ('V00378','SV00336','V00937','SV00772','SV00758','SV00604','SV00605','V00921','V00487','V00895','V00894') THEN 'Intl'
    WHEN LEFT(vendor_code,1) = 'V' THEN 'Wadi'
    WHEN LEFT(vendor_code,2) = 'SV' THEN 'Saudi'
	WHEN location = 'KSA' then 'Saudi'
 ELSE 'Wadi' 
  END AS vendor
from replica_sales_order_item_erp erp

where date(arrived_at + interval 4 hour) between '2016-01-01' and '2017-08-31'
Having vendor = 'Saudi')t group by 1;
