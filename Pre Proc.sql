select t.item_name,t.bids,
sum(t.qty)total_shipped,
sum(if(shipped_at between  (curdate() - interval 30 day) and (curdate() - interval 21 day),qty,0)) first10days,
sum(if(shipped_at between  (curdate() - interval 20 day) and (curdate() - interval 11 day),qty,0)) Mid_10_days,
sum(if(shipped_at between  (curdate() - interval 10 day) and (curdate() - interval 1 day),qty,0)) Last_10_days,

(sum(if(shipped_at between  (curdate() - interval 30 day) and (curdate() - interval 21 day),qty,0))*0.2 +
sum(if(shipped_at between  (curdate() - interval 20 day) and (curdate() - interval 11 day),qty,0))*0.3 +
sum(if(shipped_at between  (curdate() - interval 10 day) and (curdate() - interval 1 day),qty,0))*0.5)*3 adjusted_frequency

from (Select item_name,bids, date(shipped_at + interval 4 hour)shipped_at,count(1)qty 
from wadi_indexer where date(shipped_at + interval 4 hour)>= date(now() -interval 30 day) and date(shipped_at + interval 4 hour)< curdate()
group by bids,date(shipped_at + interval 4 hour))t group by t.bids;


Select ((now()-interval 1 day) -interval 29 day)