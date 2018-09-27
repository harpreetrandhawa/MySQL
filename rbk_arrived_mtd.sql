select
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=0.5,1,0))/count(1)*100),2),"%") 12Hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=1,1,0))/count(1)*100),2),"%") 24_hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) <=2,1,0))/count(1)*100),2),"%") 48_Hours,
concat(round((sum(if(((timestampdiff(second,t.exported_at,t.arrived_at)/86400) - (Fridays)) >2,1,0))/count(1)*100),2),"%") above_48_Hours,
round(sum(timestampdiff(day,exported_at,arrived_at)-Fridays)/count(1),1)avg_arrival_In_Days1
from (select item_id,
(exportable_at + interval 4 hour)exported_at,
(po_created_at+ interval 4 hour)arrived_at,
floor((dayofweek(date(exportable_at + interval 4 hour)-interval 6 day)+timestampdiff(day,date(exportable_at + interval 4 hour),Date(po_created_at + interval 4 hour)))/7) Fridays
from replica_rbk_sales_order_item_erp rbk

where date(po_created_at + interval 4 hour) >= curdate() - interval day(curdate()-interval 1 day) day 
and date(po_created_at + interval 4 hour) < Curdate())t;
