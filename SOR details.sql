Select report.item_no,wc.product_name,report.vendor_no,
ifnull(sum(if(str_to_date(left(posting_date,10),'%Y-%m-%d') < date(curdate())- interval 15 day 
,report.quantity,0)),0) as Stock_on_start,
ifnull(t.Item_purchased,0) as Item_purchased,
ifnull(t.Item_Returned,0) as Item_Returned,
ifnull(t.Sold,0) as Sold,
ifnull(t.Customer_returned,0) as Customer_returned,
ifnull(sum(report.quantity),0) as current_inventory,
ifnull(sum(report.quantity)* report.unit_cost,0) as Stock_Value
from sor_report as report
Left Outer Join
(select item_no,
sum(if(transaction_type ='Purchase' and quantity = 1,1,0)) as Item_purchased,
sum(if(transaction_type ='Purchase' and quantity = -1,1,0)) as Item_Returned,
sum(if(transaction_type ='Sales' and quantity = -1,1,0)) as Sold,
sum(if(transaction_type ='Sales' and quantity = 1,1,0)) as Customer_returned
from sor_report where str_to_date(left(posting_date,10),'%Y-%m-%d') >= date(curdate())- interval 15 day group by 1) as t On t.item_no = report.item_no
LEFT OUTER JOIN
(select bids,product_name from wadi_catalog) as wc on wc.bids = report.item_no 
where vendor_no in ('V00311','SV00208','SV00205') group by 1;


select item_no, sum(if(str_to_date(left(posting_date,10),'%Y-%m-%d') < date(curdate())- interval 15 day and quantity = 1 and transaction_type ='Purchase',1,0)) as Inventory 
,quantity from sor_report where  item_no = 'W1315100134';

