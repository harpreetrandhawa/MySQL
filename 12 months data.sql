Select concat(monthname(if(exportable_at=0,exported_at,exportable_at)),"'",year(if(exportable_at=0,exported_at,exportable_at)))Month,
sum(if(left(item_id,2)='AE',1,0)) as DXB_Items,
sum(if(left(item_id,2)='AE',unit_price,0)) as DXB_value,
sum(if(left(item_id,2)='SA',1,0)) as KSA_Items,
sum(if(left(item_id,2)='SA',unit_price,0)) as KSA_value,
sum(if(left(item_id,2)='AE' and location = 'KSA' and order_item_status='Shipped',1,0)) as shipped_KSA_to_DXB,
sum(if(left(item_id,2)='AE' and location = 'KSA' and order_item_status='Shipped',unit_price,0)) as shipped_KSA_to_DXB_value,
sum(if(left(item_id,2)='SA' and location = 'DXB' and order_item_status='Shipped',1,0)) as shipped_DXB_to_KSA,
sum(if(left(item_id,2)='SA' and location = 'DXB' and order_item_status='Shipped',unit_price,0)) as shipped_DXB_to_KSA_value
from replica_sales_order_item_erp where if(exportable_at=0,exported_at,exportable_at) between '2016-01-01' and '2017-08-31' group by 1;

select * from replica_sales_order_item_erp where exported_at between '2016-08-01' and '2017-08-31' and exportable_at is null limit 500
