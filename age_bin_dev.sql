Select location_code,ai.bids,count(ai.bids)ai_count,bin_con.quantity bin_count,count(ai.bids)-bin_con.quantity dev,
concat(round((count(ai.bids)-bin_con.quantity)/count(ai.bids)*100,2),' %')deviation,
now() as counted_at from replica_ageing_inventory ai
JOIN
replica_bin_content bin_con on bin_con.bids  = ai.bids
group by 1,2 ;




