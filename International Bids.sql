select t.wadi_sku_num, vendor_code,seller_name, count
from (select c.wadi_sku_num, vendor_code,seller_name, count(1) as count from (select wadi_sku_num, vendor_code,seller_name from wadi_retail.onboarding where seller_inventory<>'0') as c group by 1) t
where count = '1' and vendor_code in ('V00492',
'V00469',
'V00487',
'SV00235',
'V00419',
'V00689',
'SV00333',
'SV00209',
'SV00134',
'SV00257',
'SV00152',
'V00706',
'SV00186',
'V00531',
'V00571',
'V00816',
'SV00060',
'SV00172',
'V00127',
'V00287',
'V00894',
'SV00421',
'SV00481',
'V00754',
'SV00303',
'V00481',
'V00874',
'V00925',
'V00895',
'V00937',
'V00921') 
union all
Select distinct wadi_sku_num,vendor_code, seller_name,"1" as count from wadi_retail.onboarding where vendor_code in ('V00378','SV00336');

