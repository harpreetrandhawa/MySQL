select
   awb
   ,carrier
 ,min(if(reference in ('Aramex-SH005','Aramex-SH006','LastMile-LM-DL-P-SH102','LastMile-LM-DL-SH005','LastMile-LM-DL-SH101','LM-DL','SMSA-POD','SMSAKSA-DL','Lastmilesa-999','Lastmiledx-999','SMSAEXP-DL'),occurred_at,null)) as del
,t2.bob_item_status
from
         logistics.shipment_update as t1
left join 
(select HAWB_number,bob_item_status
from buy_sell.wadi_indexer
group by 1) as t2
on t2.HAWB_number = t1.awb
      where
      occurred_at > curdate() - interval 15 day 
  group by        
  1
having del is not null